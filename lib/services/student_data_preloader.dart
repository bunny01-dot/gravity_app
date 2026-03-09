import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/cache/memory_cache.dart';
import '../services/data_service.dart';

/// Background data preloader for student learning data
///
/// Features:
/// - Detects user idle time (no interaction for 3 seconds)
/// - Preloads frequently accessed data in background
/// - Provides instant access to cached data
/// - Auto-clears on app lifecycle changes
class StudentDataPreloader {
  static final StudentDataPreloader _instance =
      StudentDataPreloader._internal();
  factory StudentDataPreloader() => _instance;
  StudentDataPreloader._internal();

  // Memory caches for different data types
  final MemoryCache<List<Map<String, dynamic>>> _vocabularyCache = MemoryCache(
    ttl: const Duration(minutes: 30),
    maxSize: 50,
  );

  final MemoryCache<List<Map<String, dynamic>>> _verbsCache = MemoryCache(
    ttl: const Duration(minutes: 30),
    maxSize: 50,
  );

  final MemoryCache<List<Map<String, dynamic>>> _quizCache = MemoryCache(
    ttl: const Duration(hours: 1),
    maxSize: 20,
  );

  final MemoryCache<Map<String, dynamic>> _progressCache = MemoryCache(
    ttl: const Duration(minutes: 5),
    maxSize: 10,
  );

  // Idle detection
  Timer? _idleTimer;
  bool _isPreloading = false;
  bool _isMonitoring = false;

  // Preload statistics
  int _preloadCount = 0;
  DateTime? _lastPreloadTime;

  /// Start monitoring for user idle time
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    debugPrint('[DATA] StudentDataPreloader: Started monitoring for idle time');
  }

  /// Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _idleTimer?.cancel();
    debugPrint('[DATA] StudentDataPreloader: Stopped monitoring');
  }

  /// Called on any user interaction - resets idle timer
  void onUserInteraction() {
    if (!_isMonitoring) return;

    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 3), _onIdleDetected);
  }

  /// Called when user is idle for 3 seconds
  Future<void> _onIdleDetected() async {
    if (_isPreloading) {
      debugPrint('[LAST] Preload already in progress, skipping');
      return;
    }

    debugPrint(' User idle detected - starting background preload');
    _isPreloading = true;
    _lastPreloadTime = DateTime.now();

    try {
      // Priority 1: Vocabulary (most frequently accessed)
      await _preloadVocabulary();

      // Priority 2: Verb forms
      await _preloadVerbs();

      // Priority 3: Quiz questions
      await _preloadQuizQuestions();

      _preloadCount++;
      debugPrint('OK: Background preload complete (#$_preloadCount)');
    } catch (e) {
      debugPrint('[WARN] Preload error: $e');
    } finally {
      _isPreloading = false;
    }
  }

  /// Preload vocabulary data
  Future<void> _preloadVocabulary() async {
    const cacheKey = 'all_vocabulary';

    // Check if already cached and fresh
    if (_vocabularyCache.contains(cacheKey)) {
      debugPrint(' Vocabulary already cached, skipping');
      return;
    }

    try {
      debugPrint('[REFRESH] Preloading vocabulary...');
      final vocab = await DataService().getAllItems('vocabulary');
      // Convert List<Map<String, String>> to List<Map<String, dynamic>>
      final vocabDynamic = vocab
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      _vocabularyCache.set(cacheKey, vocabDynamic);
      debugPrint('OK: Vocabulary cached (${vocabDynamic.length} words)');
    } catch (e) {
      debugPrint('[WARN] Failed to preload vocabulary: $e');
    }
  }

  /// Preload verb forms data
  Future<void> _preloadVerbs() async {
    const cacheKey = 'all_verbs';

    if (_verbsCache.contains(cacheKey)) {
      debugPrint(' Verbs already cached, skipping');
      return;
    }

    try {
      debugPrint('[REFRESH] Preloading verb forms...');
      final verbs = await DataService().getAllItems('verbs');
      // Convert List<Map<String, String>> to List<Map<String, dynamic>>
      final verbsDynamic = verbs
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      _verbsCache.set(cacheKey, verbsDynamic);
      debugPrint('OK: Verb forms cached (${verbsDynamic.length} verbs)');
    } catch (e) {
      debugPrint('[WARN] Failed to preload verbs: $e');
    }
  }

  /// Preload quiz questions
  Future<void> _preloadQuizQuestions() async {
    const cacheKey = 'quiz_questions';

    if (_quizCache.contains(cacheKey)) {
      debugPrint(' Quiz questions already cached, skipping');
      return;
    }

    try {
      debugPrint('[REFRESH] Preloading quiz questions...');
      // getRawQuizData returns List<List<dynamic>>
      final rawQuestions = await DataService().getRawQuizData();

      // Convert to List<Map<String, dynamic>> for easier use
      final questions = rawQuestions.map((row) {
        if (row.length >= 4) {
          return {
            'question': row[0]?.toString() ?? '',
            'optionA': row[1]?.toString() ?? '',
            'optionB': row[2]?.toString() ?? '',
            'optionC': row[3]?.toString() ?? '',
            'optionD': row.length > 4 ? row[4]?.toString() ?? '' : '',
            'correct': row.length > 5 ? row[5]?.toString() ?? '0' : '0',
          };
        }
        return <String, dynamic>{};
      }).toList();

      _quizCache.set(cacheKey, questions);
      debugPrint('OK: Quiz questions cached (${questions.length} questions)');
    } catch (e) {
      debugPrint('[WARN] Failed to preload quiz questions: $e');
    }
  }

  // ===== PUBLIC GETTERS FOR CACHED DATA =====

  /// Get cached vocabulary (instant!)
  List<Map<String, dynamic>>? getCachedVocabulary() {
    return _vocabularyCache.get('all_vocabulary');
  }

  /// Get cached verb forms (instant!)
  List<Map<String, dynamic>>? getCachedVerbs() {
    return _verbsCache.get('all_verbs');
  }

  /// Get cached quiz questions (instant!)
  List<Map<String, dynamic>>? getCachedQuizQuestions() {
    return _quizCache.get('quiz_questions');
  }

  /// Get cached progress data (instant!)
  Map<String, dynamic>? getCachedProgress(String key) {
    return _progressCache.get(key);
  }

  /// Set progress data in cache
  void cacheProgress(String key, Map<String, dynamic> data) {
    _progressCache.set(key, data);
  }

  // ===== CACHE MANAGEMENT =====

  /// Clear non-critical caches (called when app goes to background)
  void clearNonCriticalCache() {
    debugPrint('[DELETE] Clearing non-critical cache (keeping critical data)');
    _quizCache.clear();
    // Keep vocabulary and verbs - they're frequently used
  }

  /// Clear all caches (called when app terminates)
  void clearAllCache() {
    debugPrint('[DELETE] Clearing ALL preloaded data');
    _vocabularyCache.clear();
    _verbsCache.clear();
    _quizCache.clear();
    _progressCache.clear();
    _idleTimer?.cancel();
  }

  /// Force refresh all cached data
  Future<void> forceRefresh() async {
    debugPrint('[REFRESH] Force refreshing all cached data...');
    _vocabularyCache.clear();
    _verbsCache.clear();
    _quizCache.clear();

    // Trigger immediate preload
    await _onIdleDetected();
  }

  /// Get preloader statistics
  Map<String, dynamic> getStats() {
    return {
      'is_monitoring': _isMonitoring,
      'is_preloading': _isPreloading,
      'preload_count': _preloadCount,
      'last_preload': _lastPreloadTime?.toIso8601String(),
      'caches': {
        'vocabulary': _vocabularyCache.getStats(),
        'verbs': _verbsCache.getStats(),
        'quiz': _quizCache.getStats(),
        'progress': _progressCache.getStats(),
      },
    };
  }

  /// Cleanup expired entries from all caches
  void cleanupExpired() {
    _vocabularyCache.cleanupExpired();
    _verbsCache.cleanupExpired();
    _quizCache.cleanupExpired();
    _progressCache.cleanupExpired();
  }
}

