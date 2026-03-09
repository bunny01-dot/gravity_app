import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class WordMatchUnlockService {
  static const int easyRequiredWords = 4;
  static const int mediumRequiredWords = 8;
  static const int hardRequiredWords = 16;

  static int requiredWordsForDifficulty(String difficulty) {
    switch (difficulty) {
      case 'Hard':
        return hardRequiredWords;
      case 'Medium':
        return mediumRequiredWords;
      case 'Easy':
      default:
        return easyRequiredWords;
    }
  }

  static bool isWordMatchUnlocked(
    int totalLearnedWords, {
    String difficulty = 'Easy',
  }) {
    final required = requiredWordsForDifficulty(difficulty);
    return totalLearnedWords >= required;
  }

  static Future<int> getTotalLearnedWords() async {
    final prefs = await SharedPreferences.getInstance();
    final vocabIds = (prefs.getStringList('learned_vocab_ids') ?? [])
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final verbIds = (prefs.getStringList('learned_verbs_ids') ?? [])
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final total = vocabIds.length + verbIds.length;
    debugPrint('Total Learned Words: $total');
    return total;
  }
}
