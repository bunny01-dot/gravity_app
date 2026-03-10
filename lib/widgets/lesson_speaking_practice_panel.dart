import 'package:flutter/material.dart';
import 'package:gravity_app/services/speech_recognition_service.dart';

class LessonSpeakingPracticePanel extends StatefulWidget {
  final Duration listenFor;
  final Duration pauseFor;

  const LessonSpeakingPracticePanel({
    super.key,
    this.listenFor = const Duration(seconds: 10),
    this.pauseFor = const Duration(seconds: 2),
  });

  @override
  State<LessonSpeakingPracticePanel> createState() =>
      _LessonSpeakingPracticePanelState();
}

class _LessonSpeakingPracticePanelState
    extends State<LessonSpeakingPracticePanel> {
  bool _isListening = false;
  bool _hasSpoken = false;
  final ValueNotifier<String> _spokenText = ValueNotifier<String>('');
  int _speechSessionId = 0;

  Future<bool> _ensureMicPermission() async {
    if (await SpeechRecognitionService.hasPermission()) return true;
    final granted = await SpeechRecognitionService.requestPermission();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for speaking.'),
        ),
      );
    }
    return granted;
  }

  Future<void> _toggleSpeaking() async {
    if (_isListening) {
      await SpeechRecognitionService.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    final hasPermission = await _ensureMicPermission();
    if (!hasPermission) return;

    final sessionId = ++_speechSessionId;
    _spokenText.value = '';
    setState(() {
      _isListening = true;
      _hasSpoken = false;
    });

    final result = await SpeechRecognitionService.listen(
      timeout: widget.listenFor,
      pauseFor: widget.pauseFor,
      onPartialResult: (partial) {
        if (!mounted || sessionId != _speechSessionId) return;
        _spokenText.value = partial;
      },
    );

    if (!mounted || sessionId != _speechSessionId) return;

    setState(() {
      _isListening = false;
      if (result != null && result.trim().isNotEmpty) {
        _spokenText.value = result.trim();
        _hasSpoken = true;
      }
    });

    if ((result == null || result.trim().isEmpty) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No speech detected. Tap to try again.')),
      );
    }
  }

  @override
  void dispose() {
    _speechSessionId++;
    SpeechRecognitionService.stop();
    _spokenText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _toggleSpeaking,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? Colors.redAccent : Colors.cyanAccent,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.redAccent : Colors.cyanAccent)
                        .withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: _isListening ? 10 : 2,
                  ),
                ],
              ),
              child: _isListening
                  ? const Icon(Icons.stop, color: Colors.black, size: 40)
                  : const Icon(Icons.mic, color: Colors.black, size: 40),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isListening
              ? 'Listening...'
              : (_hasSpoken ? 'Captured' : 'Tap to Speak'),
          style: TextStyle(
            color: _hasSpoken ? Colors.greenAccent : Colors.white54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<String>(
          valueListenable: _spokenText,
          builder: (context, spokenText, _) {
            if (!_isListening && !_hasSpoken && spokenText.trim().isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Text(
                    'Live Transcript',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    spokenText.isNotEmpty ? '"$spokenText"' : 'Listening...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
