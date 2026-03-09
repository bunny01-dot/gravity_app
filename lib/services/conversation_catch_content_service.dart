import 'dart:math';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConversationCatchQuestion {
  final List<String> dialogue;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String answer;
  final String questionType;

  const ConversationCatchQuestion({
    required this.dialogue,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.answer,
    required this.questionType,
  });
}

class ConversationCatchContentService {
  final DataService _dataService;

  ConversationCatchContentService([DataService? dataService])
      : _dataService = dataService ?? DataService();

  Future<List<ConversationCatchQuestion>> getEligibleConversations({
    int maxConversations = 6,
  }) async {
    final learnedSet = await _getLearnedWordSet();
    if (learnedSet.isEmpty) return [];

    final learnedItems = await _getLearnedItems(learnedSet);
    final wordMap = <String, VocabularyItem>{};
    for (final item in learnedItems) {
      wordMap[_normalizeWord(item.word)] = item;
    }

    final exercises = await _dataService.getListeningExercises();
    if (exercises.isEmpty) return [];

    final seeds = <_ConversationSeed>[];
    for (final exercise in exercises) {
      final sp1 = (exercise['sp1'] ?? '').toString().trim();
      final sp2 = (exercise['sp2'] ?? '').toString().trim();
      final question = (exercise['question'] ?? '').toString().trim();
      final answer = (exercise['answer'] ?? '').toString().trim();
      if (question.isEmpty || answer.isEmpty) continue;

      final dialogue = _parseDialogue(sp1, sp2);
      if (dialogue.length < 2 || dialogue.length > 5) continue;
      if (!_isDialogueLearnedOnly(dialogue, learnedSet)) continue;
      if (!_isAnswerLearnedOnly(answer, learnedSet)) continue;

      final questionType = _questionType(question);
      seeds.add(
        _ConversationSeed(
          dialogue: dialogue,
          question: question,
          answer: answer,
          questionType: questionType,
        ),
      );
    }

    if (seeds.isEmpty) return [];

    final answerPool = seeds.map((seed) => seed.answer).toList();
    final candidates = <_ConversationCandidate>[];
    for (final seed in seeds) {
      final options = _buildOptions(
        seed.answer,
        seed.question,
        answerPool,
        learnedItems,
        wordMap,
      );
      if (options.length < 3) continue;

      final shuffleSeed = seed.dialogue.join(' ').hashCode & 0x7fffffff;
      _stableShuffle(options, shuffleSeed);
      final correctIndex = options.indexOf(seed.answer);
      if (correctIndex < 0) continue;

      candidates.add(
        _ConversationCandidate(
          dialogue: seed.dialogue,
          question: seed.question,
          options: options,
          correctIndex: correctIndex,
          answer: seed.answer,
          questionType: seed.questionType,
        ),
      );
    }

    candidates.shuffle();
    final selected = candidates.take(maxConversations).toList();
    return selected
        .map(
          (candidate) => ConversationCatchQuestion(
            dialogue: candidate.dialogue,
            question: candidate.question,
            options: candidate.options,
            correctIndex: candidate.correctIndex,
            answer: candidate.answer,
            questionType: candidate.questionType,
          ),
        )
        .toList();
  }

  List<String> _parseDialogue(String sp1, String sp2) {
    final lines = <String>[];
    lines.addAll(_splitTurns(sp1));
    lines.addAll(_splitTurns(sp2));
    return lines
        .map(_cleanDialogueLine)
        .where((line) => line.isNotEmpty)
        .toList();
  }

  List<String> _splitTurns(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return [];
    final matches = RegExp(r'[A-Za-z .]+:').allMatches(trimmed).toList();
    if (matches.length <= 1) return [trimmed];

    final segments = <String>[];
    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = i == matches.length - 1 ? trimmed.length : matches[i + 1].start;
      final segment = trimmed.substring(start, end).trim();
      if (segment.isNotEmpty) segments.add(segment);
    }
    return segments;
  }

  String _cleanDialogueLine(String line) {
    return line.replaceAll('"', '').replaceAll(""", '').replaceAll(""", '').trim();
  }

  bool _isDialogueLearnedOnly(List<String> dialogue, Set<String> learnedSet) {
    for (final line in dialogue) {
      final content = line.replaceFirst(RegExp(r'^[A-Za-z .]+:\s*'), '');
      final words = _extractWords(content);
      if (words.isEmpty) return false;
      if (words.length > _maxWordsPerLine) return false;
      if (!_allLearned(words, learnedSet)) return false;
    }
    return true;
  }

  bool _isAnswerLearnedOnly(String answer, Set<String> learnedSet) {
    final words = _extractWords(answer);
    if (words.isEmpty) return false;
    if (!_allLearned(words, learnedSet)) return false;
    return true;
  }

  List<String> _buildOptions(
    String answer,
    String question,
    List<String> answerPool,
    List<VocabularyItem> learnedItems,
    Map<String, VocabularyItem> wordMap,
  ) {
    final options = <String>[answer];
    final answerWordCount = _extractWords(answer).length;
    final isNumeric = _containsNumber(answer);
    final isTime = _containsTime(answer);

    final answerNormalized = _normalizeWord(answer);
    final answerItem = answerWordCount == 1 ? wordMap[answerNormalized] : null;
    final answerPos = answerItem?.pos.trim().toLowerCase() ?? '';

    final candidatePool = <String>{};
    for (final candidate in answerPool) {
      if (candidate == answer) continue;
      if (_extractWords(candidate).length != answerWordCount) continue;
      if (isNumeric && !_containsNumber(candidate)) continue;
      if (isTime && !_containsTime(candidate)) continue;
      candidatePool.add(candidate);
    }

    if (candidatePool.length < 2 && answerWordCount == 1 && answerPos.isNotEmpty) {
      final distractors = _buildWordDistractors(
        answerItem!,
        learnedItems,
      );
      candidatePool.addAll(distractors);
    }

    final candidates = candidatePool.toList();
    final seed = (answer + question).hashCode & 0x7fffffff;
    _stableShuffle(candidates, seed);

    for (final candidate in candidates) {
      if (options.length >= 4) break;
      if (candidate == answer) continue;
      options.add(candidate);
    }

    return options;
  }

  List<String> _buildWordDistractors(
    VocabularyItem target,
    List<VocabularyItem> learnedItems,
  ) {
    final normalizedTarget = _normalizeWord(target.word);
    final targetPos = target.pos.trim().toLowerCase();
    if (targetPos.isEmpty) return [];

    final synonyms = target.synonyms.map(_normalizeWord).toSet();
    final antonyms = target.antonyms.map(_normalizeWord).toSet();

    final scored = <_ScoredWord>[];
    for (final item in learnedItems) {
      final candidate = _normalizeWord(item.word);
      if (candidate.isEmpty || candidate == normalizedTarget) continue;
      if (item.pos.trim().toLowerCase() != targetPos) continue;
      if (_containsNumber(item.word)) continue;
      if (synonyms.contains(candidate) || antonyms.contains(candidate)) continue;

      final score = _confusableScore(normalizedTarget, candidate);
      if (score < 2) continue;
      scored.add(_ScoredWord(item.word, score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((item) => item.word).toList();
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
    } else if (lengthDiff <= 2) {
      score += 0.5;
    }

    return score;
  }

  String _questionType(String question) {
    final lower = question.toLowerCase();
    if (lower.startsWith('why')) return 'Speaker intent';
    if (lower.contains('what happens next') || lower.contains('next')) {
      return 'Sequence';
    }
    if (lower.startsWith('what') || lower.startsWith('where') || lower.startsWith('when')) {
      return 'Detail';
    }
    return 'Meaning';
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

  bool _containsNumber(String text) {
    return RegExp(r'\d').hasMatch(text);
  }

  bool _containsTime(String text) {
    return RegExp(r'\d{1,2}[:.]\d{2}').hasMatch(text);
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
}

class _ConversationCandidate {
  final List<String> dialogue;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String answer;
  final String questionType;

  const _ConversationCandidate({
    required this.dialogue,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.answer,
    required this.questionType,
  });
}

class _ConversationSeed {
  final List<String> dialogue;
  final String question;
  final String answer;
  final String questionType;

  const _ConversationSeed({
    required this.dialogue,
    required this.question,
    required this.answer,
    required this.questionType,
  });
}

class _ScoredWord {
  final String word;
  final double score;

  const _ScoredWord(this.word, this.score);
}

const int _maxWordsPerLine = 14;

