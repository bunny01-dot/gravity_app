import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/stage_content_service.dart';
import 'package:gravity_app/services/stage_progress_service.dart';

class DictationContentService {
  final DataService _dataService;
  final StageProgressService _stageService;
  final StageContentService _contentService;

  DictationContentService([
    DataService? dataService,
    StageProgressService? stageProgressService,
    StageContentService? stageContentService,
  ])  : _dataService = dataService ?? DataService(),
        _stageService = stageProgressService ?? StageProgressService(),
        _contentService = stageContentService ?? StageContentService();

  Future<List<String>> getEligibleSentences() async {
    final learnedSet = await _getLearnedWordSet();
    if (learnedSet.isEmpty) return [];

    final difficulty = await _getUserDifficulty();
    final maxWords = _maxWordsForDifficulty(difficulty);

    final today = <String, String>{};
    final past = <String, String>{};
    final mastery = <String, String>{};

    final rows = await _loadDailySentenceRows(difficulty);
    final stage = await _stageService.getCurrentStage();
    final currentDay = await _contentService.resolveDayForStage(stage);

    for (final row in rows) {
      if (row.isEmpty) continue;
      final dayLabel = row[0].toString();
      final dayNum = _parseDayNumber(dayLabel);
      if (dayNum == null) continue;
      final text = row.length > 2 ? row[2].toString().trim() : '';
      if (!_isEligibleSentence(text, learnedSet, maxWords)) continue;

      if (dayNum == currentDay) {
        _addUnique(today, text);
      } else if (dayNum < currentDay) {
        _addUnique(past, text);
      }
    }

    final speakingExercises = await _dataService.getSpeakingExercises();
    for (final exercise in speakingExercises) {
      final category = (exercise['category'] ?? '').toLowerCase().trim();
      if (category != 'dictation') continue;
      final text = (exercise['prompt'] ?? exercise['text'] ?? '').trim();
      if (!_isEligibleSentence(text, learnedSet, maxWords)) continue;
      _addUnique(mastery, text);
    }

    final todayList = _sortByWordCount(today.values.toList());
    final pastList = _sortByWordCount(past.values.toList());
    final masteryList = _sortByWordCount(mastery.values.toList());

    return [...todayList, ...pastList, ...masteryList];
  }

  Future<List<List<dynamic>>> _loadDailySentenceRows(
    _DictationDifficulty difficulty,
  ) async {
    final suffix = _difficultyLabel(difficulty);
    String csvData;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final localFile = File('${directory.path}/daily_sentences_$suffix.csv');
      if (await localFile.exists()) {
        csvData = await localFile.readAsString();
      } else {
        final String csvPath =
            'assets/Master Sheets/Daily Sentences - $suffix - Sheet.csv';
        csvData = await rootBundle.loadString(csvPath);
      }
    } catch (_) {
      final String csvPath =
          'assets/Master Sheets/Daily Sentences - $suffix - Sheet.csv';
      csvData = await rootBundle.loadString(csvPath);
    }

    final rows = const CsvToListConverter().convert(csvData, eol: '\n');
    if (rows.isEmpty) return [];

    final firstCell = rows[0][0].toString().toLowerCase();
    if (firstCell.contains('day')) {
      return rows.sublist(1);
    }
    return rows;
  }

  Future<_DictationDifficulty> _getUserDifficulty() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest';

    final effective = prefs.getString('effective_difficulty_level') ?? '';
    final level = effective.isNotEmpty
        ? effective
        : (prefs.getString('english_proficiency_level_$userId') ??
            prefs.getString('english_proficiency_level') ??
            'Beginner');

    final lower = level.toLowerCase();
    if (lower.contains('advanced')) return _DictationDifficulty.advanced;
    if (lower.contains('intermediate')) return _DictationDifficulty.intermediate;
    return _DictationDifficulty.beginner;
  }

  Future<Set<String>> _getLearnedWordSet() async {
    final prefs = await SharedPreferences.getInstance();
    final learnedIds = prefs.getStringList('learned_vocab_ids') ?? [];
    return learnedIds
        .map(_normalizeWord)
        .where((word) => word.isNotEmpty)
        .toSet();
  }

  int _maxWordsForDifficulty(_DictationDifficulty difficulty) {
    switch (difficulty) {
      case _DictationDifficulty.beginner:
        return 8;
      case _DictationDifficulty.intermediate:
        return 12;
      case _DictationDifficulty.advanced:
        return 16;
    }
  }

  String _difficultyLabel(_DictationDifficulty difficulty) {
    switch (difficulty) {
      case _DictationDifficulty.beginner:
        return 'Beginner';
      case _DictationDifficulty.intermediate:
        return 'Intermediate';
      case _DictationDifficulty.advanced:
        return 'Advanced';
    }
  }

  int? _parseDayNumber(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    if (match == null) return null;
    return int.tryParse(match.group(0) ?? '');
  }

  bool _isEligibleSentence(
    String text,
    Set<String> learnedSet,
    int maxWords,
  ) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return false;
    if (_isPlaceholderText(cleaned)) return false;

    final words = _extractWords(cleaned);
    if (words.isEmpty) return false;
    if (words.length > maxWords) return false;
    if (!_allLearned(words, learnedSet)) return false;

    return true;
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

enum _DictationDifficulty { beginner, intermediate, advanced }
