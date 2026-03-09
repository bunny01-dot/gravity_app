import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

@Deprecated('Legacy calendar-based progress service. Unused in stage system.')
class DayBasedProgressService {
  // Singleton pattern
  static final DayBasedProgressService _instance =
      DayBasedProgressService._internal();

  factory DayBasedProgressService() {
    return _instance;
  }

  DayBasedProgressService._internal();

  /// Save daily vocabulary IDs for a specific date
  Future<void> saveDailyVocabularyIds(
    DateTime date,
    List<String> vocabularyIds,
  ) async {
    String dateKey = _dateToKey(date);
    String key = 'vocab_ids_$dateKey';

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, vocabularyIds.join(','));

    // Sync to cloud
    await _syncToCloud(key, vocabularyIds.join(','));

    debugPrint('OK: Saved ${vocabularyIds.length} vocabulary IDs for $dateKey');
  }

  /// Save daily verb IDs for a specific date
  Future<void> saveDailyVerbIds(DateTime date, List<String> verbIds) async {
    String dateKey = _dateToKey(date);
    String key = 'verb_ids_$dateKey';

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, verbIds.join(','));

    // Sync to cloud
    await _syncToCloud(key, verbIds.join(','));

    debugPrint('OK: Saved ${verbIds.length} verb IDs for $dateKey');
  }

  /// Mark vocabulary items as learned for a specific date
  Future<void> markVocabularyAsLearned(
    DateTime date,
    List<String> learnedIds,
  ) async {
    String dateKey = _dateToKey(date);
    String key = 'learned_vocab_$dateKey';

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, learnedIds.join(','));

    // Sync to cloud
    await _syncToCloud(key, learnedIds.join(','));

    debugPrint(
      'OK: Marked ${learnedIds.length} vocabulary items as learned for $dateKey',
    );
  }

  /// Mark verbs as learned for a specific date
  Future<void> markVerbsAsLearned(
    DateTime date,
    List<String> learnedIds,
  ) async {
    String dateKey = _dateToKey(date);
    String key = 'learned_verbs_$dateKey';

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, learnedIds.join(','));

    // Sync to cloud
    await _syncToCloud(key, learnedIds.join(','));

    debugPrint('OK: Marked ${learnedIds.length} verbs as learned for $dateKey');
  }

  /// Get daily vocabulary IDs for a specific date
  Future<List<String>> getDailyVocabularyIds(DateTime date) async {
    String dateKey = _dateToKey(date);
    String key = 'vocab_ids_$dateKey';

    // Try to load from cloud first
    await _syncFromCloud(key);

    // Load from local storage
    final prefs = await SharedPreferences.getInstance();
    String? idsStr = prefs.getString(key);

    if (idsStr == null || idsStr.isEmpty) {
      return [];
    }

    return idsStr.split(',').where((id) => id.isNotEmpty).toList();
  }

  /// Get daily verb IDs for a specific date
  Future<List<String>> getDailyVerbIds(DateTime date) async {
    String dateKey = _dateToKey(date);
    String key = 'verb_ids_$dateKey';

    // Try to load from cloud first
    await _syncFromCloud(key);

    // Load from local storage
    final prefs = await SharedPreferences.getInstance();
    String? idsStr = prefs.getString(key);

    if (idsStr == null || idsStr.isEmpty) {
      return [];
    }

    return idsStr.split(',').where((id) => id.isNotEmpty).toList();
  }

  /// Get learned vocabulary IDs for a specific date
  Future<List<String>> getLearnedVocabularyIds(DateTime date) async {
    String dateKey = _dateToKey(date);
    String key = 'learned_vocab_$dateKey';

    // Try to load from cloud first
    await _syncFromCloud(key);

    // Load from local storage
    final prefs = await SharedPreferences.getInstance();
    String? idsStr = prefs.getString(key);

    if (idsStr == null || idsStr.isEmpty) {
      return [];
    }

    return idsStr.split(',').where((id) => id.isNotEmpty).toList();
  }

  /// Get learned verb IDs for a specific date
  Future<List<String>> getLearnedVerbIds(DateTime date) async {
    String dateKey = _dateToKey(date);
    String key = 'learned_verbs_$dateKey';

    // Try to load from cloud first
    await _syncFromCloud(key);

    // Load from local storage
    final prefs = await SharedPreferences.getInstance();
    String? idsStr = prefs.getString(key);

    if (idsStr == null || idsStr.isEmpty) {
      return [];
    }

    return idsStr.split(',').where((id) => id.isNotEmpty).toList();
  }

  /// Get vocabulary IDs for a date range (for missed days quiz)
  Future<List<String>> getVocabularyIdsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    Set<String> allIds = {};

    DateTime current = startDate;
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      List<String> dayIds = await getDailyVocabularyIds(current);
      allIds.addAll(dayIds);
      current = current.add(const Duration(days: 1));
    }

    return allIds.toList();
  }

  /// Get verb IDs for a date range (for missed days quiz)
  Future<List<String>> getVerbIdsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    Set<String> allIds = {};

    DateTime current = startDate;
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      List<String> dayIds = await getDailyVerbIds(current);
      allIds.addAll(dayIds);
      current = current.add(const Duration(days: 1));
    }

    return allIds.toList();
  }

  /// Sync a key-value pair to Firestore
  Future<void> _syncToCloud(String key, dynamic value) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc('daily_assignments')
          .set({key: value}, SetOptions(merge: true));

      debugPrint('  Synced $key to cloud');
    } catch (e) {
      debugPrint('[WARN]  Failed to sync $key to cloud: $e');
    }
  }

  /// Sync a key-value pair from Firestore
  Future<void> _syncFromCloud(String key) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc('daily_assignments')
          .get();

      if (!doc.exists) return;

      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey(key)) return;

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, data[key].toString());

      debugPrint('  Synced $key from cloud');
    } catch (e) {
      debugPrint('[WARN]  Failed to sync $key from cloud: $e');
    }
  }

  /// Hydrate all progress from cloud on app startup or new device
  Future<void> hydrateFromCloud() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      debugPrint('  Hydrating daily assignments from cloud...');

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc('daily_assignments')
          .get();

      if (!doc.exists) {
        debugPrint('  No cloud data found');
        return;
      }

      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final prefs = await SharedPreferences.getInstance();
      int syncedKeys = 0;

      for (String key in data.keys) {
        await prefs.setString(key, data[key].toString());
        syncedKeys++;
      }

      debugPrint('OK: Hydrated $syncedKeys keys from cloud');
    } catch (e) {
      debugPrint('Error: Failed to hydrate from cloud: $e');
    }
  }

  /// Verify integrity of saved IDs against CSV items
  Future<Map<String, dynamic>> verifyIntegrity(
    List<String> csvVocabIds,
    List<String> csvVerbIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> report = {
      'valid_vocab_dates': 0,
      'invalid_vocab_dates': 0,
      'valid_verb_dates': 0,
      'invalid_verb_dates': 0,
      'mismatched_vocab_ids': <String>[],
      'mismatched_verb_ids': <String>[],
    };

    // Check last 90 days
    DateTime now = DateTime.now();
    for (int i = 0; i < 90; i++) {
      DateTime date = now.subtract(Duration(days: i));
      String dateKey = _dateToKey(date);

      // Check vocabulary
      String vocabKey = 'vocab_ids_$dateKey';
      String? vocabIdsStr = prefs.getString(vocabKey);
      if (vocabIdsStr != null) {
        List<String> savedIds = vocabIdsStr.split(',');
        bool allValid = savedIds.every((id) => csvVocabIds.contains(id));
        if (allValid) {
          report['valid_vocab_dates']++;
        } else {
          report['invalid_vocab_dates']++;
          List<String> mismatched = savedIds
              .where((id) => !csvVocabIds.contains(id))
              .toList();
          report['mismatched_vocab_ids'].addAll(mismatched);
        }
      }

      // Check verbs
      String verbKey = 'verb_ids_$dateKey';
      String? verbIdsStr = prefs.getString(verbKey);
      if (verbIdsStr != null) {
        List<String> savedIds = verbIdsStr.split(',');
        bool allValid = savedIds.every((id) => csvVerbIds.contains(id));
        if (allValid) {
          report['valid_verb_dates']++;
        } else {
          report['invalid_verb_dates']++;
          List<String> mismatched = savedIds
              .where((id) => !csvVerbIds.contains(id))
              .toList();
          report['mismatched_verb_ids'].addAll(mismatched);
        }
      }
    }

    return report;
  }

  /// Convert DateTime to key string (YYYY-MM-DD)
  String _dateToKey(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }
}

