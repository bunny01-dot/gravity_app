import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/utils/safe_navigation.dart';

class SoundPickerScreen extends StatefulWidget {
  const SoundPickerScreen({super.key});

  @override
  State<SoundPickerScreen> createState() => _SoundPickerScreenState();
}

class _SoundPickerScreenState extends State<SoundPickerScreen> {
  late FlutterTts _flutterTts;
  int _currentIndex = 0;
  bool _answered = false;

  final List<Map<String, dynamic>> _quizzes = [
    {
      'sound': '//',
      'example': 'as in "Shoe"',
      'options': ['See', 'She', 'Sue'],
      'correctIndex': 1, // She
    },
    {
      'sound': '//',
      'example': 'as in "Think"',
      'options': ['Tank', 'Thank', 'Sank'],
      'correctIndex': 1, // Thank
    },
    {
      'sound': '/i:/',
      'example': 'as in "Sheep"',
      'options': ['Ship', 'Sheep', 'Chip'],
      'correctIndex': 1, // Sheep
    },
    {
      'sound': '//',
      'example': 'as in "Cat"',
      'options': ['Car', 'Kate', 'Cat'],
      'correctIndex': 2, // Cat
    },
    {
      'sound': '/d/',
      'example': 'as in "Judge"',
      'options': ['Gym', 'Gum', 'Game'],
      'correctIndex': 0, // Gym (/dm/)
    },
  ];

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
  }

  void _playSound(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.speak(text);
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
          content: Text("Incorrect!"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _next() {
    if (_currentIndex < _quizzes.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
      });
    } else {
      SafeNavigation.tryPop(
        context,
        source: 'lib/screens/games/speaking/sound_picker_screen.dart',
      );
    }
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
        title: const Text("Sound Picker"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Phonetic Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.blueAccent, blurRadius: 20),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Find the word with the sound:",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    quiz['sound'],
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quiz['example'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ).animate().scale(),

            const SizedBox(height: 60),

            // Options
            Expanded(
              child: ListView.separated(
                itemCount: (quiz['options'] as List).length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final word = quiz['options'][index];
                  return GestureDetector(
                    onTap: () => _onOptionSelected(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              word,
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.volume_up_rounded,
                              color: Colors.blueAccent,
                            ),
                            onPressed: () => _playSound(word),
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: (index * 100).ms).slideX();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
