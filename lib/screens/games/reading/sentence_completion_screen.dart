import 'package:flutter/material.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/utils/safe_navigation.dart';

class SentenceCompletionScreen extends StatefulWidget {
  const SentenceCompletionScreen({super.key});

  @override
  State<SentenceCompletionScreen> createState() =>
      _SentenceCompletionScreenState();
}

class _SentenceCompletionScreenState extends State<SentenceCompletionScreen> {
  int _currentIndex = 0;
  bool _answered = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'start': "I couldn't sleep because...",
      'options': [
        "I was very tired.",
        "the noise was too loud.",
        "I ate a healthy dinner.",
        "the bed was comfortable.",
      ],
      'correct': 1,
    },
    {
      'start': "If it rains tomorrow, we...",
      'options': [
        "will go to the park.",
        "are going swimming.",
        "will stay inside.",
        "played soccer.",
      ],
      'correct': 2,
    },
    {
      'start': "She is studying hard so that...",
      'options': [
        "she can fail the test.",
        "she passes the exam.",
        "it is raining outside.",
        "she forgot her book.",
      ],
      'correct': 1,
    },
  ];

  void _onOptionSelected(int index) {
    if (_answered) return;

    setState(() => _answered = true);
    bool isCorrect = index == _questions[_currentIndex]['correct'];

    if (isCorrect) {
      SoundService().playSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Correct!"),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(const Duration(seconds: 1), _next);
    } else {
      SoundService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incorrect, try to think about the meaning."),
          backgroundColor: Colors.redAccent,
        ),
      );
      Future.delayed(const Duration(seconds: 2), _next);
    }
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
      });
    } else {
      SafeNavigation.tryPop(
        context,
        source: 'lib/screens/games/reading/sentence_completion_screen.dart',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];
    final options = q['options'] as List<String>;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final scaffoldBg = isDark
        ? const Color(0xFF030305)
        : theme.scaffoldBackgroundColor;
    final cardBg = isDark ? const Color(0xFF1E1E2C) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Finish the Sentence"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),

            // Sentence Card
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Complete this:",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    q['start'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Options
            ...List.generate(options.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _onOptionSelected(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardBg,
                      foregroundColor: onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white10
                              : onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      options[index],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              );
            }),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
