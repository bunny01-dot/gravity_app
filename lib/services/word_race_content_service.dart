import 'package:gravity_app/features/daily_sentences/daily_sentence_service.dart';
import 'package:gravity_app/models/verb_item.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/stage_content_service.dart';
import 'package:gravity_app/services/stage_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WordRaceLevel { beginner, intermediate, advanced }

enum WordRaceItemType { word, sentence, verb }

class WordRaceItem {
  final String prompt;
  final String answer;
  final WordRaceItemType type;

  const WordRaceItem({
    required this.prompt,
    required this.answer,
    required this.type,
  });
}

class WordRaceSession {
  final List<WordRaceItem> items;
  final int poolSize;
  final int wordPool;
  final int sentencePool;
  final int verbPool;

  const WordRaceSession({
    required this.items,
    required this.poolSize,
    required this.wordPool,
    required this.sentencePool,
    required this.verbPool,
  });
}

class WordRaceContentService {
  final DataService _dataService;
  final DailySentenceService _dailySentenceService;
  final StageProgressService _stageService;
  final StageContentService _contentService;

  WordRaceContentService({
    DataService? dataService,
    DailySentenceService? dailySentenceService,
    StageProgressService? stageProgressService,
    StageContentService? stageContentService,
  }) : _dataService = dataService ?? DataService(),
       _dailySentenceService = dailySentenceService ?? DailySentenceService(),
       _stageService = stageProgressService ?? StageProgressService(),
       _contentService = stageContentService ?? StageContentService();

  Future<WordRaceSession> buildSession(
    WordRaceLevel level, {
    int maxItems = 10,
  }) async {
    final learnedSet = await _getLearnedSet();
    if (learnedSet.isEmpty) {
      return const WordRaceSession(
        items: [],
        poolSize: 0,
        wordPool: 0,
        sentencePool: 0,
        verbPool: 0,
      );
    }

    final learnedItems = await _getLearnedVocabularyItems(learnedSet);
    if (learnedItems.isEmpty) {
      return const WordRaceSession(
        items: [],
        poolSize: 0,
        wordPool: 0,
        sentencePool: 0,
        verbPool: 0,
      );
    }

    final learnedVerbs = await _getLearnedVerbItems();
    final todayIds = await _getTodayLearnedIds();

    final shortWords = _filterByLength(learnedItems, maxLength: 6);
    final longWords = _filterByLength(learnedItems, minLength: 7);

    final todayItems = learnedItems
        .where((item) => todayIds.contains(_normalizeWord(item.word)))
        .toList();

    final sentenceItems = await _buildSentenceItems(
      learnedItems,
      learnedSet,
    );

    final shortSentenceItems = await _buildSentenceItems(
      learnedItems,
      learnedSet,
      maxWords: 9,
    );

    final verbItems = _buildVerbItems(learnedVerbs);

    List<WordRaceItem> sessionItems = [];
    int wordPool = 0;
    int sentencePool = 0;
    int verbPool = 0;

    if (level == WordRaceLevel.beginner) {
      final todayShort = _filterByLength(todayItems, maxLength: 6)..shuffle();
      final fallbackShort =
          (shortWords.isNotEmpty ? shortWords : _shortestWords(learnedItems))
            ..shuffle();

      final ordered = [
        ..._wordItemsFrom(todayShort),
        ..._wordItemsFrom(
          fallbackShort.where((item) => !todayShort.contains(item)).toList(),
        ),
      ];

      wordPool = ordered.length;
      sessionItems = ordered.take(maxItems).toList();
    } else if (level == WordRaceLevel.intermediate) {
      final words = _wordItemsFrom(learnedItems);
      final sentences = sentenceItems;
      final verbs = verbItems;

      wordPool = words.length;
      sentencePool = sentences.length;
      verbPool = verbs.length;

      sessionItems = _mixItems(
        words: words,
        sentences: sentences,
        verbs: verbs,
        maxItems: maxItems,
        ensureSentence: sentences.isNotEmpty,
        ensureVerb: verbs.isNotEmpty,
      );
    } else {
      final words = _wordItemsFrom(longWords.isNotEmpty ? longWords : learnedItems);
      final sentences = shortSentenceItems.isNotEmpty
          ? shortSentenceItems
          : sentenceItems;
      final verbs = verbItems;

      wordPool = words.length;
      sentencePool = sentences.length;
      verbPool = verbs.length;

      sessionItems = _mixItems(
        words: words,
        sentences: sentences,
        verbs: verbs,
        maxItems: maxItems,
        ensureSentence: sentences.isNotEmpty,
        ensureVerb: verbs.isNotEmpty,
      );
    }

    final poolSize = wordPool + sentencePool + verbPool;

    return WordRaceSession(
      items: sessionItems,
      poolSize: poolSize,
      wordPool: wordPool,
      sentencePool: sentencePool,
      verbPool: verbPool,
    );
  }

  Future<Set<String>> _getLearnedSet() async {
    final prefs = await SharedPreferences.getInstance();
    final learnedIds = prefs.getStringList('learned_vocab_ids') ?? [];
    return learnedIds
        .map(_normalizeWord)
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<List<VocabularyItem>> _getLearnedVocabularyItems(
    Set<String> learnedSet,
  ) async {
    final items = await _dataService.getLearnedVocabularyItems();
    return items
        .where((item) => learnedSet.contains(_normalizeWord(item.word)))
        .toList();
  }

  Future<List<VerbItem>> _getLearnedVerbItems() async {
    final prefs = await SharedPreferences.getInstance();
    final learnedIds = prefs.getStringList('learned_verbs_ids') ?? [];
    final learnedVerbSet = learnedIds
        .map(_normalizeWord)
        .where((id) => id.isNotEmpty)
        .toSet();

    final verbs = await _dataService.getLearnedVerbItems();
    return verbs
        .where((verb) => learnedVerbSet.contains(_normalizeWord(verb.base)))
        .toList();
  }

  Future<Set<String>> _getTodayLearnedIds() async {
    final stage = await _stageService.getCurrentStage();
    final stageItems = await _contentService.getVocabularyForStage(stage);
    return stageItems
        .map((item) => _normalizeWord(item.word))
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  List<VocabularyItem> _filterByLength(
    List<VocabularyItem> items, {
    int? maxLength,
    int? minLength,
  }) {
    return items.where((item) {
      final length = _normalizeWord(item.word).length;
      if (maxLength != null && length > maxLength) return false;
      if (minLength != null && length < minLength) return false;
      return true;
    }).toList();
  }

  List<VocabularyItem> _shortestWords(List<VocabularyItem> items) {
    final sorted = [...items]
      ..sort(
        (a, b) => _normalizeWord(a.word).length.compareTo(
          _normalizeWord(b.word).length,
        ),
      );
    return sorted.take(10).toList();
  }

  List<WordRaceItem> _wordItemsFrom(List<VocabularyItem> items) {
    return items
        .where((item) => item.word.trim().isNotEmpty)
        .map((item) {
          final definition = item.definition.trim();
          final prompt = definition.isNotEmpty
              ? 'Type the word for: $definition'
              : 'Type the word: ${item.word}';
          return WordRaceItem(
            prompt: prompt,
            answer: item.word,
            type: WordRaceItemType.word,
          );
        })
        .toList();
  }

  List<WordRaceItem> _buildVerbItems(List<VerbItem> verbs) {
    final items = <WordRaceItem>[];
    for (final verb in verbs) {
      final base = verb.base.trim();
      final past = verb.past.trim();
      if (base.isEmpty || past.isEmpty) continue;
      if (_normalizeWord(base) == _normalizeWord(past)) continue;
      items.add(
        WordRaceItem(
          prompt: "Past of '$base'",
          answer: past,
          type: WordRaceItemType.verb,
        ),
      );
    }
    return items;
  }

  Future<List<WordRaceItem>> _buildSentenceItems(
    List<VocabularyItem> learnedItems,
    Set<String> learnedSet, {
    int? maxWords,
  }) async {
    final items = <WordRaceItem>[];
    final candidates = <String>[];

    for (final item in learnedItems) {
      final sentence = item.exampleSentence.trim();
      if (sentence.isNotEmpty) candidates.add(sentence);
    }

    final dailySentences = await _dailySentenceService.getDailySentences();
    for (final sentence in dailySentences) {
      final raw = sentence.text.trim();
      if (raw.isNotEmpty) candidates.add(raw);
    }

    for (final sentence in candidates) {
      if (maxWords != null && _countWords(sentence) > maxWords) continue;
      final words = _extractWords(sentence);
      if (words.isEmpty) continue;
      if (!_allLearned(words, learnedSet)) continue;
      final target = _pickTargetWord(words, learnedSet);
      if (target.isEmpty) continue;
      final masked = _maskWord(sentence, target);
      items.add(
        WordRaceItem(
          prompt: 'Complete the sentence: $masked',
          answer: target,
          type: WordRaceItemType.sentence,
        ),
      );
    }

    return items;
  }

  List<WordRaceItem> _mixItems({
    required List<WordRaceItem> words,
    required List<WordRaceItem> sentences,
    required List<WordRaceItem> verbs,
    required int maxItems,
    required bool ensureSentence,
    required bool ensureVerb,
  }) {
    final pool = <WordRaceItem>[];
    pool.addAll(words);
    pool.addAll(sentences);
    pool.addAll(verbs);
    pool.shuffle();

    final selected = <WordRaceItem>[];
    if (ensureSentence && sentences.isNotEmpty) {
      selected.add(sentences.first);
    }
    if (ensureVerb && verbs.isNotEmpty) {
      selected.add(verbs.first);
    }

    for (final item in pool) {
      if (selected.length >= maxItems) break;
      if (selected.contains(item)) continue;
      selected.add(item);
    }

    return selected.take(maxItems).toList();
  }

  List<String> _extractWords(String sentence) {
    return RegExp(r"[A-Za-z']+")
        .allMatches(sentence)
        .map((match) => match.group(0) ?? '')
        .map(_normalizeWord)
        .where((word) => word.isNotEmpty)
        .toList();
  }

  bool _allLearned(List<String> words, Set<String> learnedSet) {
    for (final word in words) {
      if (!learnedSet.contains(word)) return false;
    }
    return true;
  }

  String _pickTargetWord(List<String> words, Set<String> learnedSet) {
    final candidates = words
        .where(
          (word) => learnedSet.contains(word) && word.length >= 3,
        )
        .toList();
    if (candidates.isEmpty) return '';
    candidates.sort((a, b) => b.length.compareTo(a.length));
    return candidates.first;
  }

  String _maskWord(String sentence, String target) {
    final regex = RegExp('\\b${RegExp.escape(target)}\\b', caseSensitive: false);
    return sentence.replaceFirst(regex, '____');
  }

  int _countWords(String sentence) {
    return _extractWords(sentence).length;
  }

  String _normalizeWord(String value) {
    final lower = value.trim().toLowerCase();
    return lower.replaceAll(RegExp(r"[^a-z']"), '');
  }
}
