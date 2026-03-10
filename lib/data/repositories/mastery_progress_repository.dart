import 'package:shared_preferences/shared_preferences.dart';

class MasteryProgressRepository {
  Future<List<String>> getCompletedExerciseIds(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'mastery_${type}_completed';
    return prefs.getStringList(key) ?? [];
  }

  Future<int> getHighScore(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('highscore_$gameId') ?? 0;
  }

  Future<bool> isNewHighScore(String gameId, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHigh = prefs.getInt('highscore_$gameId') ?? 0;
    return score > currentHigh;
  }
}
