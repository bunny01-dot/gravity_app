import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/data_service.dart';

class TongueTwisterContentService {
  final DataService _dataService;

  TongueTwisterContentService([DataService? dataService])
      : _dataService = dataService ?? DataService();

  Future<List<String>> getEligiblePhrases() async {
    final learnedSet = await _getLearnedWordSet();
    if (learnedSet.isEmpty) return [];

    final difficulty = await _getUserDifficulty();
    final maxWords = _maxWordsForDifficulty(difficulty);
    final shortMax = 6;

    final exercises = await _dataService.getSpeakingExercises();

    final Map<String, String> unique = {};
    for (final exercise in exercises) {
      final category = (exercise['category'] ?? '').toLowerCase().trim();
      if (category.isEmpty) continue;
      if (category != 'dictation' && category != 'pronunciation') continue;

      final rawText = (exercise['prompt'] ?? exercise['text'] ?? '').trim();
      if (rawText.isEmpty) continue;
      if (_isPlaceholderText(rawText)) continue;

      final words = _extractWords(rawText);
      if (words.isEmpty) continue;
      if (words.length > maxWords) continue;
      if (!_allLearned(words, learnedSet)) continue;

      final key = _normalizeSentenceKey(rawText);
      if (key.isEmpty) continue;
      unique.putIfAbsent(key, () => rawText);
    }

    final short = <String>[];
    final medium = <String>[];
    for (final phrase in unique.values) {
      final wordCount = _extractWords(phrase).length;
      if (wordCount <= shortMax) {
        short.add(phrase);
      } else {
        medium.add(phrase);
      }
    }

    short.sort((a, b) => _extractWords(a).length.compareTo(
          _extractWords(b).length,
        ));
    medium.sort((a, b) => _extractWords(a).length.compareTo(
          _extractWords(b).length,
        ));

    return [...short, ...medium];
  }

  Future<Set<String>> _getLearnedWordSet() async {
    final prefs = await SharedPreferences.getInstance();
    final learnedIds = prefs.getStringList('learned_vocab_ids') ?? [];
    return learnedIds
        .map(_normalizeWord)
        .where((word) => word.isNotEmpty)
        .toSet();
  }

  Future<_TwisterDifficulty> _getUserDifficulty() async {
    final prefs = await SharedPreferences.getInstance();
    final effective = prefs.getString('effective_difficulty_level') ?? '';
    final level = effective.isNotEmpty
        ? effective
        : (prefs.getString('english_proficiency_level') ?? 'Beginner');
    final lower = level.toLowerCase();
    if (lower.contains('advanced')) return _TwisterDifficulty.advanced;
    if (lower.contains('intermediate')) return _TwisterDifficulty.intermediate;
    return _TwisterDifficulty.beginner;
  }

  int _maxWordsForDifficulty(_TwisterDifficulty difficulty) {
    switch (difficulty) {
      case _TwisterDifficulty.beginner:
        return 6;
      case _TwisterDifficulty.intermediate:
        return 10;
      case _TwisterDifficulty.advanced:
        return 12;
    }
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

enum _TwisterDifficulty { beginner, intermediate, advanced }
