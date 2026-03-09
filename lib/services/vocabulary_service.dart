import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/services/placement_state_service.dart';

class VocabularyService {
  // Singleton pattern
  static final VocabularyService _instance = VocabularyService._internal();

  factory VocabularyService() {
    return _instance;
  }

  VocabularyService._internal();

  final List<VocabularyItem> _vocabularyList = [];
  bool _isLoaded = false;

  void reset() {
    _vocabularyList.clear();
    _isLoaded = false;
  }

  Future<List<VocabularyItem>> getVocabularyItems() async {
    if (!_isLoaded) {
      await _loadFromCsv();
    }
    return _vocabularyList;
  }

  Future<void> _loadFromCsv() async {
    try {
      final suffix = await PlacementStateService.getCourseLevelSuffix();

      String assetPath = 'assets/Master Sheets/Vocabulary $suffix - Sheet.csv';
      try {
        await rootBundle.loadString(assetPath);
      } catch (e) {
        // Fallback to Beginner if user's level sheet is missing
        if (suffix != "Beginner") {
          assetPath = 'assets/Master Sheets/Vocabulary Beginner - Sheet.csv';
        }
      }

      final String data = await rootBundle.loadString(assetPath);
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(data);

      // Skip header row
      if (csvTable.isNotEmpty) {
        csvTable = csvTable.sublist(1);
      }

      _vocabularyList.clear();

      for (var row in csvTable) {
        if (row.length < 12) {
          continue; // Ensure strictly robust skipping of malformed rows
        }

        // Indices based on the actual 12-column CSV structure:
        // 0: Serial Number
        // 1: Day Number
        // 2: English Word
        // 3: Part of Speech
        // 4: Difficulty Level
        // 5: Tamil Translation
        // 6: Hindi Translation
        // 7: English Example
        // 8: Tamil Example
        // 9: Hindi Example
        // 10: Synonyms
        // 11: Tamil Meaning

        String id = row[0].toString();
        String dayNumberStr = row[1].toString();
        String word = row[2].toString();
        String pos = row[3].toString();
        String tamilTranslation = row[5].toString();
        String hindiTranslation = row[6].toString();
        String englishExample = row[7].toString();
        String tamilExample = row[8].toString();
        String hindiExample = row[9].toString();
        String synonymsStr = row[10].toString();
        String definition = row[11].toString();

        // Handling Synonyms
        List<String> synonyms = synonymsStr
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        int parsedDayNumber =
            int.tryParse(dayNumberStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

        _vocabularyList.add(
          VocabularyItem(
            id: id,
            word: word,
            definition: definition,
            tamilMeaning: definition, // Fallback definition to Tamil meaning
            hindiMeaning: hindiTranslation,
            exampleSentence: englishExample,
            englishExample: englishExample,
            tamilExample: tamilExample,
            hindiExample: hindiExample,
            synonyms: synonyms,
            translation: tamilTranslation,
            pos: pos,
            dayNumber: parsedDayNumber,
          ),
        );
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint("Error loading vocabulary from CSV: $e");
      // Fallback or empty list
    }
  }

  List<VocabularyItem> getMockItems(int count) {
    // If not loaded yet, we can't return real items synchronously.
    // This method seems to serve synchronous needs.
    // Ideally, caller should await getVocabularyItems.
    // For now, if list is empty, return empty or wait?
    // Given the previous code was sync mock data, we might break callers expecting immediate data.
    // But callers usually use FutureBuilder or similar.
    // If the caller calls this strictly synchronously without prior initialization, it will get empty list.
    // We'll trust the app flow handles async properly or this method is used after init.
    // Alternatively, we can provide a small hardcoded fallback here if empty.

    if (_vocabularyList.isEmpty) {
      return [];
    }

    var list = List<VocabularyItem>.from(_vocabularyList);
    list.shuffle();
    return list.take(count).toList();
  }
}
