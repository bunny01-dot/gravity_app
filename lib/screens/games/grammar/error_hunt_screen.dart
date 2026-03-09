import 'package:flutter/material.dart';

import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/safe_game_content_provider.dart';

enum GrammarErrorType {
  subjectVerbAgreement,
  wrongTense,
  wrongAuxiliary,
  wrongVerbForm,
}

class ErrorHuntScreen extends StatefulWidget {
  final int level;
  const ErrorHuntScreen({super.key, this.level = 1});

  @override
  State<ErrorHuntScreen> createState() => _ErrorHuntScreenState();
}

class _ErrorHuntScreenState extends State<ErrorHuntScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _isRoundComplete = false;
  bool _isLoading = true;
  bool _hasInsufficientContent = false;

  final List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  GrammarErrorType _errorTypeForLevel(int level) {
    if (level <= 2) return GrammarErrorType.subjectVerbAgreement;
    if (level <= 4) return GrammarErrorType.wrongTense;
    if (level <= 6) return GrammarErrorType.wrongVerbForm;
    return GrammarErrorType.wrongAuxiliary; // Or mixed
  }

  Future<void> _loadData() async {
    try {
      final safeProvider = SafeGameContentProvider(DataService());
      final verbs = await safeProvider.getEligibleVerbs(minCount: 3);

      final List<Map<String, dynamic>> dynamicQuestions = [];
      final errorType = _errorTypeForLevel(widget.level);

      for (var verb in verbs) {
        switch (errorType) {
          case GrammarErrorType.subjectVerbAgreement:
            final sentence = verb.exampleSentences['present'] ?? '';
            if (sentence.isNotEmpty) {
              _generateAgreementError(verb, sentence, dynamicQuestions);
            }
            break;
          case GrammarErrorType.wrongTense:
            final sentence = verb.exampleSentences['past'] ?? '';
            if (sentence.isNotEmpty) {
              _generateWrongTenseError(verb, sentence, dynamicQuestions);
            }
            break;
          case GrammarErrorType.wrongVerbForm:
            // e.g. using base instead of gerund or PP
            final sentence =
                verb.exampleSentences['present'] ?? ''; // or continuous
            if (sentence.isNotEmpty) {
              _generateVerbFormError(verb, sentence, dynamicQuestions);
            }
            break;
          case GrammarErrorType.wrongAuxiliary:
            // Advanced: "Has gone" vs "Have gone" etc.
            // For now fallback to mixed errors
            final s1 = verb.exampleSentences['past'] ?? '';
            if (s1.isNotEmpty) {
              _generateWrongTenseError(verb, s1, dynamicQuestions);
            }
            break;
        }

        // If high level, maybe mix types?
        if (widget.level >= 7) {
          // Mix logic could go here
        }
      }

      if (dynamicQuestions.length < 3) {
        debugPrint(
          "ErrorHunt: Warning, fewer items than requested were fetched.",
        );
      }

      setState(() {
        _questions.clear();
        _questions.addAll(dynamicQuestions..shuffle());
        _questions.take(10).toList(); // Limit
        _isLoading = false;
        _hasInsufficientContent = false;
      });
    } catch (e) {
      debugPrint("ErrorHunt: Error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasInsufficientContent = true;
        });
      }
    }
  }

  void _generateAgreementError(
    dynamic verb,
    String sentence,
    List<Map<String, dynamic>> list,
  ) {
    String correctWord = '';
    String wrongWord = '';

    // "He goes" -> "He go"
    if (sentence.contains(verb.present3rd) &&
        verb.present3rd != verb.base &&
        verb.present3rd.isNotEmpty) {
      correctWord = verb.present3rd;
      wrongWord = verb.base;
    }
    // "I go" -> "I goes"
    else if (sentence.contains(verb.base)) {
      // Only if subject supports it, rough approximation
      correctWord = verb.base;
      wrongWord = verb.present3rd.isNotEmpty ? verb.present3rd : verb.gerund;
    }

    _addQuestionIfValid(sentence, correctWord, wrongWord, list);
  }

  void _generateWrongTenseError(
    dynamic verb,
    String sentence,
    List<Map<String, dynamic>> list,
  ) {
    // "I went" -> "I go" (in past context)
    if (verb.past.isNotEmpty && sentence.contains(verb.past)) {
      _addQuestionIfValid(sentence, verb.past, verb.base, list);
    }
  }

  void _generateVerbFormError(
    dynamic verb,
    String sentence,
    List<Map<String, dynamic>> list,
  ) {
    // Replace gerund with base? "I am going" -> "I am go"
    if (verb.gerund.isNotEmpty && sentence.contains(verb.gerund)) {
      _addQuestionIfValid(sentence, verb.gerund, verb.base, list);
    }
  }

  void _addQuestionIfValid(
    String sentence,
    String correctWord,
    String wrongWord,
    List<Map<String, dynamic>> list,
  ) {
    if (correctWord.isEmpty || wrongWord.isEmpty || correctWord == wrongWord) {
      return;
    }

    final words = sentence.split(' ');
    int index = -1;

    for (int i = 0; i < words.length; i++) {
      final clean = words[i].replaceAll(RegExp(r'[^\w\s]'), '');
      if (clean == correctWord) {
        index = i;
        final original = words[i];
        final punctuation = original.replaceAll(RegExp(r'[\w\s]'), '');
        words[i] = wrongWord + punctuation;
        break;
      }
    }

    if (index != -1) {
      list.add({
        'sentence': sentence,
        'words': words,
        'wrongIndex': index,
        'correction': correctWord,
      });
    }
  }

  void _onWordTap(int index) {
    if (_isRoundComplete) return;

    final question = _questions[_currentIndex];
    final wrongIndex = question['wrongIndex'] as int;

    if (index == wrongIndex) {
      _showCorrectionDialog(index);
    } else {
      SoundService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("That word looks correct! Find the mistake."),
          backgroundColor: Colors.redAccent,
          duration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _showCorrectionDialog(int index) {
    final question = _questions[_currentIndex];
    final correction = question['correction'] as String;
    final wrongWord = (question['words'] as List)[index];
    final TextEditingController controller = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final dialogBg = isDark ? const Color(0xFF1E1E2C) : Colors.white;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text("Fix the Mistake", style: TextStyle(color: onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Replace \"$wrongWord\" with:",
              style: TextStyle(color: onSurface.withValues(alpha: 0.72)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: TextStyle(color: onSurface),
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF2A2A35)
                    : onSurface.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: "Type correction...",
                hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _validateCorrection(controller.text.trim(), correction);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC779D0),
            ),
            child: const Text("Fix It"),
          ),
        ],
      ),
    );
  }

  void _validateCorrection(String input, String expected) {
    String a = input.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    String b = expected.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    if (a == b) {
      setState(() {
        _isRoundComplete = true;
        _score++;
      });
      SoundService().playSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Correct! The word is \"$expected\"."),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(const Duration(seconds: 1), _nextQuestion);
    } else {
      SoundService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Incorrect. Expected: \"$expected\""),
          backgroundColor: Colors.redAccent,
        ),
      );
      // Move on
      setState(() {
        _isRoundComplete = true;
      });
      Future.delayed(const Duration(seconds: 2), _nextQuestion);
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _isRoundComplete = false;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        title: Text("Game Over", style: TextStyle(color: onSurface)),
        content: Text(
          "You scored $_score out of ${_questions.length}!",
          style: TextStyle(color: onSurface.withValues(alpha: 0.72)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Pop Dialog
              if (Navigator.canPop(context)) {
                Navigator.pop(context); // Pop Screen
              }
            },
            child: const Text(
              "Exit",
              style: TextStyle(color: Color(0xFFC779D0)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
                _score = 0;
                _isRoundComplete = false;
                _isLoading = true; // Reloading starts
              });
              _loadData(); // Reload for new questions
            },
            child: const Text(
              "Replay",
              style: TextStyle(color: Color(0xFFC779D0)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final scaffoldBg = isDark
        ? const Color(0xFF030305)
        : theme.scaffoldBackgroundColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasInsufficientContent || _questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.indigo.shade50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.indigo),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text("No words found. Please complete more lessons."),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final words = question['words'] as List<String>;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Error Hunt"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFC779D0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFC779D0).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFFC779D0)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Tap the word that is incorrect in the sentence below.",
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: List.generate(words.length, (index) {
                  return GestureDetector(
                    onTap: () => _onWordTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.white24
                              : onSurface.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Text(
                        words[index],
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
