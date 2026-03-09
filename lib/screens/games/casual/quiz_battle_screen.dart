import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gravity_app/services/sound_service.dart';

class QuizBattleScreen extends StatefulWidget {
  const QuizBattleScreen({super.key});

  @override
  State<QuizBattleScreen> createState() => _QuizBattleScreenState();
}

class _QuizBattleScreenState extends State<QuizBattleScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;

  late AnimationController _timerController;

  static const int _timePerQuestion = 10; // seconds

  final List<Map<String, dynamic>> _questions = [
    {
      'question': "What is the past tense of 'Go'?",
      'options': ['Goed', 'Gone', 'Went', 'Going'],
      'correct': 2,
    },
    {
      'question': "Which word is a synonym for 'Happy'?",
      'options': ['Sad', 'Joyful', 'Angry', 'Bored'],
      'correct': 1,
    },
    {
      'question': "Choose the correct spelling:",
      'options': ['Recieve', 'Receive', 'Receve', 'Riceive'],
      'correct': 1,
    },
    {
      'question': "Which is a noun?",
      'options': ['Run', 'Green', 'Dog', 'Quickly'],
      'correct': 2,
    },
    {
      'question': "Complete: He ___ to the store.",
      'options': ['Run', 'Runs', 'Running', 'Runned'],
      'correct': 1,
    },
  ];

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _timePerQuestion),
    );
    _startTimer();
  }

  void _startTimer() {
    _timerController.reset();
    _timerController.forward().whenComplete(() {
      if (!_isAnswered) {
        _handleAnswer(-1); // Timeout
      }
    });
  }

  void _handleAnswer(int index) {
    if (_isAnswered) return;
    _isAnswered = true;
    _timerController.stop();

    bool isCorrect = false;
    if (index != -1) {
      isCorrect = index == _questions[_currentIndex]['correct'];
    }

    if (isCorrect) {
      // Bonus for speed
      double remain =
          1.0 - _timerController.value; // 0..1 (1 is full time left)
      int points = 10 + (remain * 10).toInt();
      _score += points;
      SoundService().playSuccess();
    } else {
      SoundService().playError();
    }

    setState(() {});

    Future.delayed(const Duration(seconds: 2), _nextQuestion);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _isAnswered = false;
      });
      _startTimer();
    } else {
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Battle Over!"),
        content: Text("Final Score: $_score"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Exit"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
                _score = 0;
                _isAnswered = false;
              });
              _startTimer();
            },
            child: const Text("Replay"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var q = _questions[_currentIndex];
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
        title: Text("Quiz Battle: Score $_score"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Timer Bar
            AnimatedBuilder(
              animation: _timerController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: 1.0 - _timerController.value,
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(
                    (1.0 - _timerController.value) > 0.3
                        ? Colors.greenAccent
                        : Colors.red,
                  ),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                );
              },
            ),

            const SizedBox(height: 40),

            // Question Card
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8E2DE2).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                q['question'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Spacer(),

            // Options
            Column(
              children: List.generate((q['options'] as List).length, (index) {
                String opt = q['options'][index];
                bool isCorrect = index == q['correct'];

                Color btnColor = cardBg;
                Color fgColor = onSurface;
                if (_isAnswered) {
                  if (isCorrect) {
                    btnColor = Colors.green;
                    fgColor = Colors.white;
                  } else if (index == -1) {
                  } // ignored
                  else {
                    btnColor = isDark
                        ? Colors.white10
                        : onSurface.withValues(alpha: 0.08);
                    fgColor = onSurface.withValues(alpha: 0.5);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => _handleAnswer(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        foregroundColor: fgColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(opt, style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
