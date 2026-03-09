import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/stage_progress_service.dart';

class DataServiceStreak {
  const DataServiceStreak._();

  /// Level-based streak rule:
  /// streak = max(current_learning_stage - 1, 0)
  ///
  /// Continue condition:
  /// - Completing and unlocking the next level.
  ///
  /// Break condition:
  /// - Explicit progression reset (for example force-onboarding/admin reset).
  ///
  /// Inactivity policy:
  /// - No calendar/day expiry. Streak does not decay by time.
  static int _streakFromStage(int stage) => stage > 1 ? stage - 1 : 0;

  static Future<int> getStreakCount({
    required SharedPreferences prefs,
    required String userId,
    required DateTime now,
  }) async {
    final stage = await StageProgressService().getCurrentStage(prefs: prefs);
    return _streakFromStage(stage);
  }

  static Future<int> getStreak({
    required SharedPreferences prefs,
    required String userId,
  }) async {
    final stage = await StageProgressService().getCurrentStage(prefs: prefs);
    return _streakFromStage(stage);
  }

  static Future<void> updateStreak({
    required SharedPreferences prefs,
    required String userId,
    required DateTime now,
  }) async {
    final stage = await StageProgressService().getCurrentStage(prefs: prefs);
    final streak = _streakFromStage(stage);
    // Keep both keys for backward compatibility with legacy data.
    await prefs.setInt('user_streak_days', streak);
    await prefs.setInt('user_stage_streak', streak);
  }
}
