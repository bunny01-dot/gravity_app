import 'dart:math';

class GameUtils {
  /// Normalizes a string by converting to lowercase and removing punctuation.
  /// Useful for fuzzy logical comparisons.
  static String normalizeString(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
  }

  /// Calculates the Levenshtein distance between two strings.
  /// Returns the number of edits required to turn [a] into [b].
  static int levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    int la = a.length;
    int lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;

    List<int> v0 = List<int>.filled(lb + 1, 0);
    List<int> v1 = List<int>.filled(lb + 1, 0);

    for (int i = 0; i <= lb; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < la; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < lb; j++) {
        int cost = (a.codeUnitAt(i) == b.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= lb; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[lb];
  }

  /// Calculates a similarity score between 0.0 and 1.0 based on Levenshtein distance.
  static double calculateAccuracy(String target, String input) {
    String t = normalizeString(target);
    String i = normalizeString(input);

    if (t.isEmpty && i.isEmpty) return 1.0;
    if (t.isEmpty || i.isEmpty) return 0.0;

    int distance = levenshteinDistance(t, i);
    int maxLength = max(t.length, i.length);

    double accuracy = 1.0 - (distance / maxLength);
    return accuracy.clamp(0.0, 1.0);
  }

  /// Safely picks [count] distractors from [source] list excluding [correctItem].
  /// If source is small, it may repeat items but tries to avoid [correctItem].
  static List<T> pickDistractors<T>(List<T> source, T correctItem, int count) {
    if (source.isEmpty) return [];

    // Create candidate list excluding the correct item
    final candidates = source.where((item) => item != correctItem).toList();

    if (candidates.isEmpty) {
      // Emergency fallback if source only had the correct item (shouldn't happen in real games)
      return List.filled(count, correctItem);
    }

    candidates.shuffle();

    // If we have enough unique candidates
    if (candidates.length >= count) {
      return candidates.take(count).toList();
    }

    // If we don't have enough, loop through them to fill the count
    List<T> result = [];
    for (int i = 0; i < count; i++) {
      result.add(candidates[i % candidates.length]);
    }
    return result;
  }
}
