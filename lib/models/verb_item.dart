class VerbItem {
  final String id;
  final String base;
  final String past;
  final String pastParticiple;
  final String present3rd;
  final String gerund;
  final String tamilMeaning;
  final String hindiMeaning;
  final Map<String, String> exampleSentences;
  final String transitivity; // 'transitive', 'intransitive', 'both'
  final int difficulty;
  bool isLearned; // Mutable for now to track state
  DateTime? learnedDate;
  final int dayNumber; // Day number (1-90) for curriculum mapping

  final List<String> antonyms;

  VerbItem({
    required this.id,
    required this.base,
    required this.past,
    required this.pastParticiple,
    required this.present3rd,
    required this.gerund,
    required this.tamilMeaning,
    this.hindiMeaning = '',
    required this.exampleSentences,
    this.transitivity = 'intransitive',
    this.difficulty = 1,
    this.isLearned = false,
    this.learnedDate,
    this.antonyms = const [],
    this.dayNumber = 0,
  });

  // Helper to create from JSON/Map
  factory VerbItem.fromMap(Map<String, dynamic> map) {
    return VerbItem(
      id: map['id'] ?? map['base'] ?? 'unknown',
      base: map['base'] ?? '',
      past: map['past'] ?? '',
      pastParticiple: map['pastParticiple'] ?? '',
      present3rd: map['present3rd'] ?? '',
      gerund: map['gerund'] ?? '',
      tamilMeaning: map['tamilMeaning'] ?? '',
      hindiMeaning: map['hindiMeaning'] ?? '',
      exampleSentences: Map<String, String>.from(map['exampleSentences'] ?? {}),
      transitivity: map['transitivity'] ?? 'intransitive',
      difficulty: map['difficulty'] ?? 1,
      isLearned: map['learned'] ?? false,
    );
  }
}
