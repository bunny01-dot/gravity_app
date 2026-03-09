import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gravity_app/services/sound_service.dart';

class DictationGameScreen extends StatefulWidget {
  const DictationGameScreen({super.key});

  @override
  State<DictationGameScreen> createState() => _DictationGameScreenState();
}

class _DictationGameScreenState extends State<DictationGameScreen> {
  late FlutterTts _flutterTts;
  final TextEditingController _controller = TextEditingController();

  int _currentIndex = 0;
  bool _checked = false;
  double _score = 0;

  final List<String> _sentences = [
    "The sun is shining brightly.",
    "Please open the door.",
    "My favorite color is blue.",
    "She walks to school every day.",
    "Can you hear the music?",
  ];

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _play(); // Auto play first on load? Or wait for user. Let's wait.
  }

  void _play() async {
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.speak(_sentences[_currentIndex]);
  }

  void _checkAnswer() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _checked = true;
    });

    String target = _sentences[_currentIndex].trim();
    String input = _controller.text.trim();

    // Normalize
    String nTarget = target.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    String nInput = input.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    if (nTarget == nInput) {
      _score = 1.0;
      SoundService().playSuccess();
    } else {
      // Calculate simplistic similarity
      // Word match count
      List<String> tWords = nTarget.split(' ');
      List<String> iWords = nInput.split(' ');
      int hits = 0;
      for (var w in tWords) {
        if (iWords.contains(w)) hits++;
      }
      _score = hits / tWords.length;
      SoundService().playError();
    }
  }

  void _next() {
    if (_currentIndex < _sentences.length - 1) {
      setState(() {
        _currentIndex++;
        _checked = false;
        _controller.clear();
        _score = 0;
      });
      _play();
    } else {
      Navigator.pop(context);
    }
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
        title: const Text("Dictation Master"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.headphones_rounded,
                    size: 48,
                    color: Color(0xFFFFD700),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Listen to the sentence and type it exactly.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: onSurface.withValues(alpha: 0.72)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _play,
                    icon: const Icon(
                      Icons.play_circle_filled,
                      color: Colors.black,
                    ),
                    label: const Text(
                      "Play Audio",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: _controller,
              enabled: !_checked,
              style: TextStyle(color: onSurface, fontSize: 18),
              decoration: InputDecoration(
                hintText: "Type what you hear...",
                hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.24)),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF2A2A35)
                    : onSurface.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            if (_checked) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _score == 1.0
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _score == 1.0 ? Colors.green : Colors.red,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _score == 1.0
                          ? "Perfect Match!"
                          : "Accuracy: ${(_score * 100).toInt()}%",
                      style: TextStyle(
                        color: _score == 1.0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (_score < 1.0) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Correct Answer:",
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.54),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _sentences[_currentIndex],
                        style: TextStyle(
                          color: onSurface,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FACFE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Next Sentence"),
              ),
            ] else
              ElevatedButton(
                onPressed: _checkAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FACFE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Submit Answer",
                  style: TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
