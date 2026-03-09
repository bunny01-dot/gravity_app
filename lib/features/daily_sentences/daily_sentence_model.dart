class DailySentence {
  final String id;
  final String day;
  final String text; // English text (learning language)
  final String tamilText;
  final String hindiText;

  DailySentence({
    required this.id,
    required this.day,
    required this.text,
    required this.tamilText,
    required this.hindiText,
  });

  factory DailySentence.fromCsv(List<dynamic> row, {int rowIndex = 0}) {
    // Expected CSV format: Day, Level/Difficulty, English, Tamil, Hindi
    // Example: Day 1, Intermediate, English Text, Tamil Text, Hindi Text
    final day = row.isNotEmpty ? row[0].toString().trim() : '';
    final english = row.length > 2 ? row[2].toString().trim() : '';
    return DailySentence(
      id: _stableId(day: day, english: english, fallbackIndex: rowIndex),
      day: day,
      text: english,
      tamilText: row.length > 3 ? row[3].toString().trim() : '',
      hindiText: row.length > 4 ? row[4].toString().trim() : '',
    );
  }

  static String _stableId({
    required String day,
    required String english,
    required int fallbackIndex,
  }) {
    final normalized = '${day.toLowerCase()}|${english.toLowerCase()}'
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return 'ds_${fallbackIndex + 1}';

    int hash = 0;
    for (final unit in normalized.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return 'ds_$hash';
  }
}
