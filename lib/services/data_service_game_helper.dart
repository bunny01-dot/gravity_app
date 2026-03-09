part of 'data_service.dart';

extension DataServiceGameHelper on DataService {
  // --- Game Helper ---
  Future<List<Map<String, String>>> getRandomVocabulary(
    int count, {
    bool onlyLearned = true,
  }) async {
    // Ensure loaded
    if (_cachedVocabData == null || _cachedVocabData!.isEmpty) {
      await _loadVocabData();
    }

    if (_cachedVocabData == null || _cachedVocabData!.isEmpty) return [];

    // Get Learned IDs if required
    Set<String> learnedIds = {};
    Set<String> learnedLookup = {};
    if (onlyLearned) {
      final prefs = await SharedPreferences.getInstance();
      final List<String> ids = prefs.getStringList('learned_vocab_ids') ?? [];
      learnedIds = ids.toSet();
      learnedLookup = _buildLearnedVocabularyLookup(ids);
    }

    // Filter valid items (Must have Word + Meaning + Learned Check)
    final userLanguage = await getUserLanguage();

    final validRows = _cachedVocabData!.where((row) {
      if (row.length < 7) {
        return false; // Ensure we have enough columns (up to Hindi)
      }

      // Index 2: Word, Index 3: POS
      final word = row.length > 2 ? row[2].toString().trim() : '';

      // Language Specific Meaning Check
      // Index 5: Tamil, Index 6: Hindi
      String meaning = '';
      if (userLanguage == 'Hindi') {
        meaning = row.length > 6 ? row[6].toString().trim() : '';
      } else {
        meaning = row.length > 5 ? row[5].toString().trim() : '';
      }

      bool isValid = word.isNotEmpty && meaning.isNotEmpty && meaning != '-';
      if (!isValid) return false;

      // STRICT FILTER: If onlyLearned is true, word MUST be in learnedIds
      if (onlyLearned &&
          !learnedIds.contains(word) &&
          !_rowMatchesLearnedVocabulary(row, learnedLookup)) {
        return false;
      }

      return true;
    }).toList();

    if (validRows.isEmpty) return [];

    // Shuffle
    validRows.shuffle();
    final selectedRows = validRows.take(count).toList();

    return selectedRows.map((row) {
      // Map correctly using the schema
      // 0:Serial, 1:Day, 2:Word, 3:POS, 4:Diff, 5:Tamil, 6:Hindi
      final word = row[2].toString();

      String meaning = '';
      if (userLanguage == 'Hindi') {
        meaning = row.length > 6 ? row[6].toString() : '';
      } else {
        meaning = row.length > 5 ? row[5].toString() : '';
      }

      return {
        'word': word,
        'meaning': meaning,
        'id': word, // Using word as ID for matching
      };
    }).toList();
  }

  Future<List<String>> getRandomWords(int count) async {
    // Ensure loaded
    if (_cachedVocabData == null || _cachedVocabData!.isEmpty) {
      await _loadVocabData();
    }

    if (_cachedVocabData == null || _cachedVocabData!.isEmpty) {
      // Fallback
      return ['School', 'Learning', 'English', 'Gravity', 'System'];
    }

    final validWords = <String>[];
    for (var row in _cachedVocabData!) {
      if (row.length > 1) {
        final w = row[1].toString().trim();
        if (w.isNotEmpty && w.length > 2) validWords.add(w);
      }
    }

    if (validWords.isEmpty) return ['Empty', 'List'];

    validWords.shuffle();
    return validWords.take(count).toList();
  }
}
