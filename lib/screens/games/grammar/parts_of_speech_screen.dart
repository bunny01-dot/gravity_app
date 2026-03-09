import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';

class PartsOfSpeechScreen extends StatefulWidget {
  const PartsOfSpeechScreen({super.key});

  @override
  State<PartsOfSpeechScreen> createState() => _PartsOfSpeechScreenState();
}

class _PartsOfSpeechScreenState extends State<PartsOfSpeechScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _isRoundComplete = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'sentence': 'The happy dog jumped.',
      'words': ['The', 'happy', 'dog', 'jumped.'],
      'targetPos': 'Adjective',
      'correctWords': ['happy'],
    },
    {
      'sentence': 'She reads books silently.',
      'words': ['She', 'reads', 'books', 'silently.'],
      'targetPos': 'Verb',
      'correctWords': ['reads'],
    },
    {
      'sentence': 'A big elephant walked slowly.',
      'words': ['A', 'big', 'elephant', 'walked', 'slowly.'],
      'targetPos': 'Noun',
      'correctWords': ['elephant'],
    },
    {
      'sentence': 'He runs very fast.',
      'words': ['He', 'runs', 'very', 'fast.'],
      'targetPos': 'Adverb',
      'correctWords': ['very', 'fast.'], // debatable but simplistic
    },
    {
      'sentence': 'They played under the tree.',
      'words': ['They', 'played', 'under', 'the', 'tree.'],
      'targetPos': 'Preposition',
      'correctWords': ['under'],
    },
  ];

  void _onWordTap(String word) {
    if (_isRoundComplete) return;

    final question = _questions[_currentIndex];
    final correctWords = question['correctWords'] as List<String>;

    // Clean word for comparison (remove punctuation if needed, though list has it)
    if (correctWords.contains(word)) {
      // Correct!
      setState(() {
        _isRoundComplete = true;
        _score++;
      });
      SoundService().playSuccess();
      _showFeedback(true, "Correct! \"$word\" is a ${question['targetPos']}.");
      Future.delayed(const Duration(seconds: 1), _nextQuestion);
    } else {
      // Wrong
      SoundService().playError();
      _showFeedback(false, "Try again! Find the ${question['targetPos']}.");
    }
  }

  void _showFeedback(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        duration: const Duration(seconds: 1),
      ),
    );
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
              Navigator.pop(context);
              Navigator.pop(context);
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

    final question = _questions[_currentIndex];
    final words = question['words'] as List<String>;
    final target = question['targetPos'] as String;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Parts of Speech"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Target Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC779D0), Color(0xFF4FACFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    "Tap the",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                        target.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 1.seconds,
                      ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Word Cloud
            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: words.map((word) {
                  return GestureDetector(
                    onTap: () => _onWordTap(word),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white24
                              : onSurface.withValues(alpha: 0.16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.1,
                            ),
                            blurRadius: 5,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        word,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2, end: 0);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
