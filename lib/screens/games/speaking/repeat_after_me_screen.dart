import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import 'package:gravity_app/services/sound_service.dart';

class RepeatAfterMeScreen extends StatefulWidget {
  const RepeatAfterMeScreen({super.key});

  @override
  State<RepeatAfterMeScreen> createState() => _RepeatAfterMeScreenState();
}

class _RepeatAfterMeScreenState extends State<RepeatAfterMeScreen>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  bool _isListening = false;
  bool _isSpeaking = false;

  int _currentIndex = 0;
  String _spokenText = "";
  double _score = 0.0;
  bool _hasResult = false;

  final List<String> _targets = [
    "Beautiful",
    "Where is the library?",
    "I would like a coffee.",
    "Can you help me?",
    "The weather is nice today.",
    "Pronunciation is important.",
    "Technology changes fast.",
  ];

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _playTarget() async {
    if (_isSpeaking || _isListening) return;
    setState(() => _isSpeaking = true);
    await _flutterTts.speak(_targets[_currentIndex]);
  }

  void _startListening() async {
    if (_isSpeaking) return;

    bool available = await _speech.initialize(
      onError: (val) => debugPrint('onError: $val'),
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          if (mounted) {
            setState(() {
              _isListening = false;
              _waveController.stop();
            });
            if (_spokenText.isEmpty) {
              // Handle no input
            } else {
              _calculateScore();
            }
          }
        }
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _spokenText = "";
        _hasResult = false;
        _waveController.repeat(reverse: true);
      });
      _speech.listen(
        onResult: (val) {
          setState(() {
            _spokenText = val.recognizedWords;
          });
        },
        localeId: "en_US",
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
      _waveController.stop();
    });
    _calculateScore();
  }

  void _calculateScore() {
    if (_spokenText.isEmpty) return;

    String target = _targets[_currentIndex].toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );
    String spoken = _spokenText.toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );

    int distance = _levenshtein(target, spoken);
    int maxLength = max(target.length, spoken.length);
    double accuracy = 0.0;

    if (maxLength > 0) {
      accuracy = 1.0 - (distance / maxLength);
    } else {
      accuracy = 1.0;
    }

    // Boost score slightly for user encouragement if it's decent
    if (accuracy > 0.8) accuracy = 1.0;

    setState(() {
      _score = accuracy;
      _hasResult = true;
    });

    if (accuracy > 0.6) {
      SoundService().playSuccess();
    } else {
      SoundService().playError();
    }
  }

  void _next() {
    if (_currentIndex < _targets.length - 1) {
      setState(() {
        _currentIndex++;
        _spokenText = "";
        _hasResult = false;
        _score = 0.0;
      });
    } else {
      // Game Over
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Session Complete!")));
      Navigator.pop(context);
    }
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    int la = a.length;
    int lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;

    List<int> v0 = List<int>.filled(lb + 1, 0);
    List<int> v1 = List<int>.filled(lb + 1, 0);

    for (int i = 0; i <= lb; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < la; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < lb; j++) {
        int cost = (a.codeUnitAt(i) == b.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= lb; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[lb];
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
        title: const Text("Repeat After Me"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Progress
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _targets.length,
              backgroundColor: isDark
                  ? Colors.white10
                  : onSurface.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00E5FF)),
            ),
            const SizedBox(height: 40),

            // Target Text
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _targets[_currentIndex],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  IconButton(
                    onPressed: _playTarget,
                    icon: Icon(
                      _isSpeaking
                          ? Icons.volume_up_rounded
                          : Icons.volume_up_outlined,
                      size: 32,
                      color: const Color(0xFF00E5FF),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Visualization
            if (_isListening)
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height:
                            20 +
                            (_waveController.value *
                                30 *
                                ((index % 2 == 0) ? 1 : 0.5)),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  );
                },
              ),

            if (_hasResult) ...[
              Text(
                "Match: ${(_score * 100).toInt()}%",
                style: TextStyle(
                  color: _score > 0.6 ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You said: \"$_spokenText\"",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.54),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const Spacer(),

            // Controls
            if (_hasResult)
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
                    "Next Word",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              )
            else
              GestureDetector(
                onTapDown: (_) => _startListening(),
                onTapUp: (_) => _stopListening(),
                onTapCancel: _stopListening, // Provide tap-to-toggle fallback
                onTap: () {
                  if (_isListening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: _isListening ? Colors.white : Colors.black,
                    size: 36,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (!_hasResult)
              Text(
                "Tap or Hold to Speak",
                style: TextStyle(color: onSurface.withValues(alpha: 0.38)),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
