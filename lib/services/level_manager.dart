import 'package:shared_preferences/shared_preferences.dart';

class LevelManager {
  static final LevelManager _instance = LevelManager._internal();
  factory LevelManager() => _instance;
  LevelManager._internal();

  // Key format: "gameId_level" -> stars (0 = locked, 1-3 = unlocked/stars)
  // Actually, let's say 0 = unlocked but 0 stars?
  // Or better: Use -1 for locked, 0 for unlocked (no stars), 1-3 for stars.

  // Actually simpler:
  // "gameId_unlockedLevel" -> int (max unlocked level)
  // "gameId_level_stars" -> int (stars for that level)

  Future<int> getUnlockedLevel(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${gameId}_unlocked_level') ?? 1;
  }

  Future<void> unlockNextLevel(String gameId, int currentLevel) async {
    final prefs = await SharedPreferences.getInstance();
    int currentMax = prefs.getInt('${gameId}_unlocked_level') ?? 1;
    if (currentLevel >= currentMax) {
      await prefs.setInt('${gameId}_unlocked_level', currentLevel + 1);
    }
  }

  Future<int> getStars(String gameId, int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${gameId}_level_${level}_stars') ?? 0;
  }

  Future<void> saveStars(String gameId, int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt('${gameId}_level_${level}_stars') ?? 0;
    if (stars > current) {
      await prefs.setInt('${gameId}_level_${level}_stars', stars);
    }
  }
}
