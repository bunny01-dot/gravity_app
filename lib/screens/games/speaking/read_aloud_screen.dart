import 'package:flutter/material.dart';
import 'package:gravity_app/utils/game_utils.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:gravity_app/services/sound_service.dart';

class ReadAloudScreen extends StatefulWidget {
  const ReadAloudScreen({super.key});

  @override
  State<ReadAloudScreen> createState() => _ReadAloudScreenState();
}

class _ReadAloudScreenState extends State<ReadAloudScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  int _currentIndex = 0;

  String _recognizedText = "";
  double _score = 0.0;
  bool _finished = false;

  final List<String> _passages = [
    "The sun rises in the east and sets in the west. It gives us light and warmth.",
    "Reading books is a great way to learn new things and explore different worlds without leaving your chair.",
    "Practice makes perfect. The more you speak English, the more confident you will become.",
    "A journey of a thousand miles begins with a single step.",
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _toggleListening() async {
    if (_isListening) {
      _stopListening();
    } else {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _recognizedText =
              ""; // Clear previous attempts? Or append? Let's clear for retry.
        });

        _speech.listen(
          onResult: (val) {
            setState(() {
              _recognizedText = val.recognizedWords;
            });
          },
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.dictation,
            partialResults: true,
            cancelOnError: true,
          ),
        );
      }
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
    _calculateScore();
  }

  void _calculateScore() {
    // Use GameUtils for robust matching
    double accuracy = GameUtils.calculateAccuracy(
      _passages[_currentIndex],
      _recognizedText,
    );

    setState(() {
      _score = accuracy;
      _finished = true;
    });

    if (_score > 0.7) {
      SoundService().playSuccess();
    } else {
      SoundService().playError();
    }
  }

  void _next() {
    if (_currentIndex < _passages.length - 1) {
      setState(() {
        _currentIndex++;
        _recognizedText = "";
        _finished = false;
        _score = 0.0;
      });
    } else {
      Navigator.pop(context); // Finish
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
        title: const Text("Read Aloud"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Passage Card
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                _passages[_currentIndex],
                style: TextStyle(
                  color: onSurface,
                  fontSize: 22,
                  height: 1.6,
                  fontFamily: 'serif',
                ),
              ),
            ),

            const SizedBox(height: 32),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black26
                      : onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _recognizedText.isEmpty
                        ? "Spoken text will appear here..."
                        : _recognizedText,
                    style: TextStyle(
                      color: _isListening
                          ? onSurface
                          : onSurface.withValues(alpha: 0.54),
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_finished) ...[
              Text(
                "Score: ${(_score * 100).toInt()}%",
                style: TextStyle(
                  color: _score > 0.7
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    "Next Passage",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ] else
              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isListening
                        ? Colors.redAccent
                        : const Color(0xFF00E5FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isListening
                                    ? Colors.redAccent
                                    : const Color(0xFF00E5FF))
                                .withValues(alpha: 0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: _isListening ? Colors.white : Colors.black,
                    size: 36,
                  ),
                ),
              ),

            const SizedBox(height: 12),
            if (!_finished && !_isListening)
              Text(
                "Tap to Record",
                style: TextStyle(color: onSurface.withValues(alpha: 0.38)),
              ),
            if (_isListening)
              const Text(
                "Recording...",
                style: TextStyle(color: Colors.redAccent),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
