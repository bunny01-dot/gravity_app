import 'dart:convert';

import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

import 'package:csv/csv.dart';

import 'package:flutter/foundation.dart';

import 'package:gravity_app/models/vocabulary_item.dart';

import 'package:gravity_app/models/verb_item.dart';

import 'package:gravity_app/services/data_service_text_utils.dart';

import 'package:gravity_app/services/placement_state_service.dart';

import 'package:http/http.dart' as http;

import 'package:path_provider/path_provider.dart';

class DayBasedCurriculumService {
  static final DayBasedCurriculumService _instance =
      DayBasedCurriculumService._internal();

  factory DayBasedCurriculumService() => _instance;

  DayBasedCurriculumService._internal();

  // State flags

  bool _isVocabLoaded = false;

  bool _isVerbsLoaded = false;
  String? _loadedVocabSuffix;
  String? _loadedVerbsSuffix;
  Future<bool>? _vocabLoadFuture;
  Future<bool>? _verbsLoadFuture;

  // Data stores

  List<VocabularyItem> _vocabularyItems = [];

  List<VerbItem> _verbItems = [];

  void reset() {
    _isVocabLoaded = false;

    _isVerbsLoaded = false;
    _loadedVocabSuffix = null;
    _loadedVerbsSuffix = null;
    _vocabLoadFuture = null;
    _verbsLoadFuture = null;

    _vocabularyItems.clear();

    _verbItems.clear();
  }

  void resetData() {
    reset();
  }

  String getVerificationReport() {
    return ' Curriculum Data Status:\n'
        '- Vocabulary: ${_vocabularyItems.length} items loaded\n'
        '- Verbs: ${_verbItems.length} items loaded\n'
        '- Ready: ${(_isVocabLoaded && _isVerbsLoaded) ? "YES" : "NO"}';
  }

  /// Initialize and load all data

  Future<bool> initialize() async {
    debugPrint(
      ' Initializing DayBasedCurriculumService (Master Sheet Mode)...',
    );

    bool vocabSuccess = await loadVocabularyCsv();

    bool verbsSuccess = await loadVerbsCsv();

    if (!vocabSuccess || !verbsSuccess) {
      debugPrint('[WARN] Warning: Some curriculum data failed to load.');
    }

    return vocabSuccess && verbsSuccess;
  }

  /// Load and validate vocabulary CSV from Local Assets or Cache

  Future<bool> loadVocabularyCsv() async {
    final suffix = await _getLevelSuffix();
    if (_isVocabLoaded && _loadedVocabSuffix == suffix) return true;

    if (_vocabLoadFuture != null) {
      final loaded = await _vocabLoadFuture!;
      if (loaded && _loadedVocabSuffix == suffix) {
        return true;
      }
    }

    final future = _loadVocabularyCsvInternal(suffix);
    _vocabLoadFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_vocabLoadFuture, future)) {
        _vocabLoadFuture = null;
      }
    }
  }

  Future<bool> _loadVocabularyCsvInternal(String suffix) async {
    try {
      String csvString;

      // 1. Check Local Cache (Downloaded from Sheet)

      final directory = await getApplicationDocumentsDirectory();

      final file = File('${directory.path}/vocabulary_$suffix.csv');

      if (await file.exists()) {
        debugPrint(' Loading Vocabulary from LOCAL CACHE ($suffix)');

        csvString = await file.readAsString();
      } else {
        // 2. Fallback to Assets

        debugPrint(' Loading Vocabulary from ASSETS ($suffix)');

        String assetPath =
            'assets/Master Sheets/Vocabulary $suffix - Sheet.csv';

        csvString = await rootBundle.loadString(assetPath);
      }

      List<List<dynamic>> csvTable = const CsvToListConverter().convert(
        csvString,
      );

      if (csvTable.isNotEmpty) {
        // Check for header and skip it

        final firstCell = csvTable[0][0].toString().toLowerCase();

        if (firstCell.contains('serial') || firstCell.contains('day')) {
          csvTable.removeAt(0);
        }

        _vocabularyItems = _parseVocabularyCsv(csvTable);

        _isVocabLoaded = true;
        _loadedVocabSuffix = suffix;

        debugPrint('OK: Loaded ${_vocabularyItems.length} vocabulary items');

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error: Error loading Vocabulary CSV: $e');
      _loadedVocabSuffix = null;

      return false;
    }
  }

  /// Load and validate verbs CSV from Local Assets or Cache

  Future<bool> loadVerbsCsv() async {
    final suffix = await _getLevelSuffix();
    if (_isVerbsLoaded && _loadedVerbsSuffix == suffix) return true;

    if (_verbsLoadFuture != null) {
      final loaded = await _verbsLoadFuture!;
      if (loaded && _loadedVerbsSuffix == suffix) {
        return true;
      }
    }

    final future = _loadVerbsCsvInternal(suffix);
    _verbsLoadFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_verbsLoadFuture, future)) {
        _verbsLoadFuture = null;
      }
    }
  }

  Future<bool> _loadVerbsCsvInternal(String suffix) async {
    try {
      // 1. Try Local Cache (User Downloaded)

      final directory = await getApplicationDocumentsDirectory();

      final localFile = File('${directory.path}/verbs_$suffix.csv');

      String csvString;

      if (await localFile.exists()) {
        debugPrint(' Loading verbs from LOCAL CACHE: ${localFile.path}');

        csvString = await localFile.readAsString();
      } else {
        // 2. Fallback to Asset

        final assetPath = 'assets/Master Sheets/Verb Forms $suffix - Sheet.csv';

        debugPrint(' Loading verbs from ASSET: $assetPath');

        csvString = await rootBundle.loadString(assetPath);
      }

      List<List<dynamic>> csvData = const CsvToListConverter().convert(
        csvString,
      );

      _verbItems = _parseVerbsCsv(csvData);

      _isVerbsLoaded = true;
      _loadedVerbsSuffix = suffix;

      debugPrint(
        'OK: Verbs CSV loaded successfully: ${_verbItems.length} items',
      );

      return true;
    } catch (e) {
      debugPrint('Error: Error loading Verbs CSV: $e');
      _loadedVerbsSuffix = null;

      return false;
    }
  }

  /// Force download latest Verbs CSV from Google Sheets

  Future<void> fetchLatestVerbsFromCloud() async {
    try {
      final suffix = await _getLevelSuffix();

      String url = '';

      if (suffix == 'Advanced') {
        url =
            'https://docs.google.com/spreadsheets/d/e/2PACX-1vRavB16Va8faVuXAK3IaHiCbeOmFoSRkqhqg-DbDJn2VRNIzhq1kT8uX8gknTylrm-zYy4O_9ALQxt9/pub?output=csv';
      } else if (suffix == 'Intermediate') {
        url =
            'https://docs.google.com/spreadsheets/d/e/2PACX-1vRgLhNztx7-IjstKz4CTBJ9sfbhw5JV8g5yp7sRxtpT_SzGlYf7B28VY0zPn5k5_evupUobQ0iFR_Nz/pub?output=csv';
      } else {
        url =
            'https://docs.google.com/spreadsheets/d/e/2PACX-1vTZiFaFrTnFpoILXz_jm4-XUXigcB1NW7V1HGA-S6UwC-60Fbyfx8jZf2u8hDIcKlgHuVImjucpxAEc/pub?output=csv';
      }

      debugPrint(' Downloading verbs from: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final csvString = utf8.decode(response.bodyBytes);

        final directory = await getApplicationDocumentsDirectory();

        final file = File('${directory.path}/verbs_$suffix.csv');

        await file.writeAsString(csvString);

        debugPrint('OK: Saved verbs to: ${file.path}');

        // Clear memory

        _isVerbsLoaded = false;
        _loadedVerbsSuffix = null;
        _verbsLoadFuture = null;

        _verbItems.clear();
      } else {
        debugPrint('Error: Failed to download verbs: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error: Error downloading verbs: $e');
    }
  }

  /// Force download latest Vocabulary CSV from Google Sheets

  Future<void> fetchLatestVocabularyFromCloud() async {
    try {
      final suffix = await _getLevelSuffix();

      String url = '';

      if (suffix == 'Advanced') {
        url =
            'https://docs.google.com/spreadsheets/d/e/2PACX-1vQ6hRMDTnZ8-ZQ9AbTappG9mOBnR7RgfZypI-ksDGr0r_nRkIyzFYBGDjB_A_xCWBge0z3VUIPSLtRa/pub?output=csv';
      } else if (suffix == 'Intermediate') {
        url =
            'https://docs.google.com/spreadsheets/d/e/2PACX-1vT1ZunpvOlzHf_xDY0mPINp_Sa1XmcdFhyGc9Rrb0RIq5kGf5wKNeM1sjtK5M865durEfMg4cgUkjrf/pub?output=csv';
      } else {
        url =
            'https://docs.google.com/spreadsheets/d/e/2PACX-1vQy59lqvW_5qG9sRG8PSSl0-JSoHPiZXZNlyFq-5jKeHcOT4PrjoU-YP43PKjf-8wBOtwAEQXb8TYOk/pub?output=csv';
      }

      debugPrint(' Downloading vocabulary from: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final csvString = utf8.decode(response.bodyBytes);

        final directory = await getApplicationDocumentsDirectory();

        final file = File('${directory.path}/vocabulary_$suffix.csv');

        await file.writeAsString(csvString);

        debugPrint('OK: Saved vocabulary to: ${file.path}');

        // Clear memory

        _isVocabLoaded = false;
        _loadedVocabSuffix = null;
        _vocabLoadFuture = null;

        _vocabularyItems.clear();
      } else {
        debugPrint(
          'Error: Failed to download vocabulary: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error: Error downloading vocabulary: $e');
    }
  }

  Future<String> _getLevelSuffix() async {
    return PlacementStateService.getCourseLevelSuffix();
  }

  // --- Vocabulary Parser ---

  List<VocabularyItem> _parseVocabularyCsv(List<List<dynamic>> csvData) {
    if (csvData.isEmpty) return [];

    List<VocabularyItem> items = [];

    for (var row in csvData) {
      if (row.length < 5) continue;

      try {
        // Indices based on Vocabulary sheet structure:

        // 0: Serial, 1: Day, 2: Word, 3: POS, 4: Level, 5: Tamil, 6: Hindi, 7: English Ex, 8: Tamil Ex, 9: Hindi Ex

        String dayStr = row.length > 1 ? row[1].toString().trim() : '';

        int dayNum =
            int.tryParse(dayStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

        String word = row.length > 2 ? row[2].toString().trim() : '';

        if (word.isEmpty) continue;

        String type = row.length > 3 ? row[3].toString().trim() : 'n/a';

        String tamilTranslation = DataServiceTextUtils.repairMojibake(
          row.length > 5 ? row[5].toString().trim() : '',
        );

        String hindiTranslation = DataServiceTextUtils.repairMojibake(
          row.length > 6 ? row[6].toString().trim() : '',
        );

        String englishExample = row.length > 7 ? row[7].toString().trim() : '';

        String tamilExample = DataServiceTextUtils.repairMojibake(
          row.length > 8 ? row[8].toString().trim() : '',
        );

        String hindiExample = DataServiceTextUtils.repairMojibake(
          row.length > 9 ? row[9].toString().trim() : '',
        );

        String synonymsRaw = row.length > 10 ? row[10].toString().trim() : '';

        String localizedSynonymsRaw = DataServiceTextUtils.repairMojibake(
          row.length > 11 ? row[11].toString().trim() : '',
        );

        final List<String> synonyms = synonymsRaw.isNotEmpty
            ? synonymsRaw
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : <String>[];

        final List<String> localizedSynonyms = localizedSynonymsRaw.isNotEmpty
            ? localizedSynonymsRaw
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : <String>[];

        items.add(
          VocabularyItem(
            id: 'vocab_day${dayNum}_${word.replaceAll(" ", "_")}',

            word: word,

            definition: tamilTranslation, // Using Tamil as definition for now

            tamilMeaning: tamilTranslation,

            hindiMeaning: hindiTranslation,

            exampleSentence: englishExample,

            englishExample: englishExample,

            tamilExample: tamilExample,

            hindiExample: hindiExample,

            synonyms: synonyms,

            localizedSynonyms: localizedSynonyms,

            pos: type,

            dayNumber: dayNum,
          ),
        );
      } catch (e) {
        // Skip malformed rows
      }
    }

    return items;
  }

  // --- Verbs Parser ---

  List<VerbItem> _parseVerbsCsv(List<List<dynamic>> csvData) {
    if (csvData.isEmpty) return [];

    List<VerbItem> items = [];

    for (int rowIndex = 0; rowIndex < csvData.length; rowIndex++) {
      List<dynamic> row = csvData[rowIndex];

      if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
        continue;
      }

      try {
        // Col 0: English (V1/V2/V3)

        String englishStr = row.isNotEmpty ? row[0].toString().trim() : '';

        if (englishStr.isEmpty || englishStr.toLowerCase().contains('v1')) {
          continue;
        }

        // Col 1: Day

        String dayStr = row.length > 1 ? row[1].toString().trim() : '';

        int dayNumber =
            int.tryParse(dayStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

        if (dayNumber < 1 || dayNumber > 90) continue;

        List<String> verbForms = englishStr
            .split('/')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        if (verbForms.isEmpty) continue;

        String v1 = verbForms.isNotEmpty ? verbForms[0] : '';

        String v2 = verbForms.length > 1 ? verbForms[1] : v1;

        String v3 = verbForms.length > 2 ? verbForms[2] : v1;

        // Col 3: Tamil Meaning

        String tamilMeaning = DataServiceTextUtils.repairMojibake(
          row.length > 3 ? row[3].toString().trim() : '',
        );

        // Col 4: Hindi Meaning

        String hindiMeaning = DataServiceTextUtils.repairMojibake(
          row.length > 4 ? row[4].toString().trim() : '',
        );

        // Col 5: English Example

        String englishExample = row.length > 5 ? row[5].toString().trim() : '';

        // Col 6: Tamil Example

        String tamilExample = DataServiceTextUtils.repairMojibake(
          row.length > 6 ? row[6].toString().trim() : '',
        );

        // Col 7: Hindi Example

        String hindiExample = DataServiceTextUtils.repairMojibake(
          row.length > 7 ? row[7].toString().trim() : '',
        );

        String id = 'verb_day${dayNumber}_${v1.replaceAll(" ", "_")}';

        items.add(
          VerbItem(
            id: id,

            base: v1,

            past: v2,

            pastParticiple: v3,

            present3rd: '${v1}s',

            gerund: '${v1}ing',

            tamilMeaning: tamilMeaning,

            hindiMeaning: hindiMeaning,

            exampleSentences: {
              'english': englishExample,

              'tamil': tamilExample,

              'hindi': hindiExample,
            },

            dayNumber: dayNumber,
          ),
        );
      } catch (e) {
        debugPrint('[WARN] Error parsing verb row $rowIndex: $e');
      }
    }

    return items;
  }

  /// Get vocabulary for a specific day (1-90)

  List<VocabularyItem> getDailyVocabularyFor(int day) {
    if (!_isVocabLoaded) return [];

    return _vocabularyItems.where((item) => item.dayNumber == day).toList();
  }

  /// Get verbs for a specific day (1-90)

  List<VerbItem> getDailyVerbsFor(int day) {
    if (!_isVerbsLoaded) return [];

    return _verbItems.where((item) => item.dayNumber == day).toList();
  }

  List<VocabularyItem> getAllVocabulary() => _vocabularyItems;

  List<VerbItem> getAllVerbs() => _verbItems;
}
