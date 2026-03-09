import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';

class PronunciationMatchScreen extends StatefulWidget {
  const PronunciationMatchScreen({super.key});

  @override
  State<PronunciationMatchScreen> createState() =>
      _PronunciationMatchScreenState();
}

class _PronunciationMatchScreenState extends State<PronunciationMatchScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  int _currentIndex = 0;

  String? _matchedWord;

  final List<Map<String, dynamic>> _rounds = [
    {
      'options': ['Sheep', 'Ship', 'Cheap', 'Chip'],
    },
    {
      'options': ['Bat', 'Bet', 'Bit', 'But'],
    },
    {
      'options': ['Cat', 'Cut', 'Cot', 'Coat'],
    },
    {
      'options': ['Walk', 'Work', 'Woke', 'Week'],
    },
    {
      'options': ['Pen', 'Pan', 'Pin', 'Pain'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    bool available = await _speech.initialize(
      onError: (val) => setState(() => _isListening = false),
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _matchedWord = null;
      });
      _speech.listen(
        onResult: (val) {
          if (val.finalResult) {
            String spoken = val.recognizedWords;
            _processResult(spoken);
          }
        },
        localeId: "en_US",
      );
    }
  }

  void _processResult(String spoken) {
    setState(() {
      _isListening = false;
    });

    List<String> options = List<String>.from(_rounds[_currentIndex]['options']);

    // Find closest match
    String bestMatch = "";
    int bestDistance = 999;

    for (String opt in options) {
      int dist = _levenshtein(spoken.toLowerCase(), opt.toLowerCase());
      if (dist < bestDistance) {
        bestDistance = dist;
        bestMatch = opt;
      }
    }

    // Threshold? If user said something completely random
    // For game fun, we map to closest if reasonable (e.g. distance < 3 or length/2)
    if (bestDistance <= 2) {
      setState(() {
        _matchedWord = bestMatch;
      });
      SoundService().playSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You said: $bestMatch"),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(seconds: 2), _nextRound);
    } else {
      setState(() {
        _matchedWord = null;
      });
      SoundService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't match \"$spoken\" to any option."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _nextRound() {
    if (_currentIndex < _rounds.length - 1) {
      setState(() {
        _currentIndex++;
        _matchedWord = null;
      });
    } else {
      // End
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Game Over!")));
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
    final round = _rounds[_currentIndex];
    final options = round['options'] as List<String>;
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
        title: const Text("Pronunciation Match"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              "Read one of the words below aloud.",
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: options.map((word) {
                  bool isMatched = word == _matchedWord;
                  return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isMatched
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                              : cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isMatched
                                ? const Color(0xFF00E5FF)
                                : (isDark
                                      ? Colors.white10
                                      : onSurface.withValues(alpha: 0.1)),
                            width: isMatched ? 3 : 1,
                          ),
                          boxShadow: isMatched
                              ? [
                                  const BoxShadow(
                                    color: Color(0xFF00E5FF),
                                    blurRadius: 20,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            word,
                            style: TextStyle(
                              color: isMatched
                                  ? const Color(0xFF00E5FF)
                                  : onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .animate(target: isMatched ? 1 : 0)
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                      );
                }).toList(),
              ),
            ),

            const Spacer(),

            // Interaction
            GestureDetector(
              onTap: _listen,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? Colors.redAccent
                      : const Color(0xFF00E5FF),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_isListening
                                  ? Colors.redAccent
                                  : const Color(0xFF00E5FF))
                              .withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.graphic_eq : Icons.mic_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isListening ? "Listening..." : "Tap to Speak",
              style: TextStyle(color: onSurface.withValues(alpha: 0.38)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
