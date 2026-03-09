import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';

class AudioGuessScreen extends StatefulWidget {
  const AudioGuessScreen({super.key});

  @override
  State<AudioGuessScreen> createState() => _AudioGuessScreenState();
}

class _AudioGuessScreenState extends State<AudioGuessScreen> {
  late FlutterTts _flutterTts;
  int _currentIndex = 0;
  bool _answered = false;

  final List<Map<String, dynamic>> _quizzes = [
    {
      'word': 'Bicycle',
      'options': ['Bicycle', 'Tricycle', 'Motorcycle', 'Circle'],
      'correctIndex': 0,
    },
    {
      'word': 'Elephant',
      'options': ['Elegant', 'Element', 'Elephant', 'Elevator'],
      'correctIndex': 2,
    },
    {
      'word': 'Library',
      'options': ['Liberty', 'Library', 'Liberal', 'Lightly'],
      'correctIndex': 1,
    },
    {
      'word': 'Wednesday',
      'options': ['Wedding', 'Wednesday', 'Yesterday', 'Weekend'],
      'correctIndex': 1,
    },
    {
      'word': 'Mountain',
      'options': ['Fountain', 'Mountain', 'Maintain', 'Morning'],
      'correctIndex': 1,
    },
  ];

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
  }

  void _playAudio() async {
    await _flutterTts.speak(_quizzes[_currentIndex]['word']);
  }

  void _onOptionSelected(int index) {
    if (_answered) return;

    setState(() => _answered = true);

    final correct = _quizzes[_currentIndex]['correctIndex'] as int;
    if (index == correct) {
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
          content: Text("Try Again!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      // Allow retry or move on? Let's move on for flow
      Future.delayed(const Duration(seconds: 1), _next);
    }
  }

  void _next() {
    if (_currentIndex < _quizzes.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
      });
      // Auto play next?
      // _playAudio();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quizzes[_currentIndex];
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
        title: const Text("Audio Guess"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),

            // Play Button Card
            GestureDetector(
              onTap: _playAudio,
              child:
                  Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFFD700,
                              ).withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 80,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                        duration: 1.seconds,
                      ),
            ),

            const SizedBox(height: 24),
            Text(
              "Tap to Listen",
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.54),
                fontSize: 18,
              ),
            ),

            const Spacer(),

            // Options
            Expanded(
              flex: 2,
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
                children: List.generate((quiz['options'] as List).length, (
                  index,
                ) {
                  final word = quiz['options'][index];
                  return ElevatedButton(
                    onPressed: () => _onOptionSelected(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardBg,
                      foregroundColor: onSurface,
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
                      word,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().fadeIn().slideY(
                    begin: 0.2,
                    end: 0,
                    delay: (index * 50).ms,
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
