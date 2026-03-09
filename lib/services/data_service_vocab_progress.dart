part of 'data_service.dart';

extension DataServiceVocabProgress on DataService {
  Future<int> getTotalLearnedVocabularyCount() async {
    final prefs = await SharedPreferences.getInstance();
    final learnedIds = prefs.getStringList('learned_vocab_ids') ?? [];
    return learnedIds.toSet().length;
  }

  /// Get learned vocabulary items filtered by difficulty level
  /// Used by games to show appropriate content for Beginner/Intermediate/Advanced users
  Future<List<VocabularyItem>> getLearnedVocabularyItemsByLevel(
    String level,
  ) async {
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

    // 3. Filter by BOTH learned status AND difficulty level
    for (var row in _cachedVocabData!) {
      // Schema: 0:Serial, 1:Day, 2:Word, 3:POS, 4:Difficulty, 5:Tamil, 6:Hindi, 7:EngEx, 8:TamEx, 9:HinEx
      if (row.length > 6) {
        String word = row.length > 2 ? row[2].toString().trim() : '';
        String difficulty = row.length > 4 ? row[4].toString().trim() : '';

        // Skip if not learned OR wrong difficulty level
        bool isLearned = _rowMatchesLearnedVocabulary(row, learnedLookup);
        bool matchesLevel = difficulty.toLowerCase() == level.toLowerCase();

        // In production: must be learned AND match level
        // In dev: show all from that level (for testing)
        if (AppConfig.isProduction && !isLearned) continue;
        if (!matchesLevel) continue;

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
            definition = row.length > 5 ? row[5].toString().trim() : '';
          }

          // Cleanup definition
          definition = DataServiceTextUtils.removeParentheses(definition);

          String pos = row.length > 3 ? row[3].toString().trim() : '';

          items.add(
            VocabularyItem(
              id: word,
              word: word,
              definition: definition,
              imageUrl: null,
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
              translation: definition,
              isLearned: true,
              pos: pos,
            ),
          );
        }
      }
    }

    debugPrint(
      'DataService: Found ${items.length} learned items for level: $level',
    );
    return items;
  }

  Future<List<VerbItem>> getLearnedVerbItems() async {
    // Ensure verbs loaded
    if (_cachedVerbData == null || _cachedVerbData!.isEmpty) {
      await getAllItems('verbs');
    }

    // 2. Get Learned IDs
    final prefs = await SharedPreferences.getInstance();
    final learnedIds = prefs.getStringList('learned_verbs_ids') ?? [];

    if ((_cachedVerbData == null || _cachedVerbData!.isEmpty)) {
      if (AppConfig.isProduction) return [];
      return _getMockVerbs(); // Dev fallback only
    }

    final userLanguage = await getUserLanguage();

    List<VerbItem> items = [];
    for (var row in _cachedVerbData!) {
      // Schema: 0:V1/V2/V3, 1:Day, 2:Difficulty, 3:Tamil, 4:Hindi, 5:EngEx, 6:TamEx, 7:HinEx
      if (row.length > 4) {
        String col0 = row[0].toString().trim();
        String base = col0;
        String past = '';
        String pp = '';

        if (col0.contains('/')) {
          final parts = col0.split('/');
          base = parts.isNotEmpty ? parts[0].trim() : col0;
          past = parts.length > 1 ? parts[1].trim() : '';
          pp = parts.length > 2 ? parts[2].trim() : '';
        }

        // Generate V4/V5 if missing (Basic logic)
        String v4 = "${base}s"; // Simplified
        String v5 = "${base}ing"; // Simplified

        // Strict Filter
        if (AppConfig.isProduction && !learnedIds.contains(base)) continue;

        if (base.isNotEmpty) {
          String meaning = '';
          if (userLanguage == 'Hindi') {
            meaning = row.length > 4 ? row[4].toString().trim() : '';
          } else {
            meaning = row.length > 3 ? row[3].toString().trim() : '';
          }
          if (meaning.isEmpty) {
            meaning = row.length > 3 ? row[3].toString().trim() : '';
          }
          meaning = DataServiceTextUtils.removeParentheses(meaning);

          items.add(
            VerbItem(
              id: base,
              base: base,
              past: past,
              pastParticiple: pp,
              present3rd: v4,
              gerund: v5,
              tamilMeaning: meaning, // Using this field for localized meaning
              exampleSentences: {
                'present': row.length > 5 ? row[5].toString().trim() : '',
                'past': '',
                'future': '',
              },
              isLearned: true,
              dayNumber:
                  int.tryParse(row.length > 1 ? row[1].toString() : '0') ?? 0,
            ),
          );
        }
      }
    }
    return items;
  }

  List<VerbItem> _getMockVerbs() {
    return []; // CLEARED: No mocks allowed
  }

  // --- New Logic for Fill The Gap ---
  Future<List<Map<String, dynamic>>> getVerbGapQuestions(int count) async {
    final verbs = await getLearnedVerbItems();
    if (verbs.isEmpty) return [];

    final random = Random();
    List<Map<String, dynamic>> questions = [];

    for (int i = 0; i < count; i++) {
      final verb = verbs[random.nextInt(verbs.length)];
      // Pick a tense randomly
      final tenses = ['present', 'past', 'future'];
      final targetTense = tenses[random.nextInt(tenses.length)];
      final sentence = verb.exampleSentences[targetTense] ?? '';

      if (sentence.isEmpty) continue;

      String correctWord = '';
      if (targetTense == 'past') {
        correctWord = verb.past;
      } else if (targetTense == 'present') {
        // Simplistic check for 3rd person or base. Since example sentence might vary ("I go" vs "He goes")
        // We will try to find which form appears in sentence
        if (sentence.contains(verb.present3rd)) {
          correctWord = verb.present3rd;
        } else if (sentence.contains(verb.base)) {
          correctWord = verb.base;
        } else if (sentence.contains(verb.gerund)) {
          correctWord = verb.gerund;
        }
      } else {
        correctWord = verb.base; // Will go
      }

      if (correctWord.isEmpty) continue;

      // Create Question
      questions.add({
        'type': 'verb',
        'sentence': sentence,
        'answer': correctWord,
        'distractors': [
          verb.base,
          verb.past,
          verb.gerund,
          verb.pastParticiple,
        ].where((w) => w != correctWord && w.isNotEmpty).take(3).toList(),
        'hint': 'Tense: $targetTense',
      });
    }
    return questions;
  }
}
