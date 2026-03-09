import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/tts_service.dart'; // Import TTS
import 'package:gravity_app/widgets/tts_speed_control.dart';
import 'package:gravity_app/services/pronunciation_feedback_service.dart';
import 'package:gravity_app/services/active_route_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailySpeakingChallengeScreen extends StatefulWidget {
  final List<Map<String, String>> words;
  final VoidCallback onCompleted;
  final String preferredLanguage;

  const DailySpeakingChallengeScreen({
    super.key,
    required this.words,
    required this.onCompleted,
    required this.preferredLanguage,
  });

  @override
  State<DailySpeakingChallengeScreen> createState() =>
      _DailySpeakingChallengeScreenState();
}

class _DailySpeakingChallengeScreenState
    extends State<DailySpeakingChallengeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const int _requiredPromptCount = 5;
  static const int _skipUnlockAttempt = 3;
  static const String _stateKey = 'daily_speaking_state_v1';
  static const String _stateTimestampKey = 'daily_speaking_state_ts';
  static const Duration _stateFreshWindow = Duration(hours: 8);
  late stt.SpeechToText _speech;
  final TtsService _ttsService = TtsService(); // TTS Instance
  late List<Map<String, String>> _sessionWords;
  bool _isListening = false;
  String _spokenText = "";
  int _currentIndex = 0;
  bool _isCorrect = false;
  int _attempt = 0;
  int _micPressCount = 0;
  String _feedbackText = "";
  bool _resultHandledForCurrentCapture = false;
  bool _isAdvanceQueued = false;
  String? _resolvedLocaleId;

  // Animation controller for the mic pulse
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speech = stt.SpeechToText();
    _sessionWords = _buildSessionWords(widget.words);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _restoreSessionState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speech.stop();
    _pulseController.dispose();
    super.dispose();
  }

  DateTime? _recordingStartTime;
  bool _manualStop = false;

  bool get _isSkipUnlocked => _micPressCount >= _skipUnlockAttempt;

  bool get _canSkipCurrentSentence =>
      _isSkipUnlocked && !_isCorrect && !_isListening;

  List<Map<String, String>> _buildSessionWords(
    List<Map<String, String>> input,
  ) {
    if (input.isEmpty) return const [];

    final normalized = <Map<String, String>>[];
    final seed = input
        .map((item) => Map<String, String>.from(item))
        .toList(growable: false);

    if (seed.length >= _requiredPromptCount) {
      return seed.take(_requiredPromptCount).toList(growable: false);
    }

    normalized.addAll(seed);
    int repeatIndex = 0;
    while (normalized.length < _requiredPromptCount) {
      final base = seed[repeatIndex % seed.length];
      final clone = Map<String, String>.from(base);
      final baseId = (base['id'] ?? base['word'] ?? 'pronunciation').trim();
      clone['id'] = '${baseId}_repeat_${normalized.length}';
      normalized.add(clone);
      repeatIndex++;
    }
    return normalized;
  }

  String _sessionSignatureFor(List<Map<String, String>> words) {
    return words
        .map((item) {
          final id = (item['id'] ?? '').trim();
          final word = (item['word'] ?? '').trim();
          final sentence = (item['english_example'] ?? '').trim();
          return '${id.toLowerCase()}|${word.toLowerCase()}|${sentence.toLowerCase()}';
        })
        .join('||');
  }

  List<Map<String, String>> _parseWords(dynamic raw) {
    if (raw is! List) return const [];
    final parsed = <Map<String, String>>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      parsed.add(
        entry.map(
          (key, value) =>
              MapEntry(key.toString(), value?.toString().trim() ?? ''),
        ),
      );
    }
    return parsed;
  }

  Future<void> _restoreSessionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_stateKey);
      final ts = prefs.getInt(_stateTimestampKey);
      if (raw == null || raw.isEmpty || ts == null) {
        await _persistProgressState();
        return;
      }

      final ageMs = DateTime.now().millisecondsSinceEpoch - ts;
      if (ageMs > _stateFreshWindow.inMilliseconds) {
        await _clearProgressState();
        await _persistProgressState();
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await _clearProgressState();
        await _persistProgressState();
        return;
      }

      final expectedSignature = _sessionSignatureFor(_sessionWords);
      final restoredSignature = (decoded['signature'] ?? '').toString();
      if (restoredSignature != expectedSignature) {
        await _clearProgressState();
        await _persistProgressState();
        return;
      }

      final restoredWords = _parseWords(decoded['words']);
      final words = restoredWords.isEmpty ? _sessionWords : restoredWords;
      if (words.isEmpty) {
        await _clearProgressState();
        return;
      }
      final restoredIndexRaw = decoded['currentIndex'];
      final restoredIndex = restoredIndexRaw is int ? restoredIndexRaw : 0;
      final int clampedIndex = restoredIndex.clamp(0, words.length - 1);

      if (!mounted) return;
      setState(() {
        _sessionWords = words;
        _currentIndex = clampedIndex;
        _attempt = (decoded['attempt'] is int ? decoded['attempt'] as int : 0)
            .clamp(0, 999);
        _micPressCount =
            (decoded['micPressCount'] is int
                    ? decoded['micPressCount'] as int
                    : _attempt)
                .clamp(0, 999);
        _spokenText = (decoded['spokenText'] ?? '').toString();
        _feedbackText = (decoded['feedbackText'] ?? '').toString();
        _isCorrect = decoded['isCorrect'] == true;
      });
      await _persistProgressState();
    } catch (_) {
      await _clearProgressState();
      await _persistProgressState();
    }
  }

  Future<void> _persistProgressState() async {
    if (_hasCompletedLesson || _sessionWords.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{
        'signature': _sessionSignatureFor(_sessionWords),
        'currentIndex': _currentIndex,
        'attempt': _attempt,
        'micPressCount': _micPressCount,
        'spokenText': _spokenText,
        'feedbackText': _feedbackText,
        'isCorrect': _isCorrect,
        'preferredLanguage': widget.preferredLanguage,
        'words': _sessionWords,
      };
      await prefs.setString(_stateKey, jsonEncode(payload));
      await prefs.setInt(
        _stateTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      await ActiveRouteService.save(
        lessonId: 'daily_speaking',
        index: _currentIndex,
        type: 'daily_speaking',
      );
    } catch (_) {}
  }

  Future<void> _clearProgressState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stateKey);
    await prefs.remove(_stateTimestampKey);
    await ActiveRouteService.clear();
  }

  void _showFeedbackSnackBar(
    String message, {
    Color backgroundColor = Colors.orangeAccent,
  }) {
    if (!mounted || _canSkipCurrentSentence) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _manualStop = true;
      _speech.stop();
      if (_isListening && mounted) {
        setState(() {
          _isListening = false;
          _pulseController.stop();
        });
      }
      _persistProgressState();
    }
  }

  void _queueNextWord() {
    if (_isAdvanceQueued) return;
    _isAdvanceQueued = true;
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      _isAdvanceQueued = false;
      _nextWord();
    });
  }

  String _normalizeLocaleId(String localeId) {
    return localeId.trim().replaceAll('-', '_').toLowerCase();
  }

  Future<String> _resolveLocaleId() async {
    if (_resolvedLocaleId != null && _resolvedLocaleId!.trim().isNotEmpty) {
      return _resolvedLocaleId!;
    }

    final locales = await _speech.locales();
    final available = locales
        .map((locale) => locale.localeId.trim())
        .where((localeId) => localeId.isNotEmpty)
        .toList(growable: false);

    if (available.isEmpty) {
      _resolvedLocaleId = 'en_US';
      return _resolvedLocaleId!;
    }

    String? pickMatch(List<String> candidates) {
      for (final candidate in candidates) {
        final normalizedCandidate = _normalizeLocaleId(candidate);
        for (final localeId in available) {
          if (_normalizeLocaleId(localeId) == normalizedCandidate) {
            return localeId;
          }
        }
      }
      return null;
    }

    final prefersIndianEnglish =
        widget.preferredLanguage == 'Hindi' ||
        widget.preferredLanguage == 'Tamil';
    final candidates = prefersIndianEnglish
        ? const ['en_IN', 'en-US', 'en_GB', 'en_US']
        : const ['en_US', 'en-US', 'en_GB', 'en_IN'];

    _resolvedLocaleId =
        pickMatch(candidates) ??
        available.firstWhere(
          (localeId) => _normalizeLocaleId(localeId).startsWith('en_'),
          orElse: () => available.first,
        );

    debugPrint('DailySpeakingChallenge: Using STT locale $_resolvedLocaleId');
    return _resolvedLocaleId!;
  }

  void _skipCurrentSentence() {
    if (_isListening) return;
    _manualStop = true;
    _speech.stop();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _nextWord();
  }

  String _simplifiedFeedbackFor({
    required PronunciationScoreClass scoreClass,
    required int attempt,
  }) {
    switch (scoreClass) {
      case PronunciationScoreClass.clear:
        return "Clear. Nice pronunciation. Keep going.";
      case PronunciationScoreClass.almost:
        return "Almost There. Good attempt. Stress the key sounds once more.";
      case PronunciationScoreClass.partial:
        return "Try Again. Speak a little slower and clearer.";
      case PronunciationScoreClass.miss:
        if (attempt >= 2) {
          return "Try Again. Listen once, then repeat slowly.";
        }
        return "Try Again. Speak a bit louder and slower.";
    }
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    final result = await Permission.microphone.request();
    if (result.isGranted) return true;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for speaking.'),
        ),
      );
    }
    return false;
  }

  void _listen() async {
    if (!_isListening) {
      final hasPermission = await _ensureMicPermission();
      if (!hasPermission) return;
      if (mounted) {
        setState(() {
          _micPressCount += 1;
          _isCorrect = false;
        });
      } else {
        _micPressCount += 1;
      }
      _manualStop = false;
      _recordingStartTime = DateTime.now();
      _persistProgressState();

      // Initialize/Re-initialize (Safe)
      bool available = await _speech.initialize(
        onStatus: (val) {
          debugPrint('STT Status: $val');
          if (val == 'done' || val == 'notListening') {
            if (_manualStop) return; // Ignore if user tapped stop

            // CHECK FOR PREMATURE STOP (< 4 seconds)
            final duration = DateTime.now().difference(
              _recordingStartTime ?? DateTime.now(),
            );
            if (duration.inMilliseconds < 4000) {
              debugPrint(
                " Premature stop detected (${duration.inMilliseconds}ms). Restarting...",
              );
              Future.delayed(const Duration(milliseconds: 50), () {
                if (mounted && !_isListening && !_manualStop) {
                  _startListeningActual();
                }
              });
              return;
            }

            if (_resultHandledForCurrentCapture) return;
            _resultHandledForCurrentCapture = true;

            if (mounted) {
              setState(() {
                _isListening = false;
                _pulseController.stop();
              });

              if (_spokenText.isEmpty) {
                _attempt += 1;
                final feedback = _simplifiedFeedbackFor(
                  scoreClass: PronunciationScoreClass.miss,
                  attempt: _attempt,
                );
                final skipUnlocked = _isSkipUnlocked;
                setState(() {
                  _isCorrect = false;
                  _feedbackText = skipUnlocked
                      ? '$feedback Skip is now available.'
                      : feedback;
                });
                _showFeedbackSnackBar(feedback, backgroundColor: Colors.orange);
                _persistProgressState();
              } else {
                _checkResult();
              }
            }
          }
        },
        onError: (val) => debugPrint('onError: $val'),
      );

      if (available) {
        _resolvedLocaleId = await _resolveLocaleId();
        _startListeningActual();
      }
    } else {
      _manualStop = true;
      _resultHandledForCurrentCapture = true;
      setState(() {
        _isListening = false;
        _pulseController.stop();
      });
      _speech.stop();
      _persistProgressState();
      // Manual stop currently ends capture without auto-evaluating.
    }
  }

  void _startListeningActual() {
    _resultHandledForCurrentCapture = false;
    setState(() {
      _isListening = true;
      _pulseController.repeat(reverse: true);
      _spokenText = "";
      _isCorrect = false;
    });
    _persistProgressState();

    _speech.listen(
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 4), // Increased to 4s
      onResult: (val) {
        if (!mounted) return;
        setState(() {
          _spokenText = val.recognizedWords;
        });
        _persistProgressState();
        // Smart Stop: stop early when we reach clear accuracy.
        final currentWord = _sessionWords[_currentIndex];
        final target =
            currentWord['english_example'] ?? currentWord['word'] ?? '';
        final score = PronunciationFeedbackService.calculateSimilarity(
          target,
          val.recognizedWords,
        );
        final scoreClass = PronunciationFeedbackService.classifyScore(score);
        final lenientPass = PronunciationFeedbackService.isLenientSentencePass(
          target,
          val.recognizedWords,
        );
        if (scoreClass == PronunciationScoreClass.clear || lenientPass) {
          if (_resultHandledForCurrentCapture) return;
          _resultHandledForCurrentCapture = true;
          _manualStop = true;
          _speech.stop();
          setState(() {
            _isListening = false;
            _pulseController.stop();
          });
          _checkResult();
        }
      },
      localeId: _resolvedLocaleId ?? 'en_US',
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation, // Better for sentences
      ),
    );
  }

  void _checkResult() {
    final currentWord = _sessionWords[_currentIndex];
    final target = (currentWord['english_example'] ?? currentWord['word'] ?? '')
        .trim();
    final spoken = _spokenText.trim();

    _attempt += 1;
    final score = spoken.isEmpty
        ? 0.0
        : PronunciationFeedbackService.calculateSimilarity(target, spoken);
    final scoreClass = PronunciationFeedbackService.classifyScore(score);
    final lenientPass = PronunciationFeedbackService.isLenientSentencePass(
      target,
      spoken,
    );
    final isSuccess =
        scoreClass == PronunciationScoreClass.clear || lenientPass;
    final feedback = _simplifiedFeedbackFor(
      scoreClass: scoreClass,
      attempt: _attempt,
    );
    const lenientFeedback = "Good enough. Moving on.";
    final skipUnlocked = _isSkipUnlocked;
    final effectiveFeedback = isSuccess
        ? (scoreClass == PronunciationScoreClass.clear
              ? feedback
              : lenientFeedback)
        : !skipUnlocked
        ? feedback
        : '$feedback Skip is now available.';

    debugPrint("Target: $target | Spoken: $spoken | Score: $score");

    setState(() {
      _isCorrect = isSuccess;
      _feedbackText = effectiveFeedback;
    });

    if (spoken.isEmpty) {
      _showFeedbackSnackBar(feedback, backgroundColor: Colors.orange);
      _persistProgressState();
      return;
    }

    if (isSuccess) {
      // Auto advance after short delay
      _persistProgressState();
      _queueNextWord();
      return;
    }

    final shouldBlock = PronunciationFeedbackService.shouldBlockProgress(
      PronunciationMode.accuracyCheck,
      score,
      _attempt,
    );

    if (!shouldBlock) {
      _showFeedbackSnackBar("You can skip this sentence or try again.");
      _persistProgressState();
      return;
    }

    _showFeedbackSnackBar(feedback);
    _persistProgressState();
  }

  void _nextWord() {
    if (_currentIndex < _sessionWords.length - 1) {
      setState(() {
        _currentIndex++;
        _spokenText = "";
        _isCorrect = false;
        _attempt = 0;
        _micPressCount = 0;
        _feedbackText = "";
      });
      _persistProgressState();
    } else {
      // Completed all - auto finish
      _completeLesson();
    }
  }

  bool _hasCompletedLesson = false;

  void _completeLesson() {
    if (_hasCompletedLesson) return;
    _hasCompletedLesson = true;
    _speech.stop();
    _clearProgressState();
    if (!mounted) return;
    widget.onCompleted();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_sessionWords.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: BackButton(color: colorScheme.onSurface),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "No speaking prompts available right now.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    final currentWord = _sessionWords[_currentIndex];
    // Main Display: The Sentence
    final targetSentence =
        currentWord['english_example'] ?? currentWord['word'] ?? '';
    final rawWord = currentWord['word'] ?? '';
    final meaning = widget.preferredLanguage == 'Hindi'
        ? (currentWord['hindi_meaning'] ?? currentWord['meaning'] ?? '')
        : widget.preferredLanguage == 'Tamil'
        ? (currentWord['tamil_meaning'] ?? currentWord['meaning'] ?? '')
        : '';
    final displayWord = meaning.isNotEmpty ? "$rawWord ($meaning)" : rawWord;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // Custom leading
        leading: BackButton(color: colorScheme.onSurface),
        title: Text(
          "Sentence ${_currentIndex + 1}/${_sessionWords.length}",
          style: TextStyle(color: colorScheme.onSurface),
        ),
        centerTitle: true,
        actions: const [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: TtsSpeedControl(compact: true),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          // Ensure centering
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2), // Top spacing
              // Word Card
              Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHigh
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isCorrect
                            ? Colors.greenAccent
                            : colorScheme.primary.withValues(
                                alpha: isDark ? 0.3 : 0.4,
                              ),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isCorrect
                              ? Colors.greenAccent.withValues(alpha: 0.2)
                              : colorScheme.primary.withValues(
                                  alpha: isDark ? 0.1 : 0.08,
                                ),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          targetSentence,
                          style: TextStyle(
                            fontSize: 24, // Adjusted for sentence
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Hint: Word + Meaning
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: isDark ? 0.66 : 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            displayWord,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // TTS Button inside card
                        GestureDetector(
                          onTap: () async {
                            debugPrint("Playing TTS for: $targetSentence");
                            await _ttsService.speak(targetSentence);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: isDark ? 0.2 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: colorScheme.primary.withValues(
                                  alpha: isDark ? 0.5 : 0.35,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.volume_up_rounded,
                                  color: colorScheme.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Listen",
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(target: _isCorrect ? 1 : 0)
                  .shake(duration: 500.ms, hz: 4, curve: Curves.easeInOut)
                  .tint(color: Colors.green),

              const Spacer(flex: 1),

              // Feedback Text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _feedbackText.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        child: Text(
                          _feedbackText,
                          key: ValueKey(_feedbackText),
                          style: TextStyle(
                            color: _isCorrect
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox(height: 60),
              ),

              const Spacer(flex: 1),

              // Mic Button
              GestureDetector(
                onTap: _listen,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(
                              alpha: 0.5 * _pulseController.value,
                            ),
                            blurRadius: 20 + (30 * _pulseController.value),
                            spreadRadius: 5 + (15 * _pulseController.value),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none_rounded,
                        color: colorScheme.onPrimary,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isListening ? "Listening..." : "Tap to Speak",
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              if (_canSkipCurrentSentence) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                      onPressed: _skipCurrentSentence,
                      icon: const Icon(Icons.skip_next_rounded),
                      label: const Text('Skip Sentence'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .moveY(
                      begin: 0,
                      end: -6,
                      duration: 700.ms,
                      curve: Curves.easeInOut,
                    ),
              ],

              const Spacer(flex: 2), // Bottom spacing
            ],
          ),
        ),
      ),
    );
  }
}
