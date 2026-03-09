import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/stage_content_service.dart';

class UserLevelService {
  static const String userLevelKey = 'user_level';
  static const String _pendingCelebrationKey = 'user_level_pending_celebration';

  static const String levelBeginner = 'Beginner';
  static const String levelIntermediate = 'Intermediate';
  static const String levelAdvanced = 'Advanced';

  static Future<String> getCurrentLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getString(userLevelKey);
    return _normalizeLevel(level) ?? levelBeginner;
  }

  static Future<bool> updateLevelFromScore({
    required int score,
    required int total,
  }) async {
    final newLevel = _levelForScore(score, total);
    return updateLevel(newLevel);
  }

  static Future<bool> updateLevel(String newLevel) async {
    final normalized = _normalizeLevel(newLevel) ?? levelBeginner;
    final prefs = await SharedPreferences.getInstance();
    final legacyXpLevel = prefs.getInt('user_level');
    if (prefs.getInt('user_xp_level') == null && legacyXpLevel != null) {
      await prefs.setInt('user_xp_level', legacyXpLevel);
    }
    final current =
        _normalizeLevel(prefs.getString(userLevelKey)) ?? levelBeginner;

    if (_rank(normalized) <= _rank(current)) {
      return false;
    }

    await prefs.setString(userLevelKey, normalized);
    await prefs.setString(_pendingCelebrationKey, normalized);

    StageContentService().reset();
    return true;
  }

  static Future<String?> consumePendingCelebration() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = _normalizeLevel(prefs.getString(_pendingCelebrationKey));
    if (pending == null || pending.isEmpty) return null;
    await prefs.remove(_pendingCelebrationKey);
    return pending;
  }

  static String _levelForScore(int score, int total) {
    if (total <= 0) return levelBeginner;
    final percentage = score / total;
    if (percentage >= 0.8) return levelAdvanced;
    if (percentage >= 0.7) return levelIntermediate;
    return levelBeginner;
  }

  static int _rank(String level) {
    switch (level) {
      case levelAdvanced:
        return 3;
      case levelIntermediate:
        return 2;
      default:
        return 1;
    }
  }

  static String? _normalizeLevel(String? level) {
    if (level == null) return null;
    final trimmed = level.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    if (lower.contains('advanced')) return levelAdvanced;
    if (lower.contains('inter')) return levelIntermediate;
    if (lower.contains('begin')) return levelBeginner;
    return null;
  }
}
