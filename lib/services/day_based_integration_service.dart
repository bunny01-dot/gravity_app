import 'package:flutter/foundation.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/models/verb_item.dart';
import 'package:gravity_app/services/day_based_curriculum_service.dart';
import 'package:gravity_app/services/learning_day_service.dart';
import 'package:gravity_app/services/day_based_progress_service.dart';

/// Integration service that provides day-based curriculum data
/// This service is designed to replace the index-based assignment logic
/// in DataService with deterministic day-based filtering.
@Deprecated('Legacy calendar-based integration service. Unused in stage system.')
class DayBasedIntegrationService {
  // Singleton pattern
  static final DayBasedIntegrationService _instance =
      DayBasedIntegrationService._internal();

  factory DayBasedIntegrationService() {
    return _instance;
  }

  DayBasedIntegrationService._internal();

  final DayBasedCurriculumService _curriculumService =
      DayBasedCurriculumService();
  final LearningDayService _learningDayService = LearningDayService();
  final DayBasedProgressService _progressService = DayBasedProgressService();

  bool _isInitialized = false;

  /// Initialize the day-based curriculum system
  /// This MUST be called before using any other methods
  /// Returns true if initialization was successful
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('OK: Day-based curriculum already initialized');
      return true;
    }

    debugPrint('[LAUNCH] Initializing day-based curriculum system...');

    try {
      // Load and validate vocabulary CSV
      bool vocabLoaded = await _curriculumService.loadVocabularyCsv();
      if (!vocabLoaded) {
        debugPrint(
          'Error: CRITICAL: Vocabulary CSV validation failed. Build blocked.',
        );
        return false;
      }

      // Load and validate verbs CSV
      bool verbsLoaded = await _curriculumService.loadVerbsCsv();
      if (!verbsLoaded) {
        debugPrint('Error: CRITICAL: Verbs CSV validation failed. Build blocked.');
        return false;
      }

      // Hydrate progress from cloud
      await _progressService.hydrateFromCloud();

      _isInitialized = true;

      // Print verification report
      String report = _curriculumService.getVerificationReport();
      debugPrint(report);

      debugPrint('OK: Day-based curriculum system initialized successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error: Failed to initialize day-based curriculum: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get daily vocabulary for today
  /// Returns VocabularyItem objects for the user's current learning day
  Future<List<VocabularyItem>> getDailyVocabulary() async {
    return getVocabularyForDate(DateTime.now());
  }

  /// Get daily verbs for today
  /// Returns VerbItem objects for the user's current learning day
  Future<List<VerbItem>> getDailyVerbs() async {
    return getVerbsForDate(DateTime.now());
  }

  /// Get vocabulary for a specific date
  /// This respects saved per-date assignments
  Future<List<VocabularyItem>> getVocabularyForDate(DateTime date) async {
    if (!_isInitialized) {
      debugPrint(
        '  Day-based curriculum not initialized. Calling initialize()...',
      );
      await initialize();
    }

    // Get learning day number for this date
    int learningDay = await _learningDayService.getLearningDayForDate(date);

    if (learningDay == 0) {
      // Not an active learning day, use current day
      learningDay = await _learningDayService.getCurrentLearningDay();
    }

    // Check if we have saved IDs for this date (for consistency)
    List<String> savedIds = await _progressService.getDailyVocabularyIds(date);

    // Get vocabulary for this learning day
    List<VocabularyItem> dayVocabulary = _curriculumService
        .getDailyVocabularyFor(learningDay);

    if (savedIds.isNotEmpty) {
      // Filter to only saved IDs (preserves exact assignment)
      dayVocabulary = dayVocabulary
          .where((item) => savedIds.contains(item.id))
          .toList();

      // If saved IDs don't match current CSV, log warning
      if (dayVocabulary.length != savedIds.length) {
        debugPrint(
          '  CSV mismatch: Expected ${savedIds.length} items, found ${dayVocabulary.length}',
        );
      }
    } else {
      // First time accessing this date - save IDs
      List<String> ids = dayVocabulary.map((item) => item.id).toList();
      await _progressService.saveDailyVocabularyIds(date, ids);
    }

    return dayVocabulary;
  }

  /// Get verbs for a specific date
  /// This respects saved per-date assignments
  Future<List<VerbItem>> getVerbsForDate(DateTime date) async {
    if (!_isInitialized) {
      debugPrint(
        '  Day-based curriculum not initialized. Calling initialize()...',
      );
      await initialize();
    }

    // Get learning day number for this date
    int learningDay = await _learningDayService.getLearningDayForDate(date);

    if (learningDay == 0) {
      // Not an active learning day, use current day
      learningDay = await _learningDayService.getCurrentLearningDay();
    }

    // Check if we have saved IDs for this date
    List<String> savedIds = await _progressService.getDailyVerbIds(date);

    // Get verbs for this learning day
    List<VerbItem> dayVerbs = _curriculumService.getDailyVerbsFor(learningDay);

    if (savedIds.isNotEmpty) {
      // Filter to only saved IDs (preserves exact assignment)
      dayVerbs = dayVerbs.where((item) => savedIds.contains(item.id)).toList();

      // If saved IDs don't match current CSV, log warning
      if (dayVerbs.length != savedIds.length) {
        debugPrint(
          '  CSV mismatch: Expected ${savedIds.length} items, found ${dayVerbs.length}',
        );
      }
    } else {
      // First time accessing this date - save IDs
      List<String> ids = dayVerbs.map((item) => item.id).toList();
      await _progressService.saveDailyVerbIds(date, ids);
    }

    return dayVerbs;
  }

  /// Get vocabulary for yesterday
  Future<List<VocabularyItem>> getYesterdayVocabulary() async {
    DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
    return getVocabularyForDate(yesterday);
  }

  /// Get verbs for yesterday
  Future<List<VerbItem>> getYesterdayVerbs() async {
    DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
    return getVerbsForDate(yesterday);
  }

  /// Get vocabulary for a range of missed days
  Future<List<VocabularyItem>> getVocabularyForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Get all saved vocabulary IDs for this date range
    List<String> allIds = await _progressService.getVocabularyIdsForDateRange(
      startDate,
      endDate,
    );

    if (allIds.isEmpty) {
      return [];
    }

    // Get all vocabulary items
    List<VocabularyItem> allVocabulary = _curriculumService.getAllVocabulary();

    // Filter to only items with matching IDs
    return allVocabulary.where((item) => allIds.contains(item.id)).toList();
  }

  /// Get verbs for a range of missed days
  Future<List<VerbItem>> getVerbsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Get all saved verb IDs for this date range
    List<String> allIds = await _progressService.getVerbIdsForDateRange(
      startDate,
      endDate,
    );

    if (allIds.isEmpty) {
      return [];
    }

    // Get all verb items
    List<VerbItem> allVerbs = _curriculumService.getAllVerbs();

    // Filter to only items with matching IDs
    return allVerbs.where((item) => allIds.contains(item.id)).toList();
  }

  /// Mark vocabulary items as learned
  Future<void> markVocabularyAsLearned(
    DateTime date,
    List<String> learnedIds,
  ) async {
    await _progressService.markVocabularyAsLearned(date, learnedIds);
  }

  /// Mark verbs as learned
  Future<void> markVerbsAsLearned(
    DateTime date,
    List<String> learnedIds,
  ) async {
    await _progressService.markVerbsAsLearned(date, learnedIds);
  }

  /// Get learned vocabulary IDs for a date
  Future<List<String>> getLearnedVocabularyIds(DateTime date) async {
    return _progressService.getLearnedVocabularyIds(date);
  }

  /// Get learned verb IDs for a date
  Future<List<String>> getLearnedVerbIds(DateTime date) async {
    return _progressService.getLearnedVerbIds(date);
  }

  /// Get current learning day number (1-90)
  Future<int> getCurrentLearningDay() async {
    return _learningDayService.getCurrentLearningDay();
  }

  /// Verify data integrity
  Future<Map<String, dynamic>> verifyIntegrity() async {
    if (!_isInitialized) {
      await initialize();
    }

    List<String> allVocabIds = _curriculumService
        .getAllVocabulary()
        .map((item) => item.id)
        .toList();
    List<String> allVerbIds = _curriculumService
        .getAllVerbs()
        .map((item) => item.id)
        .toList();

    return _progressService.verifyIntegrity(allVocabIds, allVerbIds);
  }

  /// Get comprehensive status report
  Future<String> getStatusReport() async {
    StringBuffer report = StringBuffer();
    report.writeln('=== DAY-BASED CURRICULUM STATUS ===');
    report.writeln('');
    report.writeln('Initialized: $_isInitialized');

    if (_isInitialized) {
      int currentDay = await _learningDayService.getCurrentLearningDay();
      int totalDays = await _learningDayService.getTotalActiveDays();

      report.writeln('Current Learning Day: $currentDay');
      report.writeln('Total Active Days: $totalDays');
      report.writeln('');

      List<VocabularyItem> todayVocab = await getDailyVocabulary();
      List<VerbItem> todayVerbs = await getDailyVerbs();

      report.writeln('Today\'s Vocabulary: ${todayVocab.length} items');
      report.writeln('Today\'s Verbs: ${todayVerbs.length} items');
      report.writeln('');

      Map<String, dynamic> integrity = await verifyIntegrity();
      report.writeln('Integrity Check:');
      report.writeln('  Valid Vocab Dates: ${integrity['valid_vocab_dates']}');
      report.writeln(
        '  Invalid Vocab Dates: ${integrity['invalid_vocab_dates']}',
      );
      report.writeln('  Valid Verb Dates: ${integrity['valid_verb_dates']}');
      report.writeln(
        '  Invalid Verb Dates: ${integrity['invalid_verb_dates']}',
      );
    }

    report.writeln('===================================');
    return report.toString();
  }
}

