import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HangmanContentService {
  final DataService _dataService;

  HangmanContentService([DataService? dataService])
      : _dataService = dataService ?? DataService();

  Future<List<String>> getEligibleWords({int maxWords = 10}) async {
    final learnedSet = await _getLearnedWordSet();
    if (learnedSet.isEmpty) return [];

    final learnedItems = await _getLearnedItems(learnedSet);
    if (learnedItems.isEmpty) return [];

    final todaySet = await _getTodayLearnedSet();
    final todayWords = <String>[];
    final pastWords = <String>[];
    final seen = <String>{};

    void addWord(String word, {required bool isToday}) {
      final normalized = _normalizeWord(word);
      if (normalized.isEmpty) return;
      if (!_isEligibleWord(word)) return;
      if (seen.contains(normalized)) return;
      seen.add(normalized);
      final upper = normalized.toUpperCase();
      if (isToday) {
        todayWords.add(upper);
      } else {
        pastWords.add(upper);
      }
    }

    for (final item in learnedItems) {
      final normalized = _normalizeWord(item.word);
      if (normalized.isEmpty) continue;
      final isToday = todaySet.contains(normalized);
      addWord(item.word, isToday: isToday);
    }

    todayWords.shuffle();
    pastWords.shuffle();

    final combined = <String>[];
    combined.addAll(todayWords);
    combined.addAll(pastWords);

    if (combined.length <= maxWords) return combined;
    return combined.take(maxWords).toList();
  }

  bool _isEligibleWord(String word) {
    final trimmed = word.trim();
    if (trimmed.length < 3) return false;
    return RegExp(r'^[A-Za-z]+$').hasMatch(trimmed);
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
