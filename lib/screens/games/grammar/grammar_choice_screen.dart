import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/safe_game_content_provider.dart';

class GrammarChoiceScreen extends StatefulWidget {
  final int level;
  const GrammarChoiceScreen({super.key, this.level = 1});

  @override
  State<GrammarChoiceScreen> createState() => _GrammarChoiceScreenState();
}

class _GrammarChoiceScreenState extends State<GrammarChoiceScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedOptionIndex;
  bool _isLoading = true;
  bool _hasInsufficientContent = false;

  final List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasInsufficientContent = false;
    });

    try {
      final safeProvider = SafeGameContentProvider(DataService());
      final verbs = await safeProvider.getEligibleVerbs(minCount: 4);

      final List<Map<String, dynamic>> dynamicQuestions = [];

      for (var verb in verbs) {
        // Level 1-2: Identifying parts of speech or basic forms
        if (widget.level <= 2) {
          // Find simple present or past forms
          // Question Type: Identify correct PAST form
          if (verb.past.isNotEmpty) {
            final options = [
              verb.past,
              '${verb.base}ed', // Distractor: wrong regularization
              verb.present3rd,
              verb.gerund.isNotEmpty ? verb.gerund : '${verb.base}ing',
            ];
            // Ensure distractor isn't accidentally correct (e.g. if regular)
            // Or if base ends in e, etc. Just a simple check.
            if ('${verb.base}ed' == verb.past) {
              options[1] = '${verb.base}s';
            }
            options.shuffle();

            dynamicQuestions.add({
              'question': 'Which is the correct PAST tense of "${verb.base}"?',
              'subtitle': null,
              'options': options,
              'correctIndex': options.indexOf(verb.past),
            });
          }
        }

        // Level 3-4: Sentence Context (Simpler)
        if (widget.level >= 3 && widget.level <= 4) {
          final pastSentence = verb.exampleSentences['past'];
          if (pastSentence != null &&
              pastSentence.isNotEmpty &&
              pastSentence.contains(verb.past)) {
            final masked = pastSentence.replaceFirst(verb.past, "___");
            final options = [
              verb.base,
              verb.past,
              verb.pastParticiple,
              verb.present3rd,
            ].where((e) => e.isNotEmpty).toSet().toList()..shuffle();

            dynamicQuestions.add({
              'question': 'Complete the sentence:',
              'subtitle': masked,
              'options': options,
              'correctIndex': options.indexOf(verb.past),
            });
          }
        }

        // Level 5+: Advanced / Mixed (Including Perfect Tenses if available or tricky forms)
        if (widget.level >= 5) {
          // Try finding perfect tense examples or just mixed
          // For now, let's use Past Participle identification
          if (verb.pastParticiple.isNotEmpty) {
            final options = [
              verb.past,
              verb.pastParticiple,
              verb.base,
              verb.gerund,
            ].where((e) => e.isNotEmpty).toSet().toList()..shuffle();

            dynamicQuestions.add({
              'question': 'What is the PAST PARTICIPLE of "${verb.base}"?',
              'subtitle': 'Used in "have ${verb.pastParticiple}"',
              'options': options,
              'correctIndex': options.indexOf(verb.pastParticiple),
            });
          }
        }
      }

      if (dynamicQuestions.length < 3) {
        debugPrint(
          "GrammarChoice: Warning, fewer items than requested were fetched.",
        );
      }

      // Fallback if level didn't generate enough (e.g. strict filtering)
      // Relax level constraints if needed? strict mode says NO mock content.
      // We just rely on dynamicQuestions.

      if (dynamicQuestions.isNotEmpty) {
        dynamicQuestions.shuffle();
        if (mounted) {
          setState(() {
            _questions.clear();
            _questions.addAll(dynamicQuestions.take(10));
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _hasInsufficientContent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("GrammarChoice: Error loading dynamic data: $e");
      // Optionally handle other errors
    }
  }

  void _onOptionSelected(int index) {
    if (_answered) return;

    setState(() {
      _answered = true;
      _selectedOptionIndex = index;
    });

    bool isCorrect = index == _questions[_currentIndex]['correctIndex'];
    if (isCorrect) {
      _score++;
      SoundService().playSuccess();
    } else {
      SoundService().playError();
    }

    // Auto Advance after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _selectedOptionIndex = null;
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
        title: Text("Quiz Complete", style: TextStyle(color: onSurface)),
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
                _answered = false;
                _selectedOptionIndex = null;
                _isLoading = true;
                _loadData();
              });
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
    final cardBg = isDark ? const Color(0xFF1E1E2C) : Colors.white;

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
    final options = question['options'] as List<String>;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text("Grammar Choice - Level ${widget.level}"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress
            Text(
              "Question ${_currentIndex + 1}/${_questions.length}",
              style: TextStyle(color: onSurface.withValues(alpha: 0.54)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: isDark
                  ? Colors.white10
                  : onSurface.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFC779D0)),
            ),
            const SizedBox(height: 40),

            // Question Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    question['question'],
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (question['subtitle'] != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      question['subtitle'],
                      style: const TextStyle(
                        color: Color(0xFFC779D0),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ).animate().slideY(begin: -0.1, end: 0, duration: 400.ms),

            const SizedBox(height: 40),

            // Options
            Expanded(
              child: ListView.separated(
                itemCount: options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildOptionCard(
                    index,
                    options[index],
                    question['correctIndex'] as int,
                    isDark,
                    onSurface,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    int index,
    String text,
    int correctIndex,
    bool isDark,
    Color onSurface,
  ) {
    Color backgroundColor = isDark
        ? const Color(0xFF2A2A35)
        : Colors.white.withValues(alpha: 0.96);
    Color borderColor = Colors.transparent;
    IconData? icon;
    Color textColor = onSurface;

    if (_answered) {
      if (index == correctIndex) {
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        borderColor = Colors.green;
        icon = Icons.check_circle;
        textColor = isDark ? Colors.white : Colors.green.shade900;
      } else if (index == _selectedOptionIndex) {
        backgroundColor = Colors.red.withValues(alpha: 0.2);
        borderColor = Colors.red;
        icon = Icons.cancel;
        textColor = isDark ? Colors.white : Colors.red.shade900;
      }
    }

    return GestureDetector(
      onTap: () => _onOptionSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _answered
                ? borderColor
                : (isDark ? Colors.white10 : onSurface.withValues(alpha: 0.1)),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (icon != null) Icon(icon, color: borderColor),
          ],
        ),
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.1, end: 0);
  }
}
