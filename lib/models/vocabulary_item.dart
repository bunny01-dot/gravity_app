class VocabularyItem {
  final String id;
  final String word;
  final String definition;
  final String tamilMeaning;
  final String hindiMeaning;
  final String? imageUrl; // URLs or asset paths
  final String? audioUrl;
  final List<String> synonyms;
  final List<String> localizedSynonyms;
  final List<String> antonyms;
  final String exampleSentence;
  final String englishExample;
  final String tamilExample;
  final String hindiExample;
  final String translation; // Optional for multi-language support

  final int difficulty;
  final int revisionCount;
  final bool isLearned;
  final DateTime? learnedDate;
  final String pos; // Part of Speech
  final int dayNumber; // Day number (1-90) for curriculum mapping

  VocabularyItem({
    required this.id,
    required this.word,
    required this.definition,
    this.tamilMeaning = '',
    this.hindiMeaning = '',
    this.imageUrl,
    this.audioUrl,
    this.synonyms = const [],
    this.localizedSynonyms = const [],
    this.antonyms = const [],
    required this.exampleSentence,
    this.englishExample = '',
    this.tamilExample = '',
    this.hindiExample = '',
    this.translation = '', // Used as 'tamilMeaning'
    this.difficulty = 1,
    this.revisionCount = 0,
    this.isLearned = false,
    this.learnedDate,
    this.pos = '',
    this.dayNumber = 0,
  });
}
