import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:gravity_app/models/vocabulary_item.dart';

import 'package:gravity_app/models/verb_item.dart';

import 'package:gravity_app/services/day_based_curriculum_service.dart';



/// AUTHORITATIVE curriculum progress service.

/// Single source of truth for currentLearningDay and all daily assignments.

@Deprecated('Legacy calendar-based curriculum progress. Unused in stage system.')

class CurriculumProgressService {

  // Singleton pattern

  static final CurriculumProgressService _instance =

      CurriculumProgressService._internal();



  factory CurriculumProgressService() => _instance;

  CurriculumProgressService._internal();



  final DayBasedCurriculumService _curriculumService =

      DayBasedCurriculumService();



  bool _isInitialized = false;

  int _currentLearningDay = 1; // Single source of truth



  // Keys for persistence

  static const String _currentDayKey = 'current_learning_day';

  static const String _completedDaysKey = 'completed_days';



  /// Initialize the curriculum system

  /// MUST be called before any other methods

  Future<bool> initialize() async {

    if (_isInitialized) {

      debugPrint('OK: Curriculum already initialized (day $_currentLearningDay)');

      return true;

    }



    debugPrint('[LAUNCH] Initializing curriculum progress system...');



    try {

      // Load and validate CSVs

      bool vocabLoaded = await _curriculumService.loadVocabularyCsv();

      if (!vocabLoaded) {

        debugPrint('Error: CRITICAL: Vocabulary CSV validation failed');

        return false;

      }



      bool verbsLoaded = await _curriculumService.loadVerbsCsv();

      if (!verbsLoaded) {

        debugPrint('Error: CRITICAL: Verbs CSV validation failed');

        return false;

      }



      // Hydrate currentLearningDay from cloud FIRST

      await _hydrateCurrentDayFromCloud();



      _isInitialized = true;

      debugPrint(

        'OK: Curriculum initialized successfully (current day: $_currentLearningDay)',

      );



      return true;

    } catch (e, stackTrace) {

      debugPrint('Error: Failed to initialize curriculum: $e');

      debugPrint('Stack trace: $stackTrace');

      return false;

    }

  }



  /// Get today's vocabulary (based on currentLearningDay)

  /// DO NOT call this before initialize()

  Future<List<VocabularyItem>> getTodayVocabulary() async {

    _assertInitialized();

    return getItemsForDay(_currentLearningDay);

  }



  /// Get today's verbs (based on currentLearningDay)

  /// DO NOT call this before initialize()

  Future<List<VerbItem>> getTodayVerbs() async {

    _assertInitialized();

    return getVerbsForDay(_currentLearningDay);

  }



  /// Force reload all curriculum data from CSVs

  Future<void> forceReloadData() async {

    debugPrint('[REFRESH] Force reloading all curriculum data...');



    // First, try to download the latest from cloud

    await _curriculumService.fetchLatestVocabularyFromCloud();

    await _curriculumService.fetchLatestVerbsFromCloud();



    // Then reset memory and re-initialize

    _curriculumService.reset();

    _isInitialized = false;

    await initialize();

  }



  /// Get vocabulary items for a specific day

  Future<List<VocabularyItem>> getItemsForDay(int day) async {

    _assertInitialized();

    _validateDayNumber(day);



    // Get items from curriculum

    List<VocabularyItem> dayItems = _curriculumService.getDailyVocabularyFor(

      day,

    );



    // If dayItems is empty, try to reload once just in case

    if (dayItems.isEmpty) {

      debugPrint('[WARN] No items found for day $day, attempting reload...');

      await _curriculumService.loadVocabularyCsv();

      dayItems = _curriculumService.getDailyVocabularyFor(day);

    }



    // Check if we have saved IDs for this day (for consistency)

    List<String> savedIds = await _getSavedVocabIds(day);



    if (savedIds.isNotEmpty) {

      // Filter to only saved IDs (preserves exact assignment)

      List<VocabularyItem> matchedItems = dayItems

          .where((item) => savedIds.contains(item.id))

          .toList();



      if (matchedItems.length != savedIds.length) {

        debugPrint(

          '  CSV mismatch for day $day: Expected ${savedIds.length} vocab, found ${matchedItems.length}',

        );

      }



      return matchedItems;

    }



    // First time accessing this day - save IDs

    List<String> ids = dayItems.map((item) => item.id).toList();

    if (ids.isNotEmpty) {

      await _saveVocabIds(day, ids);

    }



    return dayItems;

  }



  /// Get verbs for a specific day

  Future<List<VerbItem>> getVerbsForDay(int day) async {

    _assertInitialized();

    _validateDayNumber(day);



    // Get items from curriculum

    List<VerbItem> dayItems = _curriculumService.getDailyVerbsFor(day);



    // If dayItems is empty, try to reload once just in case

    if (dayItems.isEmpty) {

      debugPrint('[WARN] No verbs found for day $day, attempting reload...');

      await _curriculumService.loadVerbsCsv();

      dayItems = _curriculumService.getDailyVerbsFor(day);

    }



    // Check if we have saved IDs for this day

    List<String> savedIds = await _getSavedVerbIds(day);



    if (savedIds.isNotEmpty) {

      // Filter to only saved IDs

      List<VerbItem> matchedItems = dayItems

          .where((item) => savedIds.contains(item.id))

          .toList();



      if (matchedItems.length != savedIds.length) {

        debugPrint(

          '  CSV mismatch for day $day: Expected ${savedIds.length} verbs, found ${matchedItems.length}',

        );

      }



      return matchedItems;

    }



    // First time accessing this day - save IDs

    List<String> ids = dayItems.map((item) => item.id).toList();

    if (ids.isNotEmpty) {

      await _saveVerbIds(day, ids);

    }



    return dayItems;

  }



  /// Mark a day as completed

  /// This is the ONLY way to increment currentLearningDay

  /// Call this when ALL daily tasks for a day are completed

  Future<void> markDayCompleted(int day) async {

    _assertInitialized();

    _validateDayNumber(day);



    if (day != _currentLearningDay) {

      debugPrint(

        '  Attempting to complete day $day but current day is $_currentLearningDay',

      );

      // Allow marking any day as complete, but only increment if it's current

    }



    // Mark day as completed

    final prefs = await SharedPreferences.getInstance();

    Set<int> completedDays = _getCompletedDays(prefs);

    completedDays.add(day);

    await prefs.setString(_completedDaysKey, completedDays.join(','));



    // Sync to cloud

    await _syncToCloud(_completedDaysKey, completedDays.join(','));



    // If this was the current day, increment to next day

    if (day == _currentLearningDay && _currentLearningDay < 90) {

      _currentLearningDay++;

      await prefs.setInt(_currentDayKey, _currentLearningDay);

      await _syncToCloud(_currentDayKey, _currentLearningDay);



      debugPrint('OK: Day $day completed. Advanced to day $_currentLearningDay');

    } else {

      debugPrint(

        'OK: Day $day marked complete (current day: $_currentLearningDay)',

      );

    }

  }



  /// Get all learned vocabulary items up to and including a specific day

  /// Used for games and reinforcement quizzes

  Future<List<VocabularyItem>> getLearnedVocabularyUpToDay(int day) async {

    _assertInitialized();

    _validateDayNumber(day);



    List<VocabularyItem> allLearned = [];



    for (int d = 1; d <= day; d++) {

      List<VocabularyItem> dayItems = await getItemsForDay(d);

      allLearned.addAll(dayItems);

    }



    return allLearned;

  }



  /// Get all learned verbs up to and including a specific day

  /// Used for games and reinforcement quizzes

  Future<List<VerbItem>> getLearnedVerbsUpToDay(int day) async {

    _assertInitialized();

    _validateDayNumber(day);



    List<VerbItem> allLearned = [];



    for (int d = 1; d <= day; d++) {

      List<VerbItem> dayItems = await getVerbsForDay(d);

      allLearned.addAll(dayItems);

    }



    return allLearned;

  }



  /// Get yesterday's vocabulary (for Yesterday Quiz)

  /// Returns empty list if current day is 1

  Future<List<VocabularyItem>> getYesterdayVocabulary() async {

    _assertInitialized();



    if (_currentLearningDay <= 1) {

      debugPrint(

        '  No yesterday vocabulary (current day is $_currentLearningDay)',

      );

      return [];

    }



    return getItemsForDay(_currentLearningDay - 1);

  }



  /// Get yesterday's verbs (for Yesterday Quiz)

  /// Returns empty list if current day is 1

  Future<List<VerbItem>> getYesterdayVerbs() async {

    _assertInitialized();



    if (_currentLearningDay <= 1) {

      debugPrint(

        '  No yesterday verbs (current day is $_currentLearningDay)',

      );

      return [];

    }



    return getVerbsForDay(_currentLearningDay - 1);

  }



  /// Check if a specific day has been completed

  Future<bool> isDayCompleted(int day) async {

    _validateDayNumber(day);

    final prefs = await SharedPreferences.getInstance();

    Set<int> completedDays = _getCompletedDays(prefs);

    return completedDays.contains(day);

  }



  /// Get current learning day (single source of truth)

  int getCurrentLearningDay() {

    _assertInitialized();

    return _currentLearningDay;

  }



  /// Check if user has completed 90-day curriculum (reinforcement mode eligible)

  bool isReinforcementModeEligible() {

    _assertInitialized();

    return _currentLearningDay > 90;

  }



  /// Get items available for games (everything learned up to yesterday)

  /// TODAY'S items never appear in games

  Future<List<VocabularyItem>> getGameVocabulary() async {

    _assertInitialized();



    if (_currentLearningDay <= 1) {

      debugPrint('  No game vocabulary (current day is 1)');

      return [];

    }



    // Games can only use items up to YESTERDAY

    int maxDay = _currentLearningDay - 1;

    debugPrint(

      ' Game vocabulary: days 1-$maxDay (today=$_currentLearningDay excluded)',

    );



    return getLearnedVocabularyUpToDay(maxDay);

  }



  /// Get verbs available for games

  Future<List<VerbItem>> getGameVerbs() async {

    _assertInitialized();



    if (_currentLearningDay <= 1) {

      debugPrint('  No game verbs (current day is 1)');

      return [];

    }



    int maxDay = _currentLearningDay - 1;

    debugPrint(

      ' Game verbs: days 1-$maxDay (today=$_currentLearningDay excluded)',

    );



    return getLearnedVerbsUpToDay(maxDay);

  }



  /// Reset progress (for testing or user choice)

  Future<void> resetProgress() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_currentDayKey);

    await prefs.remove(_completedDaysKey);

    await prefs.remove(

      'progress_start_date',

    ); // Reset join date too for fresh start



    _currentLearningDay = 1;

    _isInitialized = false;



    debugPrint('[REFRESH] Progress reset to day 1');

  }



  /// Manually set current day (admin/testing only)

  Future<void> setCurrentDay(int day) async {

    _validateDayNumber(day);



    _currentLearningDay = day;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_currentDayKey, day);

    await _syncToCloud(_currentDayKey, day);



    debugPrint(' Manually set current day to $day');

  }



  // ==================== PRIVATE METHODS ====================



  /// Hydrate currentLearningDay from cloud first, then local

  Future<void> _hydrateCurrentDayFromCloud() async {

    final prefs = await SharedPreferences.getInstance();



    // 1. Priority: Calculate day from Join Date (as requested by user)

    String? joinDateStr = prefs.getString('progress_start_date');

    if (joinDateStr != null) {

      int joinDay = _calculateDayFromJoinDate(joinDateStr);

      _currentLearningDay = joinDay.clamp(1, 90);

      debugPrint(

        ' Calculated current day from join date: $_currentLearningDay',

      );

      await prefs.setInt(_currentDayKey, _currentLearningDay);

      return;

    }



    // 2. Fallback: Cloud

    try {

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {

        DocumentSnapshot doc = await FirebaseFirestore.instance

            .collection('users')

            .doc(user.uid)

            .collection('progress')

            .doc('curriculum')

            .get();



        if (doc.exists) {

          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

          if (data != null && data.containsKey(_currentDayKey)) {

            _currentLearningDay = data[_currentDayKey] as int;

            debugPrint(

              '  Hydrated current day from cloud: $_currentLearningDay',

            );



            // Save to local

            await prefs.setInt(_currentDayKey, _currentLearningDay);

            return;

          }

        }

      }

    } catch (e) {

      debugPrint('[WARN]  Failed to hydrate from cloud: $e');

    }



    // 3. Last resort: Local

    _currentLearningDay = prefs.getInt(_currentDayKey) ?? 1;

    debugPrint('[SAVE] Loaded current day from local: $_currentLearningDay');

  }



  int _calculateDayFromJoinDate(String startDateStr) {

    try {

      final startDate = DateTime.parse(startDateStr);

      final now = DateTime.now();

      // Use clean date comparison (ignoring time)

      final start = DateTime(startDate.year, startDate.month, startDate.day);

      final today = DateTime(now.year, now.month, now.day);

      return today.difference(start).inDays + 1;

    } catch (e) {

      debugPrint('[WARN] Error parsing join date: $e');

      return 1;

    }

  }



  /// Sync a value to Firestore

  Future<void> _syncToCloud(String key, dynamic value) async {

    try {

      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) return;



      await FirebaseFirestore.instance

          .collection('users')

          .doc(user.uid)

          .collection('progress')

          .doc('curriculum')

          .set({key: value}, SetOptions(merge: true));



      debugPrint('  Synced $key to cloud');

    } catch (e) {

      debugPrint('[WARN]  Failed to sync $key: $e');

    }

  }



  /// Get saved vocabulary IDs for a day

  Future<List<String>> _getSavedVocabIds(int day) async {

    final prefs = await SharedPreferences.getInstance();

    String key = 'vocab_ids_day_$day';

    String? idsStr = prefs.getString(key);

    if (idsStr == null || idsStr.isEmpty) return [];

    return idsStr.split(',').where((id) => id.isNotEmpty).toList();

  }



  /// Save vocabulary IDs for a day

  Future<void> _saveVocabIds(int day, List<String> ids) async {

    String key = 'vocab_ids_day_$day';

    String value = ids.join(',');



    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(key, value);

    await _syncToCloud(key, value);

  }



  /// Get saved verb IDs for a day

  Future<List<String>> _getSavedVerbIds(int day) async {

    final prefs = await SharedPreferences.getInstance();

    String key = 'verb_ids_day_$day';

    String? idsStr = prefs.getString(key);

    if (idsStr == null || idsStr.isEmpty) return [];

    return idsStr.split(',').where((id) => id.isNotEmpty).toList();

  }



  /// Save verb IDs for a day

  Future<void> _saveVerbIds(int day, List<String> ids) async {

    String key = 'verb_ids_day_$day';

    String value = ids.join(',');



    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(key, value);

    await _syncToCloud(key, value);

  }



  /// Get completed days set

  Set<int> _getCompletedDays(SharedPreferences prefs) {

    String? completedStr = prefs.getString(_completedDaysKey);

    if (completedStr == null || completedStr.isEmpty) return {};

    return completedStr.split(',').map((s) => int.parse(s)).toSet();

  }



  /// Validate day number is in range [1-90]

  void _validateDayNumber(int day) {

    if (day < 1 || day > 90) {

      throw ArgumentError('Day must be between 1 and 90, got $day');

    }

  }



  /// Assert that service has been initialized

  void _assertInitialized() {

    if (!_isInitialized) {

      throw StateError(

        'CurriculumProgressService not initialized. Call initialize() first.',

      );

    }

  }



  /// Get detailed status report

  String getStatusReport() {

    StringBuffer report = StringBuffer();

    report.writeln('=== CURRICULUM PROGRESS STATUS ===');

    report.writeln('');

    report.writeln('Initialized: $_isInitialized');

    report.writeln('Current Learning Day: $_currentLearningDay');

    report.writeln(

      'Reinforcement Mode Eligible: ${isReinforcementModeEligible()}',

    );

    report.writeln('');



    if (_isInitialized) {

      report.writeln(_curriculumService.getVerificationReport());

    }



    report.writeln('==================================');

    return report.toString();

  }

}



