import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/data_service_streak.dart';
import 'package:gravity_app/services/xp_reward_policy.dart';

class UserProgressRepository {
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

  Future<int> getStreakCount({
    required String userId,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return DataServiceStreak.getStreakCount(
      prefs: prefs,
      userId: userId,
      now: now ?? DateTime.now(),
    );
  }

  Future<int> getStreak({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    return DataServiceStreak.getStreak(prefs: prefs, userId: userId);
  }

  Future<void> updateStreak({
    required String userId,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await DataServiceStreak.updateStreak(
      prefs: prefs,
      userId: userId,
      now: now ?? DateTime.now(),
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
}
