import 'package:gravity_app/models/game_filter.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/day_based_curriculum_service.dart';
import 'package:gravity_app/services/stage_content_service.dart';
import 'package:gravity_app/services/stage_progress_service.dart';

class GameContentService {
  static final GameContentService _instance = GameContentService._internal();
  factory GameContentService() => _instance;
  GameContentService._internal();

  final DataService _dataService = DataService();
  final StageContentService _stageContentService = StageContentService();
  final StageProgressService _stageProgressService = StageProgressService();
  final DayBasedCurriculumService _curriculumService =
      DayBasedCurriculumService();

  Future<List<VocabularyItem>> getVocabularyItems(GameFilter filter) async {
    List<VocabularyItem> items = [];
    switch (filter.source) {
      case GameContentSource.currentStage:
        final stage = await _stageProgressService.getCurrentStage();
        items = await _stageContentService.getVocabularyForStage(stage);
        break;
      case GameContentSource.learned:
        items = await _dataService.getLearnedVocabularyItems();
        break;
      case GameContentSource.blackhole:
        items = await _getBlackholeVocabulary();
        break;
    }

    items = _dedupeByWord(items);
    final userLanguage = await _dataService.getUserLanguage();
    items = _applyLanguage(items, userLanguage);
    items = await _dataService.enrichWithAntonyms(items);
    return items;
  }

  List<VocabularyItem> selectItemsByDifficulty(
    List<VocabularyItem> items,
    GameDifficulty difficulty, {
    int? limitOverride,
  }) {
    if (items.isEmpty) return [];
    final limit = limitOverride ?? difficulty.itemLimit;
    final byCurriculum = _selectByCurriculumDifficulty(
      items,
      difficulty,
      limit,
    );
    if (byCurriculum.isNotEmpty) return byCurriculum;

    return _selectByWordLength(items, difficulty, limit);
  }

  List<VocabularyItem> _selectByCurriculumDifficulty(
    List<VocabularyItem> items,
    GameDifficulty difficulty,
    int limit,
  ) {
    final matching = items
        .where((item) => item.difficulty == difficulty.levelIndex)
        .toList();
    if (matching.isEmpty) return [];

    // Add randomness so 'Play again' yields novel words
    matching.shuffle();
    if (matching.length <= limit) return List<VocabularyItem>.from(matching);
    return matching.take(limit).toList();
  }

  List<VocabularyItem> _selectByWordLength(
    List<VocabularyItem> items,
    GameDifficulty difficulty,
    int limit,
  ) {
    if (items.length <= limit) {
      final pool = List<VocabularyItem>.from(items)..shuffle();
      return pool;
    }

    final sorted = List<VocabularyItem>.from(items)
      ..sort((a, b) {
        final len = a.word.length.compareTo(b.word.length);
        if (len != 0) return len;
        return a.word.toLowerCase().compareTo(b.word.toLowerCase());
      });

    // Expand the selection pool for randomness, then shuffle and cap
    int poolSize = (limit * 2.5).ceil();
    if (poolSize > sorted.length) poolSize = sorted.length;

    switch (difficulty) {
      case GameDifficulty.easy:
        final pool = sorted.take(poolSize).toList()..shuffle();
        return pool.take(limit).toList();
      case GameDifficulty.hard:
        final pool = sorted.reversed.take(poolSize).toList()..shuffle();
        return pool.take(limit).toList();
      case GameDifficulty.medium:
        final start = ((sorted.length - poolSize) / 2).floor();
        final pool = sorted.sublist(start, start + poolSize).toList()
          ..shuffle();
        return pool.take(limit).toList();
    }
  }

  Future<List<VocabularyItem>> _getBlackholeVocabulary() async {
    final rawItems = await _dataService.getBlackHoleItems();
    if (rawItems.isEmpty) return [];

    await _curriculumService.initialize();
    final vocabItems = _curriculumService.getAllVocabulary();
    final lookup = <String, VocabularyItem>{};
    for (final item in vocabItems) {
      lookup[_normalizeWord(item.word)] = item;
    }

    final results = <VocabularyItem>[];
    for (final entry in rawItems) {
      final type = (entry['type'] ?? 'vocab').toLowerCase();
      if (type == 'verb') continue;

      final rawWord = entry['word'] ?? entry['title'] ?? '';
      if (rawWord.trim().isEmpty) continue;

      final key = _normalizeWord(rawWord);
      final match = lookup[key];
      if (match != null) {
        results.add(match);
        continue;
      }

      final fallbackMeaning = entry['meaning'] ?? entry['correct_answer'] ?? '';
      results.add(
        VocabularyItem(
          id: rawWord,
          word: rawWord,
          definition: fallbackMeaning,
          tamilMeaning: fallbackMeaning,
          hindiMeaning: fallbackMeaning,
          exampleSentence: '',
          translation: fallbackMeaning,
        ),
      );
    }

    return results;
  }

  List<VocabularyItem> _dedupeByWord(List<VocabularyItem> items) {
    final seen = <String>{};
    final deduped = <VocabularyItem>[];
    for (final item in items) {
      final key = _normalizeWord(item.word);
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      deduped.add(item);
    }
    return deduped;
  }

  List<VocabularyItem> _applyLanguage(
    List<VocabularyItem> items,
    String userLanguage,
  ) {
    final isHindi = userLanguage.toLowerCase().contains('hindi');
    return items.map((item) {
      final localized = isHindi ? item.hindiMeaning : item.tamilMeaning;
      final definition = localized.isNotEmpty ? localized : item.definition;
      return VocabularyItem(
        id: item.id,
        word: item.word,
        definition: definition,
        tamilMeaning: item.tamilMeaning,
        hindiMeaning: item.hindiMeaning,
        imageUrl: item.imageUrl,
        audioUrl: item.audioUrl,
        synonyms: item.synonyms,
        localizedSynonyms: item.localizedSynonyms,
        antonyms: item.antonyms,
        exampleSentence: item.exampleSentence,
        englishExample: item.englishExample,
        tamilExample: item.tamilExample,
        hindiExample: item.hindiExample,
        translation: definition,
        difficulty: item.difficulty,
        revisionCount: item.revisionCount,
        isLearned: item.isLearned,
        learnedDate: item.learnedDate,
        pos: item.pos,
        dayNumber: item.dayNumber,
      );
    }).toList();
  }

  String _normalizeWord(String word) {
    return word.trim().toLowerCase();
  }
}
