import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gravity_app/services/sound_service.dart';

class WordRaceScreen extends StatefulWidget {
  const WordRaceScreen({super.key});

  @override
  State<WordRaceScreen> createState() => _WordRaceScreenState();
}

class _WordRaceScreenState extends State<WordRaceScreen>
    with TickerProviderStateMixin {
  int _score = 0;
  int _streak = 0;
  int _timeLeft = 30;
  Timer? _gameTimer;

  // Tasks: simplified format
  final List<Map<String, dynamic>> _tasks = [
    {
      'q': "Synonym of 'Big'",
      'opts': ['Small', 'Large', 'Tiny'],
      'ans': 1,
    },
    {
      'q': "Antonym of 'Hot'",
      'opts': ['Cold', 'Warm', 'Boiling'],
      'ans': 0,
    },
    {
      'q': "'Cat' is a...",
      'opts': ['Verb', 'Noun', 'Adjective'],
      'ans': 1,
    },
    {
      'q': "Past of 'Eat'",
      'opts': ['Eaten', 'Ate', 'Eating'],
      'ans': 1,
    },
    {
      'q': "Plural of 'Mouse'",
      'opts': ['Mouses', 'Mice', 'Mouse'],
      'ans': 1,
    },
    {
      'q': "Synonym of 'Fast'",
      'opts': ['Slow', 'Quick', 'Lazy'],
      'ans': 1,
    },
    {
      'q': "Antonym of 'Happy'",
      'opts': ['Sad', 'Glad', 'Joy'],
      'ans': 0,
    },
  ];

  late Map<String, dynamic> _currentTask;

  @override
  void initState() {
    super.initState();
    _nextTask();
    _startGame();
  }

  void _startGame() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _gameOver();
      }
    });
  }

  void _nextTask() {
    setState(() {
      _currentTask = (_tasks..shuffle()).first;
    });
  }

  void _handleAnswer(int index) {
    if (index == _currentTask['ans']) {
      _streak++;
      int bonus = (_streak ~/ 3);
      _score += (10 + (bonus * 5));
      SoundService().playSuccess();
      _nextTask(); // Instant switch
    } else {
      _streak = 0;
      SoundService().playError();
      // Penalty? Time deduction?
      setState(() {
        if (_timeLeft > 2) _timeLeft -= 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("-2 Seconds!"),
          duration: Duration(milliseconds: 500),
          backgroundColor: Colors.red,
        ),
      );
      _nextTask();
    }
  }

  void _gameOver() {
    _gameTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Time's Up!"),
        content: Text("Score: $_score\nMax Streak: $_streak"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
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

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Word Race"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      "TIME",
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.56),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "$_timeLeft",
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "SCORE",
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.56),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "$_score",
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "STREAK",
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.56),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "x$_streak",
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // Task Card
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : onSurface.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _currentTask['q'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Options
            ...List.generate((_currentTask['opts'] as List).length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => _handleAnswer(i),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FACFE),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _currentTask['opts'][i],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
