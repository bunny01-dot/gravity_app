import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/features/daily_sentences/daily_sentence_service.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/services/data_service.dart';

enum AudioGuessMode { word, sentenceGap }

class AudioGuessQuestion {
  final AudioGuessMode mode;
  final String audioText;
  final String prompt;
  final String displayText;
  final List<String> options;
  final int correctIndex;
  final String targetWord;

  const AudioGuessQuestion({
    required this.mode,
    required this.audioText,
    required this.prompt,
    required this.displayText,
    required this.options,
    required this.correctIndex,
    required this.targetWord,
  });
}

class AudioGuessContentService {
  final DataService _dataService;
  final DailySentenceService _dailySentenceService;

  AudioGuessContentService([
    DataService? dataService,
    DailySentenceService? dailySentenceService,
  ])  : _dataService = dataService ?? DataService(),
        _dailySentenceService = dailySentenceService ?? DailySentenceService();

  Future<List<AudioGuessQuestion>> getEligibleQuestions({
    int maxQuestions = 8,
  }) async {
    final learnedSet = await _getLearnedWordSet();
    if (learnedSet.isEmpty) return [];

    final learnedItems = await _getLearnedItems(learnedSet);
    if (learnedItems.isEmpty) return [];

    final itemMap = <String, VocabularyItem>{};
    for (final item in learnedItems) {
      itemMap[_normalizeWord(item.word)] = item;
    }

    final todaySet = await _getTodayLearnedSet();
    final todayItems = <VocabularyItem>[];
    final pastItems = <VocabularyItem>[];
    for (final item in learnedItems) {
      final normalized = _normalizeWord(item.word);
      if (normalized.isEmpty) continue;
      if (todaySet.contains(normalized)) {
        todayItems.add(item);
      } else {
        pastItems.add(item);
      }
    }

    todayItems.shuffle();
    pastItems.shuffle();

    final questions = <AudioGuessQuestion>[];

    void addWordQuestions(List<VocabularyItem> items) {
      for (final item in items) {
        if (questions.length >= maxQuestions) return;
        final question = _buildWordQuestion(item, learnedItems);
        if (question != null) {
          questions.add(question);
        }
      }
    }

    addWordQuestions(todayItems);
    if (questions.length < maxQuestions) {
      addWordQuestions(pastItems);
    }

    if (questions.length < maxQuestions) {
      final sentenceQuestions = await _buildSentenceQuestions(
        learnedItems,
        learnedSet,
        itemMap,
      );
      for (final question in sentenceQuestions) {
        if (questions.length >= maxQuestions) break;
        questions.add(question);
      }
    }

    return questions;
  }

  AudioGuessQuestion? _buildWordQuestion(
    VocabularyItem target,
    List<VocabularyItem> learnedItems,
  ) {
    final normalizedTarget = _normalizeWord(target.word);
    if (!_isSpeakable(normalizedTarget)) return null;
    final pos = target.pos.trim().toLowerCase();
    if (!_isEligiblePos(pos)) return null;

    final distractors = _buildDistractors(target, learnedItems);
    if (distractors.length < 2) return null;

    final options = <String>[
      target.word,
      ...distractors.take(3),
    ];
    options.shuffle();

    return AudioGuessQuestion(
      mode: AudioGuessMode.word,
      audioText: target.word,
      prompt: 'Which word did you hear?',
      displayText: '',
      options: options,
      correctIndex: options.indexOf(target.word),
      targetWord: target.word,
    );
  }

  Future<List<AudioGuessQuestion>> _buildSentenceQuestions(
    List<VocabularyItem> learnedItems,
    Set<String> learnedSet,
    Map<String, VocabularyItem> itemMap,
  ) async {
    final questions = <AudioGuessQuestion>[];
    final dailySentences = await _dailySentenceService.getDailySentences();
    for (final sentence in dailySentences) {
      final rawText = sentence.text.trim();
      if (rawText.isEmpty) continue;
      if (!_isLearnedOnlySentence(rawText, learnedSet)) continue;
      if (_wordCount(rawText) > _maxSentenceWords) continue;

      final targetChoice = _pickTargetForSentence(rawText, itemMap, learnedItems);
      if (targetChoice == null) continue;

      final options = <String>[
        targetChoice.targetWord,
        ...targetChoice.distractors.take(3),
      ];
      options.shuffle();

      questions.add(
        AudioGuessQuestion(
          mode: AudioGuessMode.sentenceGap,
          audioText: rawText,
          prompt: 'Select the missing word',
          displayText: _maskWord(rawText, targetChoice.targetWord),
          options: options,
          correctIndex: options.indexOf(targetChoice.targetWord),
          targetWord: targetChoice.targetWord,
        ),
      );
    }

    questions.shuffle();
    return questions;
  }

  _TargetChoice? _pickTargetForSentence(
    String sentence,
    Map<String, VocabularyItem> itemMap,
    List<VocabularyItem> learnedItems,
  ) {
    final words = _extractWords(sentence).toSet().toList();
    _TargetChoice? bestChoice;
    double bestScore = -1;

    for (final word in words) {
      if (!_isSpeakable(word)) continue;
      final item = itemMap[word];
      if (item == null) continue;
      final pos = item.pos.trim().toLowerCase();
      if (!_isEligiblePos(pos)) continue;

      final distractors = _buildDistractors(item, learnedItems);
      if (distractors.length < 2) continue;

      final score = _confusableScore(word, distractors.first);
      if (score > bestScore) {
        bestScore = score;
        bestChoice = _TargetChoice(item.word, distractors);
      }
    }

    return bestChoice;
  }

  List<String> _buildDistractors(
    VocabularyItem target,
    List<VocabularyItem> learnedItems,
  ) {
    final normalizedTarget = _normalizeWord(target.word);
    final targetPos = target.pos.trim().toLowerCase();
    final synonyms = target.synonyms.map(_normalizeWord).toSet();
    final antonyms = target.antonyms.map(_normalizeWord).toSet();

    final candidates = <_ScoredWord>[];
    for (final item in learnedItems) {
      final candidateWord = item.word.trim();
      final normalizedCandidate = _normalizeWord(candidateWord);
      if (normalizedCandidate.isEmpty) continue;
      if (normalizedCandidate == normalizedTarget) continue;
      if (!_isSpeakable(normalizedCandidate)) continue;

      final candidatePos = item.pos.trim().toLowerCase();
      if (candidatePos != targetPos) continue;
      if (!_isEligiblePos(candidatePos)) continue;

      final candidateSynonyms = item.synonyms.map(_normalizeWord).toSet();
      final candidateAntonyms = item.antonyms.map(_normalizeWord).toSet();

      if (synonyms.contains(normalizedCandidate) ||
          antonyms.contains(normalizedCandidate) ||
          candidateSynonyms.contains(normalizedTarget) ||
          candidateAntonyms.contains(normalizedTarget)) {
        continue;
      }

      final score = _confusableScore(normalizedTarget, normalizedCandidate);
      final lengthDiff = (normalizedCandidate.length - normalizedTarget.length)
          .abs();
      final hasPhonetic =
          _soundex(normalizedTarget) == _soundex(normalizedCandidate) ||
          _vowelPattern(normalizedTarget) ==
              _vowelPattern(normalizedCandidate) ||
          _syllableCount(normalizedTarget) ==
              _syllableCount(normalizedCandidate);
      final lengthSimilar = lengthDiff <= 2;

      if (!hasPhonetic && !lengthSimilar) continue;

      candidates.add(_ScoredWord(candidateWord, score));
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.map((c) => c.word).toList();
  }

  double _confusableScore(String a, String b) {
    final aSoundex = _soundex(a);
    final bSoundex = _soundex(b);
    final aVowels = _vowelPattern(a);
    final bVowels = _vowelPattern(b);
    final aSyllables = _syllableCount(a);
    final bSyllables = _syllableCount(b);
    final lengthDiff = (a.length - b.length).abs();

    double score = 0;
    if (aSoundex == bSoundex) score += 3;
    if (aVowels == bVowels && aVowels.isNotEmpty) score += 2;
    if (aSyllables == bSyllables) score += 1;
    if (lengthDiff <= 1) {
      score += 1;
    } else if (lengthDiff <= 2) score += 0.5;
    if (a.isNotEmpty && b.isNotEmpty && a[0] == b[0]) score += 0.5;

    final similarity = _similarity(a, b);
    score += similarity * 0.5;

    return score;
  }

  double _similarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final distance = _levenshtein(a, b);
    final maxLen = max(a.length, b.length);
    return (1.0 - (distance / maxLen)).clamp(0.0, 1.0);
  }

  int _levenshtein(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
      (_) => List<int>.filled(b.length + 1, 0),
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
        ].reduce(min);
      }
    }
    return matrix[a.length][b.length];
  }

  String _soundex(String word) {
    if (word.isEmpty) return '';
    final upper = word.toUpperCase();
    final first = upper[0];
    final buffer = StringBuffer(first);
    String lastDigit = _soundexDigit(first);

    for (int i = 1; i < upper.length; i++) {
      final digit = _soundexDigit(upper[i]);
      if (digit == '0') continue;
      if (digit == lastDigit) continue;
      buffer.write(digit);
      lastDigit = digit;
    }

    final code = buffer.toString().padRight(4, '0');
    return code.substring(0, 4);
  }

  String _soundexDigit(String char) {
    switch (char) {
      case 'B':
      case 'F':
      case 'P':
      case 'V':
        return '1';
      case 'C':
      case 'G':
      case 'J':
      case 'K':
      case 'Q':
      case 'S':
      case 'X':
      case 'Z':
        return '2';
      case 'D':
      case 'T':
        return '3';
      case 'L':
        return '4';
      case 'M':
      case 'N':
        return '5';
      case 'R':
        return '6';
      default:
        return '0';
    }
  }

  String _vowelPattern(String word) {
    final buffer = StringBuffer();
    for (final rune in word.runes) {
      final char = String.fromCharCode(rune).toLowerCase();
      if (_isVowel(char)) buffer.write(char);
    }
    return buffer.toString();
  }

  int _syllableCount(String word) {
    int count = 0;
    bool lastWasVowel = false;
    for (final rune in word.runes) {
      final char = String.fromCharCode(rune).toLowerCase();
      final isVowel = _isVowel(char);
      if (isVowel && !lastWasVowel) count++;
      lastWasVowel = isVowel;
    }
    return count;
  }

  bool _isVowel(String char) {
    return 'aeiouy'.contains(char);
  }

  bool _isLearnedOnlySentence(String sentence, Set<String> learnedSet) {
    final words = _extractWords(sentence);
    if (words.isEmpty) return false;
    for (final word in words) {
      if (!learnedSet.contains(word)) return false;
    }
    return true;
  }

  bool _isSpeakable(String word) {
    if (word.isEmpty) return false;
    if (word.length < 3) return false;
    if (RegExp(r'\d').hasMatch(word)) return false;
    return true;
  }

  bool _isEligiblePos(String pos) {
    if (pos.isEmpty) return false;
    final normalized = pos.toLowerCase();
    if (normalized.contains('article') ||
        normalized.contains('determiner') ||
        normalized.contains('preposition') ||
        normalized.contains('conjunction') ||
        normalized.contains('pronoun')) {
      return false;
    }
    return true;
  }

  String _maskWord(String sentence, String word) {
    final escaped = RegExp.escape(word);
    final regex = RegExp('\\b$escaped\\b', caseSensitive: false);
    return sentence.replaceFirst(regex, '____');
  }

  int _wordCount(String sentence) => _extractWords(sentence).length;

  List<String> _extractWords(String sentence) {
    return RegExp(r"[A-Za-z']+")
        .allMatches(sentence)
        .map((match) => _normalizeWord(match.group(0) ?? ''))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  String _normalizeWord(String value) {
    final lower = value.trim().toLowerCase();
    final cleaned = lower.replaceAll(RegExp(r"[^a-z']"), '');
    return cleaned.replaceAll(RegExp(r"^'+|'+$"), '');
  }

  Future<Set<String>> _getLearnedWordSet() async {
    final prefs = await SharedPreferences.getInstance();
    final learnedIds = prefs.getStringList('learned_vocab_ids') ?? [];
    return learnedIds
        .map(_normalizeWord)
        .where((word) => word.isNotEmpty)
        .toSet();
  }

  Future<List<VocabularyItem>> _getLearnedItems(
    Set<String> learnedSet,
  ) async {
    final items = await _dataService.getLearnedVocabularyItems();
    return items
        .where((item) => learnedSet.contains(_normalizeWord(item.word)))
        .toList();
  }

  Future<Set<String>> _getTodayLearnedSet() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateTime.now().toIso8601String().split('T')[0];
    final todayStr = prefs.getString('learned_vocab_$todayKey') ?? '';
    if (todayStr.trim().isNotEmpty) {
      return todayStr
          .split(',')
          .map(_normalizeWord)
          .where((word) => word.isNotEmpty)
          .toSet();
    }

    final todayMaps = await _dataService.getDailyVocabulary();
    return todayMaps
        .map((item) => _normalizeWord((item['word'] ?? '').toString()))
        .where((word) => word.isNotEmpty)
        .toSet();
  }
}

class _ScoredWord {
  final String word;
  final double score;

  const _ScoredWord(this.word, this.score);
}

class _TargetChoice {
  final String targetWord;
  final List<String> distractors;

  const _TargetChoice(this.targetWord, this.distractors);
}

const int _maxSentenceWords = 10;
