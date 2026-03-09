import 'dart:async';
import 'package:gravity_app/utils/game_utils.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';

class TongueTwisterScreen extends StatefulWidget {
  const TongueTwisterScreen({super.key});

  @override
  State<TongueTwisterScreen> createState() => _TongueTwisterScreenState();
}

class _TongueTwisterScreenState extends State<TongueTwisterScreen> {
  late stt.SpeechToText _speech;

  bool _isListening = false;
  int _currentIndex = 0;

  // Timer State
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _tickTimer;
  String _elapsedTime = "0.0s";

  String? _resultText;
  double _score = 0.0;

  final List<String> _twisters = [
    "She sells seashells by the seashore.",
    "Peter Piper picked a peck of pickled peppers.",
    "How much wood would a woodchuck chuck if a woodchuck could chuck wood?",
    "Fuzzy Wuzzy was a bear, Fuzzy Wuzzy had no hair.",
    "I scream, you scream, we all scream for ice cream.",
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void _startAttempt() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
        _resultText = null;
        _score = 0.0;
        _stopwatch.reset();
        _stopwatch.start();
        _elapsedTime = "0.0s";
      });

      _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _elapsedTime =
              "${(_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s";
        });
      });

      _speech.listen(
        onResult: (val) {
          // We might want to stop automatically if final result
          if (val.finalResult) {
            _finishAttempt(val.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 2),
      );
    }
  }

  void _finishAttempt(String recognized) {
    _stopwatch.stop();
    _tickTimer?.cancel();
    _speech.stop();

    // Use GameUtils for robust matching
    double accuracy = GameUtils.calculateAccuracy(
      _twisters[_currentIndex],
      recognized,
    );

    // Speed Bonus (arbitrary - e.g. < 5s is good)
    double timeInSec = _stopwatch.elapsedMilliseconds / 1000;
    double speedFactor = 1.0;
    if (timeInSec < 5.0) {
      speedFactor = 1.2;
    } else if (timeInSec > 10.0) {
      speedFactor = 0.8;
    }

    double finalScore = accuracy * speedFactor;
    if (finalScore > 1.0) finalScore = 1.0;

    setState(() {
      _isListening = false;
      _resultText = recognized;
      _score = finalScore;
    });

    if (finalScore > 0.7) {
      SoundService().playSuccess();
    } else {
      SoundService().playError();
    }
  }

  void _next() {
    if (_currentIndex < _twisters.length - 1) {
      setState(() {
        _currentIndex++;
        _resultText = null;
        _score = 0.0;
        _elapsedTime = "0.0s";
      });
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
        title: const Text("Tongue Twisters"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timer Card
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : onSurface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _elapsedTime,
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 24,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Twister Card
            Container(
              padding: const EdgeInsets.all(32),
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
                _twisters[_currentIndex],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ).animate().slideY(),

            const Spacer(),

            if (_resultText != null) ...[
              Text(
                "Accuracy Score: ${(_score * 100).toInt()}%",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _score > 0.7
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You said: \"$_resultText\"",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.54),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text("Next Challenge"),
              ),
            ] else
              GestureDetector(
                onLongPress: _startAttempt, // or Tap
                onTap: _startAttempt, // Simplify
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isListening
                        ? Colors.redAccent
                        : const Color(0xFF00E5FF),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isListening
                                    ? Colors.redAccent
                                    : const Color(0xFF00E5FF))
                                .withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isListening
                        ? const Text(
                            "LISTENING...",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : const Text(
                            "START CHALLENGE",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
