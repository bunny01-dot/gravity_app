import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Unified Speech Recognition Service
/// Provides a consistent interface for all speaking games
class SpeechRecognitionService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _isInitialized = false;
  static String? _preferredLocaleId;
  static String? _cachedResolvedLocaleId;
  static const List<String> _englishLocaleFallbackOrder = <String>[
    'en_IN',
    'en_US',
    'en_GB',
    'en_AU',
  ];

  static String _normalizeLocaleId(String localeId) {
    return localeId.trim().replaceAll('-', '_').toLowerCase();
  }

  static String? _findLocaleMatch(List<String> available, String candidate) {
    final normalizedCandidate = _normalizeLocaleId(candidate);
    if (normalizedCandidate.isEmpty) return null;

    for (final localeId in available) {
      if (_normalizeLocaleId(localeId) == normalizedCandidate) {
        return localeId;
      }
    }

    final languageCode = normalizedCandidate.split('_').first;
    for (final localeId in available) {
      final normalizedAvailable = _normalizeLocaleId(localeId);
      if (normalizedAvailable == languageCode ||
          normalizedAvailable.startsWith('${languageCode}_')) {
        return localeId;
      }
    }

    return null;
  }

  static Future<String?> _resolveLocaleId({String? requestedLocaleId}) async {
    final requested = requestedLocaleId?.trim() ?? '';
    if (requested.isEmpty &&
        _preferredLocaleId == null &&
        _cachedResolvedLocaleId != null) {
      return _cachedResolvedLocaleId;
    }

    final locales = await _speech.locales();
    final available = locales
        .map((locale) => locale.localeId.trim())
        .where((localeId) => localeId.isNotEmpty)
        .toList(growable: false);

    if (available.isEmpty) {
      return requested.isNotEmpty ? requested : _preferredLocaleId;
    }

    String? resolved;

    if (requested.isNotEmpty) {
      resolved = _findLocaleMatch(available, requested);
    }

    if (resolved == null && _preferredLocaleId != null) {
      resolved = _findLocaleMatch(available, _preferredLocaleId!);
    }

    if (resolved == null) {
      final deviceLocaleTag = WidgetsBinding.instance.platformDispatcher.locale
          .toLanguageTag();
      if (deviceLocaleTag.isNotEmpty) {
        resolved = _findLocaleMatch(available, deviceLocaleTag);
      }
    }

    if (resolved == null) {
      for (final fallback in _englishLocaleFallbackOrder) {
        resolved = _findLocaleMatch(available, fallback);
        if (resolved != null) break;
      }
    }

    resolved ??= available.first;

    if (requested.isEmpty) {
      _cachedResolvedLocaleId = resolved;
    }
    return resolved;
  }

  /// Initialize speech recognition
  /// Call once at app start or before first use
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => debugPrint('Speech Recognition Error: $error'),
        onStatus: (status) => debugPrint('Speech Recognition Status: $status'),
      );

      if (_isInitialized) {
        debugPrint('SpeechRecognitionService: Initialized successfully');
      } else {
        debugPrint('SpeechRecognitionService: Failed to initialize');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint(
        'SpeechRecognitionService: Exception during initialization: $e',
      );
      return false;
    }
  }

  /// Request microphone permission from user
  /// Returns true if granted, false otherwise
  static Future<bool> requestPermission() async {
    try {
      final status = await Permission.microphone.request();
      debugPrint('SpeechRecognitionService: Permission status: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('SpeechRecognitionService: Permission error: $e');
      return false;
    }
  }

  /// Check if microphone permission is already granted
  static Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Start listening for speech input
  /// Returns the recognized text or null if failed/timeout
  ///
  /// [timeout] - Maximum duration to listen (default: 5 seconds)
  /// [pauseFor] - How long to wait for pause before stopping (default: 3 seconds)
  /// [onPartialResult] - Optional callback for real-time partial results
  static Future<String?> listen({
    Duration timeout = const Duration(seconds: 5),
    Duration pauseFor = const Duration(seconds: 3),
    Function(String)? onPartialResult,
    stt.ListenMode listenMode = stt.ListenMode.dictation,
    String? localeId,
  }) async {
    // 1. Ensure initialized
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        debugPrint('SpeechRecognitionService: Cannot listen - not initialized');
        return null;
      }
    }

    // 2. Check/request permission
    if (!await hasPermission()) {
      final granted = await requestPermission();
      if (!granted) {
        debugPrint(
          'SpeechRecognitionService: Cannot listen - permission denied',
        );
        return null;
      }
    }

    // 3. Start listening
    String result = '';
    bool completed = false;

    try {
      final resolvedLocaleId = await _resolveLocaleId(
        requestedLocaleId: localeId,
      );
      debugPrint(
        'SpeechRecognitionService: Listening with locale: ${resolvedLocaleId ?? 'default'}',
      );

      await _speech.listen(
        onResult: (val) {
          result = val.recognizedWords;
          if (onPartialResult != null && !val.finalResult) {
            onPartialResult(result);
          }
          if (val.finalResult) {
            completed = true;
          }
          debugPrint(
            'SpeechRecognitionService: Recognized: "$result" (final: ${val.finalResult})',
          );
        },
        listenFor: timeout,
        pauseFor: pauseFor,
        localeId: resolvedLocaleId,
        listenOptions: stt.SpeechListenOptions(
          partialResults: onPartialResult != null,
          cancelOnError: true,
          listenMode: listenMode,
        ),
      );

      // Wait for timeout or completion
      final startTime = DateTime.now();
      while (!completed && DateTime.now().difference(startTime) < timeout) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await stop();

      if (result.isNotEmpty) {
        debugPrint('SpeechRecognitionService: Final result: "$result"');
        return result;
      } else {
        debugPrint('SpeechRecognitionService: No speech detected');
        return null;
      }
    } catch (e) {
      debugPrint('SpeechRecognitionService: Error during listening: $e');
      await stop();
      return null;
    }
  }

  /// Stop listening immediately
  static Future<void> stop() async {
    try {
      if (_isInitialized && _speech.isListening) {
        await _speech.stop();
        debugPrint('SpeechRecognitionService: Stopped listening');
      }
    } catch (e) {
      debugPrint('SpeechRecognitionService: Error stopping: $e');
    }
  }

  /// Cancel current listening session
  static Future<void> cancel() async {
    try {
      if (_isInitialized && _speech.isListening) {
        await _speech.cancel();
        debugPrint('SpeechRecognitionService: Cancelled listening');
      }
    } catch (e) {
      debugPrint('SpeechRecognitionService: Error cancelling: $e');
    }
  }

  /// Check if currently listening
  static bool get isListening {
    return _isInitialized && _speech.isListening;
  }

  /// Check if the device/platform supports speech recognition
  static bool get isAvailable {
    return _isInitialized && _speech.isAvailable;
  }

  /// Get list of available locales for speech recognition
  static Future<List<stt.LocaleName>> getLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speech.locales();
  }

  /// Set the locale for speech recognition (default: en-US)
  static Future<void> setLocale(String localeId) async {
    final normalized = localeId.trim();
    _preferredLocaleId = normalized.isEmpty ? null : normalized;
    _cachedResolvedLocaleId = null;
    debugPrint(
      'SpeechRecognitionService: Preferred locale set to: ${_preferredLocaleId ?? 'auto'}',
    );
  }

  /// Compare recognized text with expected text using Levenshtein distance
  /// Returns a similarity score from 0.0 to 1.0 (1.0 = perfect match)
  ///
  /// This is more accurate than simple word matching for pronunciation games.
  static double compareText(String recognized, String expected) {
    final recognizedClean = recognized.toLowerCase().trim();
    final expectedClean = expected.toLowerCase().trim();

    if (recognizedClean == expectedClean) return 1.0;
    if (recognizedClean.isEmpty || expectedClean.isEmpty) return 0.0;

    // Calculate Levenshtein distance
    final distance = _levenshteinDistance(recognizedClean, expectedClean);
    final maxLength = recognizedClean.length > expectedClean.length
        ? recognizedClean.length
        : expectedClean.length;

    // Convert distance to similarity score
    final similarity = 1.0 - (distance / maxLength);
    return similarity.clamp(0.0, 1.0);
  }

  /// Levenshtein distance algorithm
  /// Returns the minimum number of edits needed to transform string a into string b
  static int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final List<List<int>> matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
  }

  /// Calculate pronunciation score (alias for compareText with better name)
  /// Returns 0.0-1.0 where 1.0 is perfect pronunciation
  static double calculatePronunciationScore(String spoken, String target) {
    return compareText(spoken, target);
  }

  /// Dispose and clean up resources
  static Future<void> dispose() async {
    try {
      if (_isInitialized) {
        await stop();
        // speech_to_text doesn't have explicit dispose
        _isInitialized = false;
        _cachedResolvedLocaleId = null;
        debugPrint('SpeechRecognitionService: Disposed');
      }
    } catch (e) {
      debugPrint('SpeechRecognitionService: Error during dispose: $e');
    }
  }
}
