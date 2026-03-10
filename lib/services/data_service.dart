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
import 'package:gravity_app/data/repositories/black_hole_repository.dart';
import 'package:gravity_app/data/repositories/activity_repository.dart';
import 'package:gravity_app/data/repositories/mastery_progress_repository.dart';
import 'package:gravity_app/data/repositories/quiz_progress_repository.dart';
import 'package:gravity_app/data/repositories/user_progress_repository.dart';
import 'package:gravity_app/models/verb_item.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/features/daily_sentences/daily_sentence_service.dart';
import 'package:gravity_app/services/day_based_curriculum_service.dart';
import 'package:gravity_app/services/data_service_curriculum.dart';
import 'package:gravity_app/services/data_service_content_loaders.dart';
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
  Future<void>? _vocabLoadFuture;
  Future<void>? _verbLoadFuture;
  Future<void>? _readingLoadFuture;
  Future<void>? _writingLoadFuture;
  Future<void>? _speakingLoadFuture;
  Future<void>? _listeningLoadFuture;
  Future<void>? _quizLoadFuture;
  Future<void>? _progressSyncFuture;
  DateTime? _lastProgressSyncAt;

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
    _vocabLoadFuture = null;
    _verbLoadFuture = null;
    _readingLoadFuture = null;
    _writingLoadFuture = null;
    _speakingLoadFuture = null;
    _listeningLoadFuture = null;
    _quizLoadFuture = null;
    _progressSyncFuture = null;
    _lastProgressSyncAt = null;
    debugPrint("[CLEAN] DataService: Memory cache cleared.");
  }

  Future<void> wipeAllLibraryData() async {
    return await DataServiceCloudSync(this).wipeAllLibraryData();
  }

  final CsvRepository _csvRepository = CsvRepository();
  final BlackHoleRepository _blackHoleRepository = BlackHoleRepository();
  final ActivityRepository _activityRepository = ActivityRepository();
  final UserProgressRepository _userProgressRepository =
      UserProgressRepository();
  final QuizProgressRepository _quizProgressRepository =
      QuizProgressRepository();
  final MasteryProgressRepository _masteryProgressRepository =
      MasteryProgressRepository();
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
    if (_cachedVocabData != null && _cachedVocabData!.isNotEmpty) {
      return;
    }
    if (_vocabLoadFuture != null) {
      await _vocabLoadFuture;
      return;
    }

    final future = _loadVocabDataInternal();
    _vocabLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_vocabLoadFuture, future)) {
        _vocabLoadFuture = null;
      }
    }
  }

  Future<void> _loadVocabDataInternal() async {
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
        debugPrint(
          "DataService: Indexed vocabulary data (${_cachedVocabData!.length} rows).",
        );
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
    if (_cachedVerbData != null && _cachedVerbData!.isNotEmpty) {
      return;
    }
    if (_verbLoadFuture != null) {
      await _verbLoadFuture;
      return;
    }

    final future = _loadVerbDataInternal();
    _verbLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_verbLoadFuture, future)) {
        _verbLoadFuture = null;
      }
    }
  }

  Future<void> _loadVerbDataInternal() async {
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
        debugPrint(
          "DataService: Indexed verb data (${_cachedVerbData!.length} rows).",
        );
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
    final stage = await StageProgressService().getCurrentStage();
    final preferredLanguage = await getUserLanguage();
    return StageContentService().getVocabularyMapsForStage(
      stage,
      preferredLanguage: preferredLanguage,
    );
  }

  Future<List<Map<String, String>>> getYesterdayVocabulary() async {
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
    final stage = await StageProgressService().getCurrentStage();
    final preferredLanguage = await getUserLanguage();
    return StageContentService().getVerbMapsForStage(
      stage,
      preferredLanguage: preferredLanguage,
    );
  }

  Future<List<Map<String, String>>> getYesterdayVerbs() async {
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
    return _quizProgressRepository.hasPassedQuiz(date);
  }

  Future<void> saveQuizResult(DateTime date, int score, int total) async {
    final result = await _quizProgressRepository.saveQuizResult(
      date,
      score,
      total,
    );

    await saveProgressToCloud('quiz_score_${result.dateKey}', score);
    await saveProgressToCloud('quiz_total_${result.dateKey}', total);
    await saveProgressToCloud('quiz_passed_${result.dateKey}', result.passed);
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
    return _quizProgressRepository.getMissedDates();
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
    return _userProgressRepository.getStreakCount(
      userId: 'guest',
      now: DateTime.now(),
    );
  }

  /// Fetches all progress data from Firestore and updates local SharedPreferences.
  Future<void> syncProgressFromCloud({bool force = false}) async {
    return await DataServiceCloudSync(this).syncProgressFromCloud(force: force);
  }

  Future<bool> hasPassedQuizForStage(int stage) async {
    return _quizProgressRepository.hasPassedQuizForStage(stage);
  }

  Future<bool> hasAttemptedQuizForStage(int stage) async {
    return _quizProgressRepository.hasAttemptedQuizForStage(stage);
  }

  Future<List<int>> getMissedStages() async {
    return _quizProgressRepository.getMissedStages();
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

  static const String _blackHoleKey = BlackHoleRepository.blackHoleKey;

  Future<bool> toggleBlackHoleItem(Map<String, String> item) async {
    return _blackHoleRepository.toggleItem(
      item,
      onMissingLocal: () async {
        await DataServiceCloudSync(this).syncProgressFromCloud(force: true);
      },
      onSaveEncoded: (encodedItems) async {
        await saveProgressToCloud(_blackHoleKey, encodedItems);
      },
    );
  }

  Future<List<Map<String, String>>> getBlackHoleItems() async {
    return _blackHoleRepository.getItems(
      onMissingLocal: () async {
        await DataServiceCloudSync(this).syncProgressFromCloud(force: true);
      },
    );
  }

  Future<bool> isInBlackHole(String id) async {
    return _blackHoleRepository.isInBlackHole(
      id,
      onMissingLocal: () async {
        await DataServiceCloudSync(this).syncProgressFromCloud(force: true);
      },
    );
  }

  // --- Mastery Progress ---

  Future<List<String>> getCompletedExerciseIds(String type) async {
    return _masteryProgressRepository.getCompletedExerciseIds(type);
  }

  Future<double> getMasteryProgress(String type) async {
    // 1. Get Completed Count
    final List<String> completed =
        await _masteryProgressRepository.getCompletedExerciseIds(type);
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
  static const String _activityKey = ActivityRepository.activityKey;

  Future<void> logActivity({
    required String title,
    required String subtitle,
    required String iconName, // 'quiz', 'book', 'mic', 'pen'
    required String colorName, // 'red', 'blue', 'green', 'orange', 'purple'
  }) async {
    final logs = await _activityRepository.logActivity(
      title: title,
      subtitle: subtitle,
      iconName: iconName,
      colorName: colorName,
    );
    saveProgressToCloud(_activityKey, logs);
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    return await _activityRepository.getRecentActivity();
  }

  // --- High Scores ---
  Future<int> getHighScore(String gameId) async {
    return _masteryProgressRepository.getHighScore(gameId);
  }

  Future<void> saveHighScore(String gameId, int score) async {
    final shouldUpdate = await _masteryProgressRepository.isNewHighScore(
      gameId,
      score,
    );
    if (!shouldUpdate) return;
    await DataServiceCloudSync(this).saveHighScore(gameId, score);
  }

  // --- Gamification Persistence ---

  Future<Map<String, int>> getUserLevelData() async {
    return _userProgressRepository.getUserLevelData();
  }

  Future<bool> addXp(int amount) async {
    return await DataServiceCloudSync(this).addXp(amount);
  }

  Future<int> getStreak() async {
    return _userProgressRepository.getStreak(userId: 'guest');
  }

  Future<void> updateStreak() async {
    await _userProgressRepository.updateStreak(
      userId: 'guest',
      now: DateTime.now(),
    );
  }

  Future<List<String>> getUnlockedBadges() async {
    return _userProgressRepository.getUnlockedBadges();
  }

  Future<bool> unlockBadge(String badgeId) async {
    return _userProgressRepository.unlockBadge(badgeId);
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
