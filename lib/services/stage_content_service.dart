import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/models/verb_item.dart';
import 'package:gravity_app/services/day_based_curriculum_service.dart';

/// Level-based content provider for Daily Tasks.
/// Maps stage -> curriculum day and fetches the corresponding items.
class StageContentService {
  static final StageContentService _instance = StageContentService._internal();
  factory StageContentService() => _instance;
  StageContentService._internal();

  final DayBasedCurriculumService _curriculumService =
      DayBasedCurriculumService();

  bool _isInitialized = false;
  Future<void>? _initializeFuture;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initializeFuture != null) {
      await _initializeFuture;
      return;
    }

    final future = _initializeInternal();
    _initializeFuture = future;
    try {
      await future;
    } finally {
      if (identical(_initializeFuture, future)) {
        _initializeFuture = null;
      }
    }
  }

  Future<void> _initializeInternal() async {
    final vocabLoaded = await _curriculumService.loadVocabularyCsv();
    final verbsLoaded = await _curriculumService.loadVerbsCsv();
    if (!vocabLoaded || !verbsLoaded) {
      debugPrint('StageContentService: Warning - curriculum data incomplete.');
    }
    _isInitialized = true;
  }

  void reset() {
    _isInitialized = false;
    _initializeFuture = null;
    _curriculumService.reset();
  }

  Future<int> _getMaxDay() async {
    await initialize();
    int maxVocabDay = 0;
    for (final item in _curriculumService.getAllVocabulary()) {
      if (item.dayNumber > maxVocabDay) {
        maxVocabDay = item.dayNumber;
      }
    }
    int maxVerbDay = 0;
    for (final item in _curriculumService.getAllVerbs()) {
      if (item.dayNumber > maxVerbDay) {
        maxVerbDay = item.dayNumber;
      }
    }
    final maxDay = max(maxVocabDay, maxVerbDay);
    return maxDay > 0 ? maxDay : 1;
  }

  Future<int> resolveDayForStage(int stage) async {
    final safeStage = stage < 1 ? 1 : stage;
    final maxDay = await _getMaxDay();
    if (maxDay <= 0) return safeStage;
    return ((safeStage - 1) % maxDay) + 1;
  }

  Future<List<VocabularyItem>> getVocabularyForStage(int stage) async {
    await initialize();
    final day = await resolveDayForStage(stage);
    return _curriculumService.getDailyVocabularyFor(day);
  }

  Future<List<VerbItem>> getVerbsForStage(int stage) async {
    await initialize();
    final day = await resolveDayForStage(stage);
    return _curriculumService.getDailyVerbsFor(day);
  }

  Future<List<Map<String, String>>> getVocabularyMapsForStage(
    int stage, {
    String preferredLanguage = 'Tamil',
  }) async {
    final items = await getVocabularyForStage(stage);
    return _mapVocabularyItems(items, preferredLanguage);
  }

  Future<List<Map<String, String>>> getVerbMapsForStage(
    int stage, {
    String preferredLanguage = 'Tamil',
  }) async {
    final items = await getVerbsForStage(stage);
    return _mapVerbItems(items, preferredLanguage);
  }

  List<Map<String, String>> _mapVocabularyItems(
    List<VocabularyItem> items,
    String preferredLanguage,
  ) {
    return items.map((item) {
      final preferredMeaning = preferredLanguage == 'Hindi'
          ? item.hindiMeaning
          : item.tamilMeaning;
      final fallbackMeaning = preferredMeaning.isNotEmpty
          ? preferredMeaning
          : (item.tamilMeaning.isNotEmpty
                ? item.tamilMeaning
                : item.hindiMeaning);
      final englishExample = item.englishExample.isNotEmpty
          ? item.englishExample
          : item.exampleSentence;
      final synonyms = item.synonyms.join(', ');
      final localizedSynonyms = item.localizedSynonyms.join(', ');

      return {
        'id': item.id,
        'word': item.word,
        'pos': item.pos,
        'tamil_meaning': item.tamilMeaning,
        'hindi_meaning': item.hindiMeaning,
        'meaning': fallbackMeaning,
        'english_example': englishExample,
        'tamil_example': item.tamilExample,
        'hindi_example': item.hindiExample,
        'synonyms': synonyms,
        'tamil_synonyms': localizedSynonyms,
      };
    }).toList();
  }

  List<Map<String, String>> _mapVerbItems(
    List<VerbItem> items,
    String preferredLanguage,
  ) {
    return items.map((item) {
      final v1 = item.base;
      final v2 = item.past;
      final v3 = item.pastParticiple;
      final v4 = item.present3rd;
      final v5 = item.gerund;
      final forms = [
        v1,
        v2,
        v3,
        v4,
        v5,
      ].where((e) => e.trim().isNotEmpty).join(' / ');
      final meaning = preferredLanguage == 'Hindi'
          ? item.hindiMeaning
          : item.tamilMeaning;
      final englishExample = item.exampleSentences['english'] ?? '';
      final tamilExample = item.exampleSentences['tamil'] ?? '';
      final hindiExample = item.exampleSentences['hindi'] ?? '';

      return {
        'id': item.id,
        'word': v1,
        'v1': v1,
        'v2': v2,
        'v3': v3,
        'v4': v4,
        'v5': v5,
        'forms': forms,
        'tamil_meaning': item.tamilMeaning,
        'hindi_meaning': item.hindiMeaning,
        'meaning': meaning,
        'english_example': englishExample.isNotEmpty
            ? englishExample
            : 'Forms: $forms',
        'tamil_example': tamilExample.isNotEmpty
            ? tamilExample
            : item.tamilMeaning,
        'hindi_example': hindiExample.isNotEmpty
            ? hindiExample
            : item.hindiMeaning,
      };
    }).toList();
  }
}
