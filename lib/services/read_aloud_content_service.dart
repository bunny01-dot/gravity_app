import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/features/daily_sentences/daily_sentence_service.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/services/data_service.dart';

class ReadAloudContentService {
  final DataService _dataService;
  final DailySentenceService _dailySentenceService;

  ReadAloudContentService([
    DataService? dataService,
    DailySentenceService? dailySentenceService,
  ])  : _dataService = dataService ?? DataService(),
        _dailySentenceService = dailySentenceService ?? DailySentenceService();

  Future<List<String>> getEligibleItems() async {
    final learnedSet = await _getLearnedWordSet();
    if (learnedSet.isEmpty) return [];

    final difficulty = await _getUserDifficulty();

    final phrases = <String, String>{};
    final sentences = <String, String>{};
    final passages = <String, String>{};

    final learnedItems = await _getLearnedItems(learnedSet);
    for (final item in learnedItems) {
      final word = item.word.trim();
      if (!_isSpeakable(word)) continue;
      _addUnique(phrases, word);
    }

    final dailySentences = await _dailySentenceService.getDailySentences();
    for (final sentence in dailySentences) {
      _collectSentence(sentence.text, learnedSet, phrases, sentences);
    }

    for (final item in learnedItems) {
      final sentence = item.exampleSentence.trim();
      _collectSentence(sentence, learnedSet, phrases, sentences);
    }

    final speakingExercises = await _dataService.getSpeakingExercises();
    for (final exercise in speakingExercises) {
      final category = (exercise['category'] ?? '').toLowerCase().trim();
      if (category != 'dictation' && category != 'pronunciation') continue;
      final text = (exercise['prompt'] ?? exercise['text'] ?? '').trim();
      _collectSentence(text, learnedSet, phrases, sentences);
    }

    final readingExercises = await _dataService.getReadingExercises();
    for (final exercise in readingExercises) {
      final passage = (exercise['passage'] ?? '').trim();
      _collectPassage(passage, learnedSet, passages);
    }

    _buildPassagesFromSentences(sentences.values.toList(), passages);

    final phraseList = _sortByWordCount(phrases.values.toList());
    final sentenceList = _sortByWordCount(sentences.values.toList());
    final passageList = _sortByWordCount(passages.values.toList());

    switch (difficulty) {
      case _ReadAloudDifficulty.beginner:
        return [...phraseList, ...sentenceList];
      case _ReadAloudDifficulty.intermediate:
        return [...sentenceList, ...phraseList, ...passageList];
      case _ReadAloudDifficulty.advanced:
        return [...passageList, ...sentenceList, ...phraseList];
    }
  }

  Future<List<VocabularyItem>> _getLearnedItems(
    Set<String> learnedSet,
  ) async {
    final items = await _dataService.getLearnedVocabularyItems();
    return items
        .where((item) => learnedSet.contains(_normalizeWord(item.word)))
        .toList();
  }

  Future<Set<String>> _getLearnedWordSet() async {
    final prefs = await SharedPreferences.getInstance();
    final learnedIds = prefs.getStringList('learned_vocab_ids') ?? [];
    return learnedIds
        .map(_normalizeWord)
        .where((word) => word.isNotEmpty)
        .toSet();
  }

  Future<_ReadAloudDifficulty> _getUserDifficulty() async {
    final prefs = await SharedPreferences.getInstance();
    final effective = prefs.getString('effective_difficulty_level') ?? '';
    final level = effective.isNotEmpty
        ? effective
        : (prefs.getString('english_proficiency_level') ?? 'Beginner');
    final lower = level.toLowerCase();
    if (lower.contains('advanced')) return _ReadAloudDifficulty.advanced;
    if (lower.contains('intermediate')) {
      return _ReadAloudDifficulty.intermediate;
    }
    return _ReadAloudDifficulty.beginner;
  }

  void _collectSentence(
    String text,
    Set<String> learnedSet,
    Map<String, String> phrases,
    Map<String, String> sentences,
  ) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    if (_isPlaceholderText(cleaned)) return;

    final words = _extractWords(cleaned);
    if (words.isEmpty) return;
    if (!_allLearned(words, learnedSet)) return;

    if (words.length <= _phraseMaxWords) {
      _addUnique(phrases, cleaned);
    } else if (words.length <= _sentenceMaxWords) {
      _addUnique(sentences, cleaned);
    }
  }

  void _collectPassage(
    String text,
    Set<String> learnedSet,
    Map<String, String> passages,
  ) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    if (_isPlaceholderText(cleaned)) return;

    final sentences = _splitSentences(cleaned);
    if (sentences.length < 2 || sentences.length > 4) return;
    if (sentences.any((sentence) => sentence.isEmpty)) return;

    int totalWords = 0;
    for (final sentence in sentences) {
      final words = _extractWords(sentence);
      if (words.isEmpty) return;
      if (words.length > _sentenceMaxWords) return;
      if (!_allLearned(words, learnedSet)) return;
      totalWords += words.length;
    }

    if (totalWords > _passageMaxWords) return;
    _addUnique(passages, sentences.join(' '));
  }

  void _buildPassagesFromSentences(
    List<String> sentenceList,
    Map<String, String> passages,
  ) {
    if (sentenceList.length < 2) return;
    final limited = sentenceList.take(20).toList();
    for (int i = 0; i < limited.length - 1; i++) {
      final combined = '${limited[i]} ${limited[i + 1]}'.trim();
      if (combined.isEmpty) continue;
      if (_extractWords(combined).length > _passageMaxWords) continue;
      _addUnique(passages, combined);
    }
  }

  List<String> _sortByWordCount(List<String> items) {
    items.sort((a, b) => _extractWords(a).length.compareTo(
          _extractWords(b).length,
        ));
    return items;
  }

  void _addUnique(Map<String, String> bucket, String text) {
    final key = _normalizeSentenceKey(text);
    if (key.isEmpty) return;
    bucket.putIfAbsent(key, () => text);
  }

  List<String> _splitSentences(String passage) {
    return passage
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((sentence) => sentence.trim())
        .where((sentence) => sentence.isNotEmpty)
        .toList();
  }

  List<String> _extractWords(String sentence) {
    return RegExp(r"[A-Za-z']+")
        .allMatches(sentence)
        .map((match) => _normalizeWord(match.group(0) ?? ''))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  bool _allLearned(List<String> words, Set<String> learnedSet) {
    for (final word in words) {
      if (!learnedSet.contains(word)) return false;
    }
    return true;
  }

  bool _isSpeakable(String value) {
    if (value.isEmpty) return false;
    if (RegExp(r'\d').hasMatch(value)) return false;
    return true;
  }

  bool _isPlaceholderText(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('new suggested data')) return true;
    if (lower.contains('text column')) return true;
    return false;
  }

  String _normalizeWord(String value) {
    final lower = value.trim().toLowerCase();
    final cleaned = lower.replaceAll(RegExp(r"[^a-z']"), '');
    return cleaned.replaceAll(RegExp(r"^'+|'+$"), '');
  }

  String _normalizeSentenceKey(String sentence) {
    final words = _extractWords(sentence);
    return words.join(' ');
  }
}

enum _ReadAloudDifficulty { beginner, intermediate, advanced }

const int _phraseMaxWords = 3;
const int _sentenceMaxWords = 14;
const int _passageMaxWords = 48;
