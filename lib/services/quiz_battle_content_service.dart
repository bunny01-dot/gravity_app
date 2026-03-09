import 'dart:math';
import 'package:gravity_app/features/daily_sentences/daily_sentence_service.dart';
import 'package:gravity_app/models/verb_item.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizBattleQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String correctAnswer;
  final String type;

  const QuizBattleQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.correctAnswer,
    required this.type,
  });
}

class QuizBattleContentService {
  final DataService _dataService;
  final DailySentenceService _dailySentenceService;

  QuizBattleContentService([
    DataService? dataService,
    DailySentenceService? dailySentenceService,
  ])  : _dataService = dataService ?? DataService(),
        _dailySentenceService = dailySentenceService ?? DailySentenceService();

  Future<List<QuizBattleQuestion>> getEligibleQuestions({
    int maxQuestions = 200,
  }) async {
    final learnedSet = await _getLearnedWordSet();
    if (learnedSet.isEmpty) return [];

    final learnedItems = await _dataService.getLearnedVocabularyItems();
    if (learnedItems.isEmpty) return [];

    final learnedVerbs = await _dataService.getLearnedVerbItems();
    final wordMap = <String, VocabularyItem>{};
    final posMap = <String, List<VocabularyItem>>{};
    final definitionPool = <VocabularyItem>[];

    for (final item in learnedItems) {
      final normalized = _normalizeWord(item.word);
      if (normalized.isEmpty) continue;
      wordMap[normalized] = item;
      final pos = item.pos.trim().toLowerCase();
      posMap.putIfAbsent(pos, () => []).add(item);
      if (item.definition.trim().isNotEmpty) {
        definitionPool.add(item);
      }
    }

    final questions = <QuizBattleQuestion>[];
    final seen = <String>{};

    void addQuestion(QuizBattleQuestion question) {
      final key = '${question.question}|${question.options.join('|')}';
      if (seen.contains(key)) return;
      seen.add(key);
      questions.add(question);
    }

    for (final item in definitionPool) {
      final questionText = 'Which word means: ${item.definition}?';
      final options = _buildWordOptions(item, learnedItems, posMap);
      if (options.length < 3) continue;
      final ordered = _stableOptions(options, questionText);
      addQuestion(
        QuizBattleQuestion(
          question: questionText,
          options: ordered,
          correctIndex: ordered.indexOf(item.word),
          correctAnswer: item.word,
          type: 'meaning',
        ),
      );
    }

    for (final item in definitionPool) {
      final questionText = "What does '${item.word}' mean?";
      final options = _buildDefinitionOptions(item, definitionPool);
      if (options.length < 3) continue;
      final ordered = _stableOptions(options, questionText);
      addQuestion(
        QuizBattleQuestion(
          question: questionText,
          options: ordered,
          correctIndex: ordered.indexOf(item.definition),
          correctAnswer: item.definition,
          type: 'definition',
        ),
      );
    }

    final sentenceQuestions = await _buildSentenceQuestions(
      learnedSet,
      learnedItems,
      wordMap,
      posMap,
    );
    for (final question in sentenceQuestions) {
      addQuestion(question);
    }

    final grammarQuestions = _buildGrammarQuestions(learnedVerbs);
    for (final question in grammarQuestions) {
      addQuestion(question);
    }

    if (questions.isEmpty) return [];
    if (questions.length <= maxQuestions) return questions;
    return questions.take(maxQuestions).toList();
  }

  List<String> _buildWordOptions(
    VocabularyItem correct,
    List<VocabularyItem> allItems,
    Map<String, List<VocabularyItem>> posMap,
  ) {
    final options = <String>{};
    options.add(correct.word);

    final pos = correct.pos.trim().toLowerCase();
    final pool = pos.isEmpty
        ? List<VocabularyItem>.from(allItems)
        : List<VocabularyItem>.from(posMap[pos] ?? allItems);
    pool.shuffle();

    for (final item in pool) {
      if (options.length >= 4) break;
      if (item.word == correct.word) continue;
      options.add(item.word);
    }

    if (options.length < 3) {
      for (final item in allItems) {
        if (options.length >= 3) break;
        if (item.word == correct.word) continue;
        options.add(item.word);
      }
    }

    return options.toList();
  }

  List<String> _buildDefinitionOptions(
    VocabularyItem correct,
    List<VocabularyItem> pool,
  ) {
    final options = <String>{};
    options.add(correct.definition);
    final shuffled = List<VocabularyItem>.from(pool)..shuffle();

    for (final item in shuffled) {
      if (options.length >= 4) break;
      if (item.word == correct.word) continue;
      if (item.definition.trim().isEmpty) continue;
      options.add(item.definition);
    }

    return options.toList();
  }

  Future<List<QuizBattleQuestion>> _buildSentenceQuestions(
    Set<String> learnedSet,
    List<VocabularyItem> learnedItems,
    Map<String, VocabularyItem> wordMap,
    Map<String, List<VocabularyItem>> posMap,
  ) async {
    final questions = <QuizBattleQuestion>[];
    final dailySentences = await _dailySentenceService.getDailySentences();
    for (final sentence in dailySentences) {
      final rawText = sentence.text.trim();
      if (rawText.isEmpty) continue;
      if (!_isLearnedOnlySentence(rawText, learnedSet)) continue;
      if (_wordCount(rawText) > 12) continue;

      final target = _pickTargetWord(rawText, wordMap);
      if (target == null) continue;

      final item = wordMap[_normalizeWord(target)];
      if (item == null) continue;

      final options = _buildWordOptions(item, learnedItems, posMap);
      if (options.length < 3) continue;
      final questionText = 'Complete the sentence:';
      final masked = _maskWord(rawText, target);
      final ordered = _stableOptions(options, masked);

      questions.add(
        QuizBattleQuestion(
          question: '$questionText\n$masked',
          options: ordered,
          correctIndex: ordered.indexOf(item.word),
          correctAnswer: item.word,
          type: 'sentence',
        ),
      );
    }

    return questions;
  }

  String? _pickTargetWord(
    String sentence,
    Map<String, VocabularyItem> wordMap,
  ) {
    final words = _extractWords(sentence)
        .where((word) => word.length >= 3)
        .where(wordMap.containsKey)
        .toList();
    if (words.isEmpty) return null;

    words.sort((a, b) {
      if (a.length != b.length) return b.length.compareTo(a.length);
      return a.compareTo(b);
    });
    return words.first;
  }

  List<QuizBattleQuestion> _buildGrammarQuestions(List<VerbItem> verbs) {
    final questions = <QuizBattleQuestion>[];
    for (final verb in verbs) {
      final base = verb.base.trim();
      final past = verb.past.trim();
      final present3rd = verb.present3rd.trim();
      final gerund = verb.gerund.trim();
      if (base.isEmpty || past.isEmpty) continue;

      final options = <String>{past, base, gerund};
      if (verb.pastParticiple.trim().isNotEmpty) {
        options.add(verb.pastParticiple.trim());
      }
      if (options.length < 3) continue;

      final questionText = "Choose the past tense of '$base'.";
      final ordered = _stableOptions(options.toList(), questionText);
      questions.add(
        QuizBattleQuestion(
          question: questionText,
          options: ordered,
          correctIndex: ordered.indexOf(past),
          correctAnswer: past,
          type: 'grammar',
        ),
      );

      if (present3rd.isNotEmpty) {
        final presentOptions = <String>{present3rd, base, gerund};
        if (past.isNotEmpty) presentOptions.add(past);
        if (presentOptions.length >= 3) {
          final presentQuestion =
              "Choose the correct form: He ___ every day.";
          final presentOrdered = _stableOptions(
            presentOptions.toList(),
            '$presentQuestion$base',
          );
          questions.add(
            QuizBattleQuestion(
              question: presentQuestion,
              options: presentOrdered,
              correctIndex: presentOrdered.indexOf(present3rd),
              correctAnswer: present3rd,
              type: 'grammar',
            ),
          );
        }
      }
    }
    return questions;
  }

  bool _isLearnedOnlySentence(String sentence, Set<String> learnedSet) {
    final words = _extractWords(sentence);
    if (words.isEmpty) return false;
    for (final word in words) {
      if (!learnedSet.contains(word)) return false;
    }
    return true;
  }

  String _maskWord(String sentence, String target) {
    final escaped = RegExp.escape(target);
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

  List<String> _stableOptions(List<String> options, String seedText) {
    final list = List<String>.from(options);
    final seed = seedText.hashCode & 0x7fffffff;
    _stableShuffle(list, seed);
    return list;
  }

  void _stableShuffle(List<String> list, int seed) {
    final random = Random(seed);
    for (int i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }

  String _normalizeWord(String value) {
    final lower = value.trim().toLowerCase();
    return lower.replaceAll(RegExp(r"[^a-z']"), '');
  }

  Future<Set<String>> _getLearnedWordSet() async {
    final prefs = await SharedPreferences.getInstance();
    final learnedIds = prefs.getStringList('learned_vocab_ids') ?? [];
    return learnedIds
        .map(_normalizeWord)
        .where((word) => word.isNotEmpty)
        .toSet();
  }
}
