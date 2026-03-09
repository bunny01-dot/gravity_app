import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gravity_app/config/app_config.dart';
import 'package:gravity_app/data/repositories/csv_repository.dart';
import 'package:gravity_app/models/verb_item.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/features/daily_sentences/daily_sentence_service.dart';
import 'package:gravity_app/services/day_based_curriculum_service.dart';
import 'package:gravity_app/services/data_service_curriculum.dart';
import 'package:gravity_app/services/data_service_content_loaders.dart';
import 'package:gravity_app/services/data_service_streak.dart';
import 'package:gravity_app/services/data_service_text_utils.dart';
import 'package:gravity_app/services/xp_reward_policy.dart';
import 'package:gravity_app/services/placement_state_service.dart';
import 'package:gravity_app/services/stage_content_service.dart';
import 'package:gravity_app/services/stage_progress_service.dart';
import 'package:gravity_app/services/vocabulary_service.dart';

part 'data_service_cloud_sync.dart';
part 'data_service_admin.dart';
part 'data_service_mastery_content.dart';
part 'data_service_vocab_progress.dart';
part 'data_service_game_helper.dart';
part 'data_service_learned_vocab.dart';

class DataService {
  // Singleton pattern for DataService to avoid multiple caches
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  List<List<dynamic>>? _cachedVocabData;
  List<List<dynamic>>? _cachedVerbData;
  List<List<dynamic>>? _cachedReadingData;
  String? _cachedReadingLevel;
  List<List<dynamic>>? _cachedWritingData;
  String? _cachedWritingLevel;
  List<List<dynamic>>? _cachedSpeakingData;
  String? _cachedSpeakingLevel;
  List<List<dynamic>>? _cachedListeningData;
  String? _cachedListeningLevel;
  List<List<dynamic>>? _cachedQuizData;
  Map<String, List<String>>? _cachedAntonymMap;

  void clearMemoryCache() {
    _cachedVocabData = null;
    _cachedVerbData = null;
    _cachedReadingData = null;
    _cachedReadingLevel = null;
    _cachedWritingData = null;
    _cachedWritingLevel = null;
    _cachedSpeakingData = null;
    _cachedSpeakingLevel = null;
    _cachedListeningData = null;
    _cachedListeningLevel = null;
    _cachedQuizData = null;
    _cachedAntonymMap = null;
    debugPrint("[CLEAN] DataService: Memory cache cleared.");
  }

  Future<void> wipeAllLibraryData() async {
    return await DataServiceCloudSync(this).wipeAllLibraryData();
  }

  final CsvRepository _csvRepository = CsvRepository();
  StreamSubscription? _userProfileSubscription;

  void listenToUserChanges({required Function(String) onLevelChanged}) {
    DataServiceCloudSync(
      this,
    ).listenToUserChanges(onLevelChanged: onLevelChanged);
  }

  void dispose() {
    DataServiceCloudSync(this).dispose();
  }

  // Force Refresh Cache & Sync
  Future<String> forceRefreshData() async {
    return await DataServiceCloudSync(this).forceRefreshData();
  }

  Future<void> syncQuizDataFromCloud() async {
    return await DataServiceCloudSync(this).syncQuizDataFromCloud();
  }

  // Centralized Curriculum List - 28 Lessons in 4 Phases
  List<Map<String, String>> getCurriculumLessons() {
    return getCurriculumLessonsData();
  }

  // --- Data Management (Import, Save, Update, Delete) ---

  Future<List<Map<String, String>>> getAllItems(String type) async {
    // Ensure data is loaded
    switch (type) {
      case 'vocabulary':
        await _loadVocabData();
        break;
      case 'verbs':
        await _loadVerbData();
        break;
      case 'reading':
        await _loadReadingData();
        break;
      case 'writing':
        await _loadWritingData();
        break;
      case 'speaking':
        await _loadSpeakingData();
        break;
      case 'listening':
        await _loadListeningData();
        break;
      case 'quiz':
        await _loadQuizData();
        break;
    }

    List<List<dynamic>>? targetList;
    switch (type) {
      case 'vocabulary':
        targetList = _cachedVocabData;
        break;
      case 'verbs':
        targetList = _cachedVerbData;
        break;
      case 'reading':
        targetList = _cachedReadingData;
        break;
      case 'writing':
        targetList = _cachedWritingData;
        break;
      case 'speaking':
        targetList = _cachedSpeakingData;
        break;
      case 'listening':
        targetList = _cachedListeningData;
        break;
      case 'quiz':
        targetList = _cachedQuizData;
        break;
    }

    if (targetList == null || targetList.isEmpty) return [];

    final userLanguage = await getUserLanguage();

    // Map to generic structure based on type
    return mapItemsForType(targetList, type, userLanguage: userLanguage);
  }

  Future<bool> importCsvFromUrl(String url, String type) async {
    return await DataServiceCloudSync(this).importCsvFromUrl(url, type);
  }

  // Generic delete method
  Future<void> deleteItem(String type, int index) async {
    return await DataServiceCloudSync(this).deleteItem(type, index);
  }

  // Generic update method
  Future<void> updateItem(
    String type,
    int index,
    Map<String, String> updatedItem,
  ) async {
    return await DataServiceCloudSync(
      this,
    ).updateItem(type, index, updatedItem);
  }

  Future<void> _loadLocalDataIfExists(String type) async {
    //  FORCE DISABLE: Prevent loading old local data found in prefs.
    return;
  }

  Future<List<Map<String, String>>> getDailyItems(String type) async {
    if (type == 'vocabulary') {
      return getDailyVocabulary();
    } else {
      return getDailyVerbs();
    }
  }

  // --- Vocabulary Logic ---

  Future<void> _loadVocabData() async {
    // Attempt Cloud Sync First - DISABLED TO FORCE BEGINNER CSV
    // await _syncWithCloud('custom_vocabulary');

    // if (_cachedVocabData != null && _cachedVocabData!.isNotEmpty) return;

    try {
      // 1. Check Prefs first - DISABLED TO FORCE BEGINNER CSV
      // final prefs = await SharedPreferences.getInstance();
      // if (prefs.containsKey('custom_vocabulary')) {
      //   await _loadLocalDataIfExists('vocabulary');
      //   if (_cachedVocabData != null && _cachedVocabData!.isNotEmpty) return;
      // }

      // 2. Determine Level-Based Asset
      // (Deprecated: We now load all levels into cache to prevent data loss across levels)
      // 3. Load from Assets
      try {
        final List<List<dynamic>> allRows = [];
        for (final lvl in ['Beginner', 'Intermediate', 'Advanced']) {
          try {
            debugPrint("DataService: Indexing Vocabulary $lvl");
            final String rawData = await rootBundle.loadString(
              'assets/Master Sheets/Vocabulary $lvl - Sheet.csv',
            );
            allRows.addAll(normalizeVocabularyRows(parseCsvRows(rawData)));
          } catch (e) {
            debugPrint("DataService: Failed indexing $lvl vocab: $e");
          }
        }
        if (allRows.isEmpty) {
          throw Exception("No vocabulary content could be indexed");
        }
        _cachedVocabData = allRows;
      } catch (e) {
        debugPrint("DataService: Critical Error Loading Vocabs: $e");
        _cachedVocabData = [];
      }
    } catch (e) {
      debugPrint("Error loading local vocabulary: $e");
      _cachedVocabData = [];
    }
  }

  Future<void> _loadAntonymData() async {
    try {
      final String rawData = await rootBundle.loadString(
        'assets/Master Sheets/antonyms.json',
      );
      final List<dynamic> jsonList = json.decode(rawData);
      _cachedAntonymMap = {};
      for (final entry in jsonList) {
        if (entry is Map &&
            entry.containsKey('word') &&
            entry.containsKey('antonym')) {
          final word = entry['word'].toString().toLowerCase();
          final antonym = entry['antonym'].toString().toLowerCase();
          _cachedAntonymMap!.putIfAbsent(word, () => []).add(antonym);
          // Also Add Reverse Mapping
          _cachedAntonymMap!.putIfAbsent(antonym, () => []).add(word);
        }
      }
    } catch (e) {
      debugPrint("DataService: Error loading antonyms: $e");
      _cachedAntonymMap = {};
    }
  }

  /// Enriches a list of vocabulary items with antonym data from the antonyms JSON.
  /// Call this on any item list that may not have antonyms loaded (e.g. stage items).
  Future<List<VocabularyItem>> enrichWithAntonyms(
    List<VocabularyItem> items,
  ) async {
    if (_cachedAntonymMap == null) {
      await _loadAntonymData();
    }
    final map = _cachedAntonymMap;
    if (map == null || map.isEmpty) return items;

    return items.map((item) {
      final key = item.word.trim().toLowerCase();
      final antonyms = map[key];
      if (antonyms == null || antonyms.isEmpty) return item;
      if (item.antonyms.isNotEmpty) return item; // already has antonyms

      return VocabularyItem(
        id: item.id,
        word: item.word,
        definition: item.definition,
        tamilMeaning: item.tamilMeaning,
        hindiMeaning: item.hindiMeaning,
        imageUrl: item.imageUrl,
        audioUrl: item.audioUrl,
        synonyms: item.synonyms,
        localizedSynonyms: item.localizedSynonyms,
        antonyms: antonyms,
        exampleSentence: item.exampleSentence,
        englishExample: item.englishExample,
        tamilExample: item.tamilExample,
        hindiExample: item.hindiExample,
        translation: item.translation,
        difficulty: item.difficulty,
        revisionCount: item.revisionCount,
        isLearned: item.isLearned,
        learnedDate: item.learnedDate,
        pos: item.pos,
        dayNumber: item.dayNumber,
      );
    }).toList();
  }

  Future<String> _getLevelSuffix() async {
    return PlacementStateService.getCourseLevelSuffix();
  }

  String _normalizeLevelToken(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('advanced') ||
        lower.contains('c1') ||
        lower.contains('c2')) {
      return 'Advanced';
    }
    if (lower.contains('intermediate') ||
        lower.contains('b1') ||
        lower.contains('b2')) {
      return 'Intermediate';
    }
    if (lower.contains('beginner') ||
        lower.contains('a1') ||
        lower.contains('a2')) {
      return 'Beginner';
    }
    return value.trim();
  }

  List<List<dynamic>> _filterRowsByLevel(
    List<List<dynamic>> rows, {
    required int levelColumnIndex,
    required String level,
  }) {
    final target = _normalizeLevelToken(level);
    return rows.where((row) {
      if (row.length <= levelColumnIndex) return false;
      final rowLevel = _normalizeLevelToken(row[levelColumnIndex].toString());
      return rowLevel == target;
    }).toList();
  }

  Future<void> _loadVerbData() async {
    // await _syncWithCloud('custom_verbs');
    // if (_cachedVerbData != null && _cachedVerbData!.isNotEmpty) return;
    try {
      // 1. Check Prefs first
      // if (prefs.containsKey('custom_verbs')) {
      //   await _loadLocalDataIfExists('verbs');
      //   if (_cachedVerbData != null && _cachedVerbData!.isNotEmpty) return;
      // }

      // 2. Determine Level-Based Asset
      // (Deprecated: We now load all levels into cache to prevent data loss across levels)
      // 3. Load from Assets
      try {
        final List<List<dynamic>> allRows = [];
        for (final lvl in ['Beginner', 'Intermediate', 'Advanced']) {
          try {
            debugPrint("DataService: Indexing Verb Forms $lvl");
            final String rawData = await rootBundle.loadString(
              'assets/Master Sheets/Verb Forms $lvl - Sheet.csv',
            );
            allRows.addAll(normalizeVerbRows(parseCsvRows(rawData)));
          } catch (e) {
            debugPrint("DataService: Failed indexing $lvl verbs: $e");
          }
        }
        if (allRows.isEmpty) {
          throw Exception("No verb content could be indexed");
        }
        _cachedVerbData = allRows;
      } catch (e) {
        debugPrint("DataService: Critical Error Loading Verbs: $e");
        _cachedVerbData = [];
      }
    } catch (e) {
      debugPrint("Error loading verbs: $e");
      _cachedVerbData = [];
    }
  }

  // --- Date-Specific & Progress Logic ---

  @Deprecated(
    'Legacy calendar-based day assignment removed. Use stage-based methods.',
  )
  Future<List<Map<String, String>>> getItemsForDate(
    String type,
    DateTime date,
  ) async {
    debugPrint(
      'DataService: getItemsForDate() is deprecated (calendar-based). Returning empty list.',
    );
    return [];
  }

  @Deprecated(
    'Legacy calendar-based day assignment removed. Use stage-based methods.',
  )
  Future<List<Map<String, String>>> getVocabularyForDate(
    DateTime date, {
    bool createIfMissing = true,
  }) async {
    debugPrint(
      'DataService: getVocabularyForDate() is deprecated (calendar-based). Returning empty list.',
    );
    return [];
  }

  @Deprecated(
    'Legacy calendar-based day assignment removed. Use stage-based methods.',
  )
  Future<List<Map<String, String>>> getVerbsForDate(DateTime date) async {
    debugPrint(
      'DataService: getVerbsForDate() is deprecated (calendar-based). Returning empty list.',
    );
    return [];
  }

  // Wrappers for existing calls to maintain backward compatibility
  // Level-based replacements for legacy calendar logic.
  Future<List<Map<String, String>>> getDailyVocabulary() async {
    debugPrint('');
    debugPrint(
      'DataService: getDailyVocabulary() now uses stage-based content.',
    );
    debugPrint('');

    final stage = await StageProgressService().getCurrentStage();
    final preferredLanguage = await getUserLanguage();
    return StageContentService().getVocabularyMapsForStage(
      stage,
      preferredLanguage: preferredLanguage,
    );
  }

  Future<List<Map<String, String>>> getYesterdayVocabulary() async {
    debugPrint('');
    debugPrint(
      'DataService: getYesterdayVocabulary() now uses previous stage content.',
    );
    debugPrint('');

    final stageService = StageProgressService();
    final stage = await stageService.getCurrentStage();
    final previousStage = stageService.previousStage(stage);
    if (previousStage <= 0) return [];
    final preferredLanguage = await getUserLanguage();
    return StageContentService().getVocabularyMapsForStage(
      previousStage,
      preferredLanguage: preferredLanguage,
    );
  }

  Future<List<Map<String, String>>> getDailyVerbs() async {
    debugPrint('');
    debugPrint('DataService: getDailyVerbs() now uses stage-based content.');
    debugPrint('');

    final stage = await StageProgressService().getCurrentStage();
    final preferredLanguage = await getUserLanguage();
    return StageContentService().getVerbMapsForStage(
      stage,
      preferredLanguage: preferredLanguage,
    );
  }

  Future<List<Map<String, String>>> getYesterdayVerbs() async {
    debugPrint('');
    debugPrint(
      'DataService: getYesterdayVerbs() now uses previous stage content.',
    );
    debugPrint('');

    final stageService = StageProgressService();
    final stage = await stageService.getCurrentStage();
    final previousStage = stageService.previousStage(stage);
    if (previousStage <= 0) return [];
    final preferredLanguage = await getUserLanguage();
    return StageContentService().getVerbMapsForStage(
      previousStage,
      preferredLanguage: preferredLanguage,
    );
  }

  // --- Progress & Missed Lessons ---

  Future<void> saveQuizResultForStage(int stage, int score, int total) async {
    return await DataServiceCloudSync(
      this,
    ).saveQuizResultForStage(stage, score, total);
  }

  String _legacyDateKey(DateTime date) => date.toIso8601String().split('T')[0];

  // Legacy calendar-based compatibility wrappers for older screens.
  Future<bool> hasPassedQuiz(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'quiz_passed_${_legacyDateKey(date)}';
    return prefs.getBool(key) ?? false;
  }

  Future<void> saveQuizResult(DateTime date, int score, int total) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _legacyDateKey(date);
    final passed = total > 0 && (score * 100) >= (total * 70);

    await prefs.setInt('quiz_score_$dateKey', score);
    await prefs.setInt('quiz_total_$dateKey', total);
    await prefs.setBool('quiz_passed_$dateKey', passed);

    await saveProgressToCloud('quiz_score_$dateKey', score);
    await saveProgressToCloud('quiz_total_$dateKey', total);
    await saveProgressToCloud('quiz_passed_$dateKey', passed);
  }

  Future<void> addToBlackHole(
    List<Map<String, String>> wrongAnswers,
    DateTime date,
  ) async {
    final stage = await StageProgressService().getCurrentStage();
    await addToBlackHoleForStage(wrongAnswers, stage);

    final prefs = await SharedPreferences.getInstance();
    final key = 'blackhole_${_legacyDateKey(date)}';
    final existing = prefs.getStringList(key) ?? <String>[];
    final merged = <String>{...existing};
    for (final item in wrongAnswers) {
      final word = item['word']?.trim();
      if (word != null && word.isNotEmpty) {
        merged.add(word);
      }
    }
    await prefs.setStringList(key, merged.toList());
  }

  Future<List<DateTime>> getMissedDates() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final missed = <DateTime>{};

    for (final key in prefs.getKeys()) {
      if (!key.startsWith('quiz_passed_')) continue;
      final passed = prefs.getBool(key) ?? false;
      if (passed) continue;

      final raw = key.substring('quiz_passed_'.length);
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) continue;

      final normalized = DateTime(parsed.year, parsed.month, parsed.day);
      if (normalized.isBefore(today)) {
        missed.add(normalized);
      }
    }

    final list = missed.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  /// Saves a specific progress key to Firestore for the current user.
  Future<void> saveProgressToCloud(String key, dynamic value) async {
    return await DataServiceCloudSync(this).saveProgressToCloud(key, value);
  }

  // --- Seeding Data for Placement ---
  Future<void> seedVocabularyForLevel(String level) async {
    return await DataServiceCloudSync(this).seedVocabularyForLevel(level);
  }

  Future<void> saveMasteryProgress(String category, String id) async {
    return await DataServiceCloudSync(this).saveMasteryProgress(category, id);
  }

  Future<Map<String, double>> getDetailedProgress({String? uid}) async {
    return await DataServiceCloudSync(this).getDetailedProgress(uid: uid);
  }

  Future<double> getOverallProgress({String? uid}) async {
    return await DataServiceCloudSync(this).getOverallProgress(uid: uid);
  }

  Future<int> getStreakCount() async {
    final prefs = await SharedPreferences.getInstance();
    return DataServiceStreak.getStreakCount(
      prefs: prefs,
      userId: 'guest',
      now: DateTime.now(),
    );
  }

  /// Fetches all progress data from Firestore and updates local SharedPreferences.
  Future<void> syncProgressFromCloud() async {
    return await DataServiceCloudSync(this).syncProgressFromCloud();
  }

  Future<bool> hasPassedQuizForStage(int stage) async {
    final prefs = await SharedPreferences.getInstance();
    final stageService = StageProgressService();
    return prefs.getBool(stageService.quizPassedKey(stage)) ?? false;
  }

  Future<bool> hasAttemptedQuizForStage(int stage) async {
    final prefs = await SharedPreferences.getInstance();
    final stageService = StageProgressService();
    return prefs.containsKey(stageService.quizScoreKey(stage));
  }

  Future<List<int>> getMissedStages() async {
    final prefs = await SharedPreferences.getInstance();
    final stageService = StageProgressService();
    final currentStage = await stageService.getCurrentStage(prefs: prefs);

    final missed = <int>[];
    for (int stage = 1; stage < currentStage; stage++) {
      final assessmentCompleted =
          prefs.getBool(stageService.assessmentCompletedKey(stage)) ?? false;
      bool quizPassed =
          prefs.getBool(stageService.quizPassedKey(stage)) ?? false;

      if (!quizPassed) {
        final score = prefs.getInt(stageService.quizScoreKey(stage));
        final total = prefs.getInt(stageService.quizTotalKey(stage));
        if (score != null && total != null && total > 0) {
          quizPassed = stageService.isAssessmentPassed(score, total);
        }
      }

      // Assessment completion (perfect score) clears recovery for this stage.
      if (!assessmentCompleted && !quizPassed) {
        missed.add(stage);
      }
    }

    return missed;
  }

  Future<void> resetMissedLessons() async {
    debugPrint("Reset missed lessons is disabled to preserve progression.");
  }

  Future<void> _notifyTeacherOfSuccess(
    String dateStr,
    int score,
    int total,
  ) async {
    return await DataServiceAdmin(
      this,
    )._notifyTeacherOfSuccess(dateStr, score, total);
  }

  /// Add wrong answers to black hole for review
  Future<void> addToBlackHoleForStage(
    List<Map<String, String>> wrongAnswers,
    int stage,
  ) async {
    return await DataServiceCloudSync(
      this,
    ).addToBlackHoleForStage(wrongAnswers, stage);
  }

  /// ???? RECOVERY: Fixes missing words from previous bug
  /// Scans completed daily tasks and ensures word count matches
  Future<int> recoverLostProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Count days where vocab task was completed
    int completedDays = 0;
    final allKeys = prefs.getKeys();
    for (String key in allKeys) {
      if (key.startsWith('task_vocab_stage_') && !key.endsWith('_score')) {
        if (prefs.getBool(key) == true) {
          completedDays++;
        }
      }
    }

    // 2. Minimum words user SHOULD have
    final int minExpectedWords = completedDays * 5;

    // 3. Check actual words
    List<String> currentIds = prefs.getStringList('learned_vocab_ids') ?? [];

    if (currentIds.length < minExpectedWords) {
      debugPrint(
        '???? RECOVERY: Found $completedDays completed days but only ${currentIds.length} words.',
      );
      debugPrint(
        '   Backfilling ${minExpectedWords - currentIds.length} words...',
      );

      // 4. Load ALL words to backfill
      List<Map<String, String>> allVocab = [];
      try {
        // Try to verify we have data loaded
        if (_cachedVocabData == null || _cachedVocabData!.isEmpty) {
          await _loadVocabData();
        }
        allVocab = await getAllItems('vocabulary');
      } catch (e) {
        debugPrint('Error loading vocab for recovery: $e');
        return 0; // Abort if cant load data
      }

      if (allVocab.isEmpty) return 0;

      // 5. Add words until we reach expected count
      int added = 0;
      for (var item in allVocab) {
        if (currentIds.length >= minExpectedWords) break;

        final id = item['id'] ?? item['word'];
        if (id != null && !currentIds.contains(id)) {
          currentIds.add(id);
          added++;
        }
      }

      // 6. Save!
      if (added > 0) {
        await prefs.setStringList('learned_vocab_ids', currentIds);
        debugPrint('??? RECOVERY SUCCESS: Restored $added missing words!');
        return added;
      }
    }

    return 0;
  }

  // --- Admin / Teacher Features ---

  Future<bool> adminSyncFromUrlToCloud(String url) async {
    return await DataServiceAdmin(this).adminSyncFromUrlToCloud(url);
  }

  // --- Black Hole (Difficult Words Bank) ---

  static const String _blackHoleKey = 'black_hole_items';

  Future<bool> toggleBlackHoleItem(Map<String, String> item) async {
    return await DataServiceCloudSync(this).toggleBlackHoleItem(item);
  }

  Future<List<Map<String, String>>> getBlackHoleItems() async {
    return await DataServiceCloudSync(this).getBlackHoleItems();
  }

  Future<bool> isInBlackHole(String id) async {
    return await DataServiceCloudSync(this).isInBlackHole(id);
  }

  // --- Mastery Progress ---

  Future<List<String>> getCompletedExerciseIds(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'mastery_${type}_completed';
    return prefs.getStringList(key) ?? [];
  }

  Future<double> getMasteryProgress(String type) async {
    // 1. Get Completed Count
    final prefs = await SharedPreferences.getInstance();
    final key = 'mastery_${type}_completed';
    final List<String> completed = prefs.getStringList(key) ?? [];
    int completedCount = completed.length;

    // 2. Get Total Count
    int totalCount = 0;
    switch (type) {
      case 'reading':
        await _loadReadingData();
        totalCount = _cachedReadingData?.length ?? 0;
        break;
      case 'writing':
        await _loadWritingData();
        totalCount = _cachedWritingData?.length ?? 0;
        break;
      case 'speaking':
        await _loadSpeakingData();
        totalCount = _cachedSpeakingData?.length ?? 0;
        break;
      case 'listening':
        await _loadListeningData();
        totalCount = _cachedListeningData?.length ?? 0;
        break;
      case 'quiz': // Focused Quiz
        await _loadQuizData();
        // Approx check: Unique questions? Or just row count.
        totalCount = _cachedQuizData?.length ?? 0;
        break;
      default:
        totalCount = 0;
    }

    if (totalCount == 0) return 0.0;

    // Debug
    // debugPrint("Mastery $type: $completedCount / $totalCount");

    return (completedCount / totalCount).clamp(0.0, 1.0);
  }

  void _clearCacheFor(String category) {
    switch (category) {
      case 'writing':
        _cachedWritingData = [];
        _cachedWritingLevel = null;
        break;
      case 'listening':
        _cachedListeningData = [];
        _cachedListeningLevel = null;
        break;
      case 'vocabulary':
        _cachedVocabData = [];
        break;
      case 'verbs':
        _cachedVerbData = [];
        break;
      case 'reading':
        _cachedReadingData = [];
        _cachedReadingLevel = null;
        break;
      case 'speaking':
        _cachedSpeakingData = [];
        _cachedSpeakingLevel = null;
        break;
      case 'quiz':
        _cachedQuizData = [];
        break;
    }
  }

  // --- Activity Logging ---
  static const String _activityKey = 'recent_activity_log';

  Future<void> logActivity({
    required String title,
    required String subtitle,
    required String iconName, // 'quiz', 'book', 'mic', 'pen'
    required String colorName, // 'red', 'blue', 'green', 'orange', 'purple'
  }) async {
    return await DataServiceCloudSync(this).logActivity(
      title: title,
      subtitle: subtitle,
      iconName: iconName,
      colorName: colorName,
    );
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    return await DataServiceCloudSync(this).getRecentActivity();
  }

  // --- High Scores ---
  Future<int> getHighScore(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('highscore_$gameId') ?? 0;
  }

  Future<void> saveHighScore(String gameId, int score) async {
    return await DataServiceCloudSync(this).saveHighScore(gameId, score);
  }

  // --- Gamification Persistence ---

  Future<Map<String, int>> getUserLevelData() async {
    final prefs = await SharedPreferences.getInstance();
    int level =
        prefs.getInt('user_xp_level') ?? prefs.getInt('user_level') ?? 1;
    if (prefs.getInt('user_xp_level') == null &&
        prefs.getInt('user_level') != null) {
      await prefs.setInt('user_xp_level', level);
    }
    int currentXp = prefs.getInt('user_current_xp') ?? 0;
    int requiredXp = XpRewardPolicy.requiredXpForLevel(level);
    return {'level': level, 'currentXp': currentXp, 'requiredXp': requiredXp};
  }

  Future<bool> addXp(int amount) async {
    return await DataServiceCloudSync(this).addXp(amount);
  }

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return DataServiceStreak.getStreak(prefs: prefs, userId: 'guest');
  }

  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await DataServiceStreak.updateStreak(
      prefs: prefs,
      userId: 'guest',
      now: DateTime.now(),
    );
  }

  Future<List<String>> getUnlockedBadges() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('user_badges') ?? [];
  }

  Future<bool> unlockBadge(String badgeId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> badges = prefs.getStringList('user_badges') ?? [];
    if (!badges.contains(badgeId)) {
      badges.add(badgeId);
      await prefs.setStringList('user_badges', badges);
      return true; // New unlock
    }
    return false;
  }

  // --- DVS & DVeS Implementation ---

  Future<void> markItemAsLearned(String type, String id) async {
    return await DataServiceCloudSync(this).markItemAsLearned(type, id);
  }

  // Get User Role
  Future<String?> getUserRole() async {
    return await DataServiceAdmin(this).getUserRole();
  }

  // Get User Status (Role + Blocked + Level + StartDate)
  Future<Map<String, dynamic>> getUserStatus() async {
    return await DataServiceAdmin(this).getUserStatus();
  }

  Future<void> resetStudentProgress(String uid) async {
    return await DataServiceAdmin(this).resetStudentProgress(uid);
  }

  Future<void> setUserLevel(
    String level, {
    bool fromPlacementQuiz = false,
  }) async {
    return await DataServiceAdmin(
      this,
    ).setUserLevel(level, fromPlacementQuiz: fromPlacementQuiz);
  }

  // --- Assessment Status Management ---
  Future<String?> getAssessmentStatus() async {
    return await DataServiceAdmin(this).getAssessmentStatus();
  }

  Future<void> setAssessmentStatus(String status) async {
    return await DataServiceAdmin(this).setAssessmentStatus(status);
  }

  Future<void> savePlacementResult(String levelCode, int score) async {
    return await DataServiceAdmin(this).savePlacementResult(levelCode, score);
  }
}
