import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/services/pronunciation_feedback_service.dart';

class LessonSpeakingCard extends StatefulWidget {
  final String imagePath;
  final String prompt;
  final String? exampleText;
  final VoidCallback onCompleted;

  const LessonSpeakingCard({
    super.key,
    required this.imagePath,
    required this.prompt,
    this.exampleText,
    required this.onCompleted,
  });

  @override
  State<LessonSpeakingCard> createState() => _LessonSpeakingCardState();
}

class _LessonSpeakingCardState extends State<LessonSpeakingCard> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isAvailable = false;
  String _text = "";
  // double _confidence = 1.0;
  bool _hasSpoken = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) {
          if (mounted) {
            setState(() => _isListening = false);
            debugPrint("Speech Error: $errorNotification");
          }
        },
      );

      if (mounted) setState(() => _isAvailable = available);
    } catch (e) {
      debugPrint("Speech Init Error: $e");
      if (mounted) setState(() => _isAvailable = false);
    }
  }

  void _listen() async {
    if (!_isAvailable) {
      // Mock for simulators or if permission denied, so user isn't stuck
      _simulateSpeaking();
      return;
    }

    if (!_isListening) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              // _confidence = val.confidence;
            }
          });

          if (val.finalResult || _text.length > 5) {
            _validateAndComplete();
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(partialResults: true),
      );
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _simulateSpeaking() async {
    // Fallback if mic fails
    setState(() => _isListening = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _text = "Simulated speech for testing...";
      _isListening = false;
    });
    _validateAndComplete();
  }

  void _validateAndComplete() {
    if (_hasSpoken) return;

    // Exposure mode: any captured speech counts.
    if (PronunciationFeedbackService.normalizeText(_text).isNotEmpty) {
      setState(() => _hasSpoken = true);
      SoundService().playCorrect();
      // Auto-advance after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) widget.onCompleted();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image Section
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 15),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                widget.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.mic, size: 80, color: Colors.white24),
              ),
            ).animate().fadeIn(),
          ),
        ),

        // Content Section
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.prompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.exampleText != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Say: \"${widget.exampleText}\"",
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Mic Button
                GestureDetector(
                      onTap: _listen,
                      child: AnimatedContainer(
                        duration: 300.ms,
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening
                              ? Colors.redAccent
                              : Colors.cyanAccent,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isListening
                                          ? Colors.redAccent
                                          : Colors.cyanAccent)
                                      .withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: _isListening ? 10 : 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.black,
                          size: 40,
                        ),
                      ),
                    )
                    .animate(target: _isListening ? 1 : 0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                    ),

                Text(
                  _isListening
                      ? "Listening..."
                      : (_hasSpoken ? "Great!" : "Tap to Speak"),
                  style: TextStyle(
                    color: _hasSpoken ? Colors.greenAccent : Colors.white54,
                  ),
                ),

                if (_text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "\"$_text\"",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
