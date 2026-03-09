import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/safe_game_content_provider.dart';

class TenseTrainerScreen extends StatefulWidget {
  final int level;
  const TenseTrainerScreen({super.key, this.level = 1});

  @override
  State<TenseTrainerScreen> createState() => _TenseTrainerScreenState();
}

class _TenseTrainerScreenState extends State<TenseTrainerScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedWord;
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

      // Determine target tenses based on level
      List<String> allowedTenses = [];
      if (widget.level <= 2) {
        allowedTenses = ['present'];
      } else if (widget.level <= 4) {
        allowedTenses = ['past'];
      } else {
        allowedTenses = ['present', 'past', 'future'];
      }

      final List<Map<String, dynamic>> dynamicQuestions = [];

      // Generate questions
      for (var verb in verbs) {
        // Try to find a sentence for permitted tenses
        String? targetTense;
        String sentence = '';

        // Shuffle allowed tenses to pick one that has an example
        final shuffledTenses = List.of(allowedTenses)..shuffle();

        for (final tense in shuffledTenses) {
          final possibleSentence = verb.exampleSentences[tense];
          if (possibleSentence != null && possibleSentence.isNotEmpty) {
            targetTense = tense;
            sentence = possibleSentence;
            break;
          }
        }

        if (targetTense != null && sentence.isNotEmpty) {
          String correctWord = '';
          List<String> options = [];

          if (targetTense == 'past') {
            correctWord = verb.past;
            options = [verb.base, verb.past, verb.pastParticiple];
          } else if (targetTense == 'present') {
            // Simple present logic: standard base or 3rd person
            if (sentence.contains(verb.present3rd)) {
              correctWord = verb.present3rd;
              options = [verb.base, verb.present3rd, verb.past];
            } else if (sentence.contains(verb.base)) {
              correctWord = verb.base;
              options = [verb.base, verb.present3rd, verb.past];
            }
          } else {
            // Future
            correctWord = verb.base; // Usually after 'will'
            options = [verb.base, verb.past, verb.pastParticiple];
          }

          if (correctWord.isNotEmpty) {
            // Masking by replacing only the first occurrence or specific word matching
            // Using logic that handles punctuation if needed, though simple replaceFirst is okay for v1
            final masked = sentence.replaceFirst(correctWord, "___");
            if (masked.contains("___")) {
              dynamicQuestions.add({
                'sentence': masked,
                'options': options.toSet().toList()..shuffle(),
                'correct': correctWord,
                'tense': targetTense.toUpperCase(),
              });
            }
          }
        }
      }

      // Shuffle and limit
      dynamicQuestions.shuffle();

      if (dynamicQuestions.length < 3) {
        debugPrint(
          "TenseTrainer: Warning, fewer items than requested were fetched.",
        );
      }

      if (mounted) {
        setState(() {
          _questions.clear();
          _questions.addAll(dynamicQuestions.take(10));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("TenseTrainer: Error loading dynamic data: $e");
    }
  }

  void _onOptionSelected(String option) {
    if (_answered) return;

    setState(() {
      _answered = true;
      _selectedWord = option;
    });

    bool isCorrect = option == _questions[_currentIndex]['correct'];
    if (isCorrect) {
      _score++;
      SoundService().playSuccess();
    } else {
      SoundService().playError();
    }

    Future.delayed(const Duration(seconds: 2), _nextQuestion);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _selectedWord = null;
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
        title: Text("Training Complete", style: TextStyle(color: onSurface)),
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
                _selectedWord = null;
                _isLoading = true;
                _loadData(); // Reload for variety
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
    final String sentenceRaw = question['sentence'];
    final List<String> parts = sentenceRaw.split('___');
    final options = question['options'] as List<String>;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text("Tense Trainer - Level ${widget.level}"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: isDark
                  ? Colors.white10
                  : onSurface.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFC779D0)),
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 40),
            // Sentence Display
            TextSpanBuilder(
              part1: parts[0],
              part2: parts.length > 1 ? parts[1] : "",
              placeholder: _selectedWord ?? "___",
              isAnswered: _answered,
              isCorrect: _selectedWord == question['correct'],
              isDark: isDark,
              onSurface: onSurface,
            ),

            const Spacer(),

            // Type Options
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: options.map((opt) {
                return _buildOptionButton(opt, question['correct']);
              }).toList(),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String text, String correct) {
    bool isSelected = text == _selectedWord;
    Color color = const Color(0xFFC779D0);

    if (_answered) {
      if (text == correct) {
        color = Colors.green;
      } else if (isSelected) {
        color = Colors.red;
      } else {
        color = Colors.grey.withValues(alpha: 0.5);
      }
    }

    return ElevatedButton(
      onPressed: () => _onOptionSelected(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: isSelected ? 8 : 2,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ).animate().scale(duration: 200.ms);
  }
}

class TextSpanBuilder extends StatelessWidget {
  final String part1;
  final String part2;
  final String placeholder;
  final bool isAnswered;
  final bool isCorrect;
  final bool isDark;
  final Color onSurface;

  const TextSpanBuilder({
    super.key,
    required this.part1,
    required this.part2,
    required this.placeholder,
    required this.isAnswered,
    required this.isCorrect,
    required this.isDark,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    Color highlightColor = const Color(0xFFC779D0);
    if (isAnswered) {
      highlightColor = isCorrect ? Colors.greenAccent : Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 24, color: onSurface, height: 1.5),
          children: [
            TextSpan(text: part1),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: highlightColor, width: 2),
                  ),
                ),
                child: Text(
                  placeholder,
                  style: TextStyle(
                    fontSize: 24,
                    color: highlightColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            TextSpan(text: part2),
          ],
        ),
      ),
    );
  }
}
