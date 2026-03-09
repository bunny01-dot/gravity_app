part of 'data_service.dart';

extension DataServiceLearnedVocab on DataService {
  Future<String> getUserLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to Tamil for backward compatibility if not set
    return prefs.getString('preferred_language') ?? 'Tamil';
  }

  String _normalizeLearnedWordKey(String value) {
    final lower = value.trim().toLowerCase();
    final cleaned = lower.replaceAll(RegExp(r"[^a-z0-9']"), '');
    return cleaned.replaceAll(RegExp(r"^'+|'+$"), '');
  }

  void _addLookupVariants(Set<String> lookup, String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return;

    final lower = trimmed.toLowerCase();
    lookup.add(lower);

    final normalizedWord = _normalizeLearnedWordKey(trimmed);
    if (normalizedWord.isNotEmpty) {
      lookup.add(normalizedWord);
    }

    final asInt = int.tryParse(trimmed);
    if (asInt != null) {
      lookup.add(asInt.toString());
      return;
    }

    final asDouble = double.tryParse(trimmed);
    if (asDouble == null) return;
    if (asDouble == asDouble.roundToDouble()) {
      lookup.add(asDouble.toInt().toString());
    }
  }

  Set<String> _buildLearnedVocabularyLookup(Iterable<String> learnedIds) {
    final lookup = <String>{};
    for (final id in learnedIds) {
      _addLookupVariants(lookup, id);
    }
    return lookup;
  }

  bool _rowMatchesLearnedVocabulary(
    List<dynamic> row,
    Set<String> learnedLookup,
  ) {
    if (learnedLookup.isEmpty) return false;

    final candidates = <String>{};

    final word = row.length > 2 ? row[2].toString().trim() : '';
    if (word.isNotEmpty) {
      _addLookupVariants(candidates, word);
    }

    final serial = row.isNotEmpty ? row[0].toString().trim() : '';
    if (serial.isNotEmpty) {
      _addLookupVariants(candidates, serial);
    }

    if (word.isNotEmpty && row.length > 1) {
      final dayRaw = row[1].toString().trim();
      final dayNumber = int.tryParse(dayRaw.replaceAll(RegExp(r'[^0-9]'), ''));
      if (dayNumber != null && dayNumber > 0) {
        _addLookupVariants(
          candidates,
          'vocab_day${dayNumber}_${word.replaceAll(' ', '_')}',
        );
      }
    }

    for (final candidate in candidates) {
      if (learnedLookup.contains(candidate)) {
        return true;
      }
    }

    return false;
  }

  Future<List<VocabularyItem>> getLearnedVocabularyItems() async {
    // 1. Ensure Data Loaded
    if (_cachedVocabData == null || _cachedVocabData!.isEmpty) {
      await _loadVocabData();
    }
    if (_cachedAntonymMap == null) {
      await _loadAntonymData();
    }
    if (_cachedVocabData == null) return [];

    // 2. Get Learned IDs
    final prefs = await SharedPreferences.getInstance();
    final learnedIds = prefs.getStringList('learned_vocab_ids') ?? [];
    final learnedLookup = _buildLearnedVocabularyLookup(learnedIds);
    final userLanguage = await getUserLanguage();

    List<VocabularyItem> items = [];

    // 3. Filter
    for (var row in _cachedVocabData!) {
      // Schema: 0:Serial, 1:Day, 2:Word, 3:POS, 4:Difficulty, 5:Tamil, 6:Hindi, 7:EngEx, 8:TamEx, 9:HinEx
      if (row.length > 6) {
        String word = row.length > 2 ? row[2].toString().trim() : '';
        final isLearned = _rowMatchesLearnedVocabulary(row, learnedLookup);

        // Strict filter in production, relaxed in development for testing.
        if (isLearned || !AppConfig.isProduction) {
          if (AppConfig.isProduction && !isLearned) continue;

          if (word.isNotEmpty) {
            // Select correct meaning based on language
            String definition = '';
            if (userLanguage == 'Hindi') {
              definition = row.length > 6 ? row[6].toString().trim() : '';
            } else {
              // Default to Tamil
              definition = row.length > 5 ? row[5].toString().trim() : '';
            }

            // Fallback if meaning is empty
            if (definition.isEmpty) {
              // Try the other language or English Example as last resort?
              definition = row.length > 5 ? row[5].toString().trim() : '';
            }

            // Cleanup definition (remove parentheses if needed)
            definition = DataServiceTextUtils.removeParentheses(definition);

            String pos = row.length > 3 ? row[3].toString().trim() : '';

            items.add(
              VocabularyItem(
                id: word,
                word: word,
                definition: definition,
                imageUrl:
                    null, // No imageUrl column in assets/vocabulary.csv currently
                synonyms: row.length > 10
                    ? row[10]
                          .toString()
                          .trim()
                          .split(',')
                          .map((e) => e.trim())
                          .toList()
                    : [],
                antonyms: _cachedAntonymMap?[word.toLowerCase()] ?? [],
                exampleSentence: row.length > 7 ? row[7].toString().trim() : '',
                translation: definition, // Set translation too
                isLearned: true,
                pos: pos,
              ),
            );
          }
        }
      }
    }

    return items;
  }
}
