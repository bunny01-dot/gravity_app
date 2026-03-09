import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/data_service_content_loaders.dart';
import 'package:gravity_app/services/placement_state_service.dart';

@Deprecated('Legacy calendar-based daily assignment. Unused in stage system.')
class DataServiceDailyAssignment {
  const DataServiceDailyAssignment._();

  static Future<String> resolveLevelSuffix({
    required SharedPreferences prefs,
    required String userId,
  }) async {
    return PlacementStateService.getCourseLevelSuffix();
  }

  static Future<List<Map<String, String>>> getVocabularyForDate({
    required DateTime date,
    required List<List<dynamic>> cachedVocabData,
    required SharedPreferences prefs,
    required String userId,
    bool createIfMissing = true,
  }) async {
    final dateKey = date.toIso8601String().split('T')[0];

    // LEVEL-SCOPED KEYS to ensure strict separation
    final levelSuffix = await resolveLevelSuffix(
      prefs: prefs,
      userId: userId,
    ); // e.g., "Beginner", "Intermediate"

    // Daily Assignment Key: vocab_guest_2024-01-29_Beginner
    final key = 'vocab_${userId}_${dateKey}_$levelSuffix';

    // Progress Key: total_vocab_assigned_guest_Beginner
    // This strict tracking ensures a user starts at Day 1 (Index 0) for EACH level independently.
    final totalAssignedKey = 'total_vocab_assigned_${userId}_$levelSuffix';

    const dailyWordCount = 5;

    // Check if assignments already exist for THIS user, THIS date, and THIS level
    if (prefs.containsKey(key)) {
      final savedIndicesString = prefs.getString(key);
      if (savedIndicesString != null) {
        final indices = savedIndicesString
            .split(',')
            .map((e) => int.tryParse(e) ?? 0)
            .toList();

        // Basic bounds check
        if (indices.any((i) => i >= cachedVocabData.length)) {
          // Invalid for this level? Wipe it.
          await prefs.remove(key);
        } else {
          // CONGRUENCE CHECK: Resize if goal changed
          if (indices.length != dailyWordCount) {
            final int currentTotalAssigned =
                prefs.getInt(totalAssignedKey) ?? 0;
            if (indices.length < dailyWordCount) {
              // Expand
              int needed = dailyWordCount - indices.length;
              for (int i = 0; i < needed; i++) {
                int idx = (currentTotalAssigned + i) % cachedVocabData.length;
                indices.add(idx);
              }
              await prefs.setInt(
                totalAssignedKey,
                currentTotalAssigned + needed,
              );
            } else {
              // Shrink
              int removeCount = indices.length - dailyWordCount;
              await prefs.setInt(
                totalAssignedKey,
                currentTotalAssigned - removeCount,
              );
              indices.removeRange(dailyWordCount, indices.length);
            }
            await prefs.setString(key, indices.join(','));
          }
          return mapVocabularyByIndices(
            cachedVocabData,
            indices,
            userLanguage: prefs.getString('preferred_language') ?? 'Tamil',
          );
        }
      }
    }

    // If we are strictly reading (History mode) and no key exists, return empty.
    if (!createIfMissing) return [];

    //  BLOCKER: Do not assign sequential indices for dates BEFORE the start date.
    // This prevents Day 1 users from consuming indices when clicking "Yesterday's Quiz"
    final startDateStr = prefs.getString('learning_start_date');
    if (startDateStr != null) {
      final startDate = DateTime.parse(startDateStr);
      // Compare dates only (ignore time)
      final startOnly = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      final targetOnly = DateTime(date.year, date.month, date.day);
      if (targetOnly.isBefore(startOnly)) {
        debugPrint(
          "DataService: Target date $dateKey is before Start Date. Returning empty pool.",
        );
        return [];
      }
    }

    // New Day Assignment (Strict Sequential)
    int startIndex = prefs.getInt(totalAssignedKey) ?? 0;

    final List<int> newIndices = [];

    // Check if we are entering revision mode
    if (startIndex >= cachedVocabData.length && startIndex > 0) {
      // Revision logic or loop
    }

    for (int i = 0; i < dailyWordCount; i++) {
      int idx = (startIndex + i) % cachedVocabData.length;
      newIndices.add(idx);
    }

    // Save Local
    await prefs.setString(key, newIndices.join(','));
    await prefs.setInt(totalAssignedKey, startIndex + dailyWordCount);

    // Save Cloud (Disabled temporarily as per user request flow, or re-enable if desired)
    // saveProgressToCloud(key, newIndices.join(','));
    // saveProgressToCloud(totalAssignedKey, startIndex + dailyWordCount);

    return mapVocabularyByIndices(
      cachedVocabData,
      newIndices,
      userLanguage: prefs.getString('preferred_language') ?? 'Tamil',
    );
  }

  static Future<List<Map<String, String>>> getVerbsForDate({
    required DateTime date,
    required List<List<dynamic>> cachedVerbData,
    required SharedPreferences prefs,
    required String userId,
  }) async {
    final dateKey = date.toIso8601String().split('T')[0];

    // LEVEL-SCOPED KEYS to ensure strict separation
    final levelSuffix = await resolveLevelSuffix(
      prefs: prefs,
      userId: userId,
    ); // e.g., "Beginner", "Intermediate"

    // Daily Assignment Key: verbs_guest_2024-01-29_Beginner
    final key = 'verbs_${userId}_${dateKey}_$levelSuffix';

    // Progress Key: total_verbs_assigned_guest_Beginner
    final totalAssignedKey = 'total_verbs_assigned_${userId}_$levelSuffix';

    const dailyWordCount = 5;

    // Check if assignments already exist for THIS user, THIS date, and THIS level
    if (prefs.containsKey(key)) {
      final savedIndicesString = prefs.getString(key);
      if (savedIndicesString != null) {
        final indices = savedIndicesString
            .split(',')
            .map((e) => int.tryParse(e) ?? 0)
            .toList();

        // Basic bounds check to prevent crash if data changes
        if (indices.any((i) => i >= cachedVerbData.length)) {
          // NOTE: Verb assignments intentionally do NOT wipe invalid keys here.
          // This mirrors legacy behavior and allows regeneration via fall-through.
        } else {
          // CONGRUENCE CHECK: Resize if goal changed
          if (indices.length != dailyWordCount) {
            final int currentTotalAssigned =
                prefs.getInt(totalAssignedKey) ?? 0;
            if (indices.length < dailyWordCount) {
              // Expand
              int needed = dailyWordCount - indices.length;
              for (int i = 0; i < needed; i++) {
                int idx = (currentTotalAssigned + i) % cachedVerbData.length;
                indices.add(idx);
              }
              await prefs.setInt(
                totalAssignedKey,
                currentTotalAssigned + needed,
              );
            } else {
              // Shrink
              int removeCount = indices.length - dailyWordCount;
              await prefs.setInt(
                totalAssignedKey,
                currentTotalAssigned - removeCount,
              );
              indices.removeRange(dailyWordCount, indices.length);
            }
            await prefs.setString(key, indices.join(','));
          }
          return mapVerbsByIndices(
            cachedVerbData,
            indices,
            userLanguage: prefs.getString('preferred_language') ?? 'Tamil',
          );
        }
      }
    }

    // New Day Assignment (Strict Sequential)
    int startIndex = prefs.getInt(totalAssignedKey) ?? 0;
    final List<int> newIndices = [];

    // Revision check
    if (startIndex >= cachedVerbData.length && startIndex > 0) {
      // Loop or revision logic
    }

    for (int i = 0; i < dailyWordCount; i++) {
      int idx = (startIndex + i) % cachedVerbData.length;
      newIndices.add(idx);
    }

    final newStr = newIndices.join(',');

    // Save Local
    await prefs.setString(key, newStr);
    await prefs.setInt(totalAssignedKey, startIndex + dailyWordCount);

    // Save Cloud (Disabled temporarily or consistent with Vocab)
    // saveProgressToCloud(key, newStr);
    // saveProgressToCloud(totalAssignedKey, startIndex + dailyWordCount);

    return mapVerbsByIndices(
      cachedVerbData,
      newIndices,
      userLanguage: prefs.getString('preferred_language') ?? 'Tamil',
    );
  }
}
