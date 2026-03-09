import 'dart:math';

/// Pronunciation scoring + encouragement rules shared across mic screens.
/// Keeps normalization and similarity math in one place to avoid drift.
enum PronunciationMode { accuracyCheck, practice, exposure }

enum PronunciationScoreClass { clear, almost, partial, miss }

class PronunciationFeedbackService {
  static const double clearThreshold = 0.50;
  static const double almostThreshold = 0.40;
  static const double partialThreshold = 0.25;

  /// Normalize text for fair comparison.
  /// - lowercase
  /// - remove punctuation (keep apostrophes)
  /// - collapse whitespace
  static String normalizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\s']"), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Similarity score from 0.0 to 1.0 (1.0 = perfect match).
  /// Uses Levenshtein distance on normalized strings.
  static double calculateSimilarity(String expected, String spoken) {
    final expectedClean = normalizeText(expected);
    final spokenClean = normalizeText(spoken);

    if (expectedClean.isEmpty && spokenClean.isEmpty) return 1.0;
    if (expectedClean.isEmpty || spokenClean.isEmpty) return 0.0;

    final distance = _levenshteinDistance(expectedClean, spokenClean);
    final maxLength = max(expectedClean.length, spokenClean.length);
    final similarity = 1.0 - (distance / maxLength);
    return similarity.clamp(0.0, 1.0);
  }

  /// Classify a similarity score into a feedback tier.
  static PronunciationScoreClass classifyScore(double score) {
    if (score >= clearThreshold) return PronunciationScoreClass.clear;
    if (score >= almostThreshold) return PronunciationScoreClass.almost;
    if (score >= partialThreshold) return PronunciationScoreClass.partial;
    return PronunciationScoreClass.miss;
  }

  /// Label shown to the user for the score class.
  static String labelForClass(PronunciationScoreClass scoreClass) {
    switch (scoreClass) {
      case PronunciationScoreClass.clear:
        return 'Clear';
      case PronunciationScoreClass.almost:
        return 'Almost';
      case PronunciationScoreClass.partial:
        return 'Partial';
      case PronunciationScoreClass.miss:
        return 'Try Again';
    }
  }

  /// Convenience helper to label a raw score.
  static String labelForScore(double score) {
    return labelForClass(classifyScore(score));
  }

  /// UI text based on score + attempt count.
  /// Includes score label and improvement delta (attempt >= 2).
  static String feedbackFor(
    double score,
    int attempt,
    double? previousScore,
  ) {
    final scoreClass = classifyScore(score);
    final label = labelForClass(scoreClass);
    final percent = (score * 100).round();

    String base;
    switch (scoreClass) {
      case PronunciationScoreClass.clear:
        base = 'Clear pronunciation.';
        break;
      case PronunciationScoreClass.almost:
        base = 'Almost there, try once more.';
        break;
      case PronunciationScoreClass.partial:
        base = 'Good start, slow down and try again.';
        break;
      case PronunciationScoreClass.miss:
        base = 'Try again, speak a bit louder.';
        break;
    }

    final buffer = StringBuffer('$label - $percent% - $base');

    if (attempt >= 2 && previousScore != null) {
      final prevPercent = (previousScore * 100).round();
      final diff = percent - prevPercent;
      final sign = diff >= 0 ? '+' : '';
      buffer.write(' Change $sign$diff% ($prevPercent% -> $percent%).');
    }

    return buffer.toString();
  }

  /// Number of normalized words in text.
  static int wordCount(String input) => _tokenizeWords(input).length;

  /// LCS-based matched word count (order-aware, tolerant to insertions).
  static int countMatchedWords(String expected, String spoken) {
    final expectedWords = _tokenizeWords(expected);
    final spokenWords = _tokenizeWords(spoken);
    if (expectedWords.isEmpty || spokenWords.isEmpty) return 0;

    final dp = List.generate(
      expectedWords.length + 1,
      (_) => List.filled(spokenWords.length + 1, 0),
    );

    for (int i = 1; i <= expectedWords.length; i++) {
      for (int j = 1; j <= spokenWords.length; j++) {
        if (expectedWords[i - 1] == spokenWords[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = max(dp[i - 1][j], dp[i][j - 1]);
        }
      }
    }

    return dp[expectedWords.length][spokenWords.length];
  }

  /// Lenient pass rule for sentence STT:
  /// - 5+ words: at least 3 matched words
  /// - shorter prompts: at least half (rounded up), minimum 1
  static bool isLenientSentencePass(String expected, String spoken) {
    final expectedWordCount = wordCount(expected);
    if (expectedWordCount == 0) return false;

    final matched = countMatchedWords(expected, spoken);
    final required = expectedWordCount >= 5
        ? 3
        : max(1, (expectedWordCount / 2).ceil());
    return matched >= required;
  }

  /// Returns true if progression should be blocked.
  /// Accuracy check blocks until clear or after 3 attempts.
  static bool shouldBlockProgress(
    PronunciationMode mode,
    double score,
    int attempt,
  ) {
    if (mode == PronunciationMode.accuracyCheck) {
      return score < clearThreshold && attempt < 3;
    }
    return false;
  }

  static int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final List<List<int>> matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
  }

  static List<String> _tokenizeWords(String input) {
    final normalized = normalizeText(input);
    if (normalized.isEmpty) return const [];
    return RegExp(r"[a-z0-9']+")
        .allMatches(normalized)
        .map((match) => match.group(0) ?? '')
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
  }
}
