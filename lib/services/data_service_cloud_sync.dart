// NOTE: Cloud-sync methods intentionally mix local mutation and remote I/O.
// Extracted verbatim from DataService; do not refactor or reorder.
part of 'data_service.dart';

extension DataServiceCloudSync on DataService {
  String get _blackHoleKey => DataService._blackHoleKey;
  String get _activityKey => DataService._activityKey;

  Future<void> wipeAllLibraryData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    // 1. Clear Memory
    clearMemoryCache();

    // 2. Define all Library Keys
    List<String> types = [
      'vocabulary',
      'verbs',
      'reading',
      'writing',
      'speaking',
      'listening',
      'quiz',
    ];

    // 3. Wipe Local SharedPreferences Aggressively
    final allKeys = prefs.getKeys();
    for (String key in allKeys) {
      if (key.startsWith('custom_') ||
          key.startsWith('vocab_') ||
          key.startsWith('verb_') ||
          key.contains('daily') ||
          key.contains('saved_url_')) {
        await prefs.remove(key);
      }
    }

    // 4. Wipe Cloud Data (Firestore)
    if (user != null) {
      try {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        Map<String, Object?> updates = {};
        for (String type in types) {
          String dataKey = type == 'verbs' ? 'custom_verbs' : 'custom_$type';
          updates[dataKey] = FieldValue.delete();
        }

        // Also wipe daily stuff
        updates['daily_sentences_history'] = FieldValue.delete();
        updates['daily_items'] = FieldValue.delete();

        await docRef.update(updates);
        debugPrint(
          "DataService: Cloud library data wiped for user ${user.uid}",
        );
      } catch (e) {
        debugPrint("DataService: Error wiping cloud data: $e");
      }
    }

    // 5. Reset Daily Sentence Service
    await DailySentenceService().resetData();

    debugPrint("[CLEAN] DataService: All library data wiped successfully.");
  }

  void listenToUserChanges({required Function(String) onLevelChanged}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userProfileSubscription?.cancel();
    _userProfileSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) async {
          if (!snapshot.exists || snapshot.data() == null) return;

          final data = snapshot.data()!;
          final newLevel =
              (data['effective_difficulty_level'] as String?) ??
              (data['english_proficiency_level'] as String?);

          if (newLevel != null) {
            final prefs = await SharedPreferences.getInstance();
            final currentLevel = prefs.getString('english_proficiency_level');

            if (currentLevel != newLevel) {
              debugPrint(
                " Level changed from $currentLevel to $newLevel! Updating...",
              );

              await prefs.setString('english_proficiency_level', newLevel);
              await prefs.setString(
                'english_proficiency_level_${user.uid}',
                newLevel,
              );

              // Clear caches
              DayBasedCurriculumService().reset();
              StageContentService().reset();
              VocabularyService().reset();
              clearMemoryCache();

              // Notify App
              onLevelChanged(newLevel);
            }
          }
        });
  }

  void dispose() {
    _userProfileSubscription?.cancel();
  }

  Future<String> forceRefreshData() async {
    StringBuffer log = StringBuffer();
    log.writeln(" Starting Cloud Sync...\n");

    // 1. Sync Quiz Data CSV (Storage)
    try {
      await syncQuizDataFromCloud();
      log.writeln("OK: Quiz CSV (Storage): Checked/Downloaded");
    } catch (e) {
      log.writeln("Error: Quiz CSV: Failed ($e)");
    }

    // 2. Sync Custom Libraries (Firestore) or Web CSV
    final prefs = await SharedPreferences.getInstance();

    List<String> types = [
      'vocabulary',
      'verbs',
      'reading',
      'writing',
      'speaking',
      'listening',
      'quiz',
    ];
    int totalUpdates = 0;

    for (String type in types) {
      String key = type == 'verbs' ? 'custom_verbs' : 'custom_$type';
      String? savedUrl = prefs.getString('saved_url_$type');

      // Hardcoded Defaults
      if (savedUrl == null || savedUrl.isEmpty) {
        // Defaults removed as per user request to start afresh
        savedUrl = '';
      }

      try {
        bool updated = false;
        if (savedUrl.isNotEmpty) {
          // Auto-Fetch from Web
          bool success = await importCsvFromUrl(savedUrl, type);
          if (success) {
            updated =
                true; // Assume true if fetch succeeded, or we could diff content but simple is fine
          }
        } else {
          // Standard Cloud Sync
          updated = await _syncWithCloud(key);
        }

        // Ensure data is loaded to get count
        switch (type) {
          case 'vocabulary':
            await _loadVocabData();
            break;
          case 'verbs':
            await _loadVerbData();
            break;
          case 'reading':
            await _loadReadingData();
            break;
          case 'writing':
            await _loadWritingData();
            break;
          case 'listening':
            await _loadListeningData();
            break;
          case 'quiz':
            await _loadQuizData();
            break;
        }

        if (updated) totalUpdates++;

        // log.writeln(
        //   "${updated ? '' : 'OK:'} ${type.toUpperCase()}: $count items ($status)",
        // );
      } catch (e) {
        log.writeln("Error: ${type.toUpperCase()}: Error ($e)");
      }
    }

    log.writeln("\n Sync Complete! ($totalUpdates collections updated)");
    return log.toString();
  }

  Future<void> syncQuizDataFromCloud() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/quiz_data.csv');

      // Check metadata or just always download if requested explicitly
      final ref = FirebaseStorage.instance.ref().child('data/quiz_data.csv');

      // We can check metadata to see if updated, but forceRefresh implies "Give me latest".
      await ref.writeToFile(file);
      debugPrint("DataService: Quiz data downloaded to ${file.path}");
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        debugPrint(
          "DataService: Cloud quiz_data.csv not found. Using local/asset fallback.",
        );
        return;
      }
      debugPrint("DataService: Quiz cloud sync skipped (${e.code}).");
      // Not fatal, will fallback to asset
    } catch (e) {
      debugPrint("DataService: Quiz cloud sync skipped: $e");
      // Not fatal, will fallback to asset
    }
  }

  Future<bool> importCsvFromUrl(String url, String type) async {
    try {
      // ?? BLOCKER: Prevent legacy default sheets from re-syncing
      final List<String> bannedUrls = [
        "https://docs.google.com/spreadsheets/d/e/2PACX-1vQ6hRMDTnZ8-ZQ9AbTappG9mOBnR7RgfZypI-ksDGr0r_nRkIyzFYBGDjB_A_xCWBge0z3VUIPSLtRa/pub?output=csv",
        "https://docs.google.com/spreadsheets/d/e/2PACX-1vTZiFaFrTnFpoILXz_jm4-XUXigcB1NW7V1HGA-S6UwC-60Fbyfx8jZf2u8hDIcKlgHuVImjucpxAEc/pub?output=csv",
        "https://docs.google.com/spreadsheets/d/e/2PACX-1vT1ZunpvOlzHf_xDY0mPINp_Sa1XmcdFhyGc9Rrb0RIq5kGf5wKNeM1sjtK5M865durEfMg4cgUkjrf/pub?output=csv",
        "https://docs.google.com/spreadsheets/d/e/2PACX-1vQy59lqvW_5qG9sRG8PSSl0-JSoHPiZXZNlyFq-5jKeHcOT4PrjoU-YP43PKjf-8wBOtwAEQXb8TYOk/pub?output=csv",
        "https://docs.google.com/spreadsheets/d/e/2PACX-1vRFk3PzNq30GLKrnEdWw_aNyQGa9mkGedHfZxHsJX8xoJZEPwqwEblVLd_sBHja161TFOtMDNFdp_k7/pub?output=csv",
        "https://docs.google.com/spreadsheets/d/e/2PACX-1vTIGws_xzeHyMlPSnStq_orq7MogT3AlyEkvIM4WWqa0WpdY4-dGd3rgw5IIARMiF0j0OTPMvsFttcE/pub?output=csv",
        "https://docs.google.com/spreadsheets/d/e/2PACX-1vQY5rcw5VYtMByPX-PMNTiqv4vdkpyCz2FKmvbxgZhF6zIK52tpN6VrkHHMO4CGjunopoOwiYR6gKWO/pub?output=csv",
      ];

      if (bannedUrls.contains(url)) {
        debugPrint("?? BLOCKED legacy default sheet: $url");
        return false;
      }

      debugPrint("Fetching CSV from $url...");

      // Use Repository with Isolate
      List<List<dynamic>> newRows = await _csvRepository.fetchAndParseCsv(url);

      // Remove header if present
      newRows = normalizeImportedRows(newRows);

      switch (type) {
        case 'vocabulary':
          await _mergeAndSaveVocabulary(newRows, replace: true);
          break;
        case 'verbs':
          await _mergeAndSaveVerbs(newRows, replace: true);
          break;
        case 'reading':
          await _mergeAndSaveGeneric('reading', newRows, replace: true);
          break;
        case 'writing':
          await _mergeAndSaveGeneric('writing', newRows, replace: true);
          break;
        case 'speaking':
          await _mergeAndSaveGeneric('speaking', newRows, replace: true);
          break;
        case 'listening':
          await _mergeAndSaveGeneric('listening', newRows, replace: true);
          break;
        case 'quiz':
          await _mergeAndSaveGeneric('quiz', newRows, replace: true);
          break;
        default:
          debugPrint("Unknown type for import: $type");
          return false;
      }
      // Save URL for future auto-sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_url_$type', url);

      // Clear memory cache so next fetch reloads from prefs
      _clearCacheFor(type);

      return true;
    } catch (e) {
      debugPrint("Error importing CSV: $e");
      return false;
    }
  }

  Future<void> deleteItem(String type, int index) async {
    List<List<dynamic>>? targetList;
    String key;

    switch (type) {
      case 'vocabulary':
        targetList = _cachedVocabData;
        key = 'custom_vocabulary';
        break;
      case 'verbs':
        targetList = _cachedVerbData;
        key = 'custom_verbs';
        break;
      case 'reading':
        targetList = _cachedReadingData;
        key = 'custom_reading';
        break;
      case 'writing':
        targetList = _cachedWritingData;
        key = 'custom_writing';
        break;
      case 'speaking':
        targetList = _cachedSpeakingData;
        key = 'custom_speaking';
        break;
      case 'listening':
        targetList = _cachedListeningData;
        key = 'custom_listening';
        break;
      case 'quiz':
        targetList = _cachedQuizData;
        key = 'custom_quiz';
        break;
      default:
        return;
    }

    if (targetList != null && index >= 0 && index < targetList.length) {
      targetList.removeAt(index);
      await _saveDataToPrefs(key, targetList);
    }
  }

  Future<void> updateItem(
    String type,
    int index,
    Map<String, String> updatedItem,
  ) async {
    List<List<dynamic>>? targetList;
    String key;

    switch (type) {
      case 'vocabulary':
        targetList = _cachedVocabData;
        key = 'custom_vocabulary';
        break;
      case 'verbs':
        targetList = _cachedVerbData;
        key = 'custom_verbs';
        break;
      case 'reading':
        targetList = _cachedReadingData;
        key = 'custom_reading';
        break;
      case 'writing':
        targetList = _cachedWritingData;
        key = 'custom_writing';
        break;
      case 'speaking':
        targetList = _cachedSpeakingData;
        key = 'custom_speaking';
        break;
      case 'listening':
        targetList = _cachedListeningData;
        key = 'custom_listening';
        break;
      case 'quiz':
        targetList = _cachedQuizData;
        key = 'custom_quiz';
        break;
      default:
        return;
    }

    if (targetList != null && index >= 0 && index < targetList.length) {
      // Reconstruct List<dynamic> from Map<String, String> based on schema
      List<dynamic> oldRow = targetList[index];
      List<dynamic> newRow = List.from(
        oldRow,
      ); // Copy existing to preserve length/hidden cols

      // Helper to safely update simple columns
      void updateCol(int colIndex, String val) {
        if (newRow.length <= colIndex) {
          // Extend row if needed
          while (newRow.length <= colIndex) {
            newRow.add("");
          }
        }
        newRow[colIndex] = val;
      }

      if (type == 'vocabulary') {
        // 0: Serial, 1: Word, 2: POS, 3: Tamil, 4: Hindi, ...
        // Map Keys: word, type, meaning, example
        if (updatedItem.containsKey('word')) updateCol(1, updatedItem['word']!);
        if (updatedItem.containsKey('type')) updateCol(2, updatedItem['type']!);
        if (updatedItem.containsKey('meaning')) {
          updateCol(3, updatedItem['meaning']!);
        }
        if (updatedItem.containsKey('example')) {
          updateCol(5, updatedItem['example']!);
        }
      } else if (type == 'verbs') {
        // 0: SN, 1: English (V1/V2/V3)...
        if (updatedItem.containsKey('word')) updateCol(1, updatedItem['word']!);
        if (updatedItem.containsKey('meaning')) {
          updateCol(2, updatedItem['meaning']!);
        }
      } else if (type == 'reading') {
        // 0:ID, 1:Title, 2:Passage, 3:Q1, 4:A1, 5:Q2, 6:A2, 7:Level
        if (updatedItem.containsKey('id')) updateCol(0, updatedItem['id']!);
        if (updatedItem.containsKey('title')) {
          updateCol(1, updatedItem['title']!);
        }
        if (updatedItem.containsKey('passage')) {
          updateCol(2, updatedItem['passage']!);
        }
        if (updatedItem.containsKey('q1')) updateCol(3, updatedItem['q1']!);
        if (updatedItem.containsKey('a1')) updateCol(4, updatedItem['a1']!);
        if (updatedItem.containsKey('q2')) updateCol(5, updatedItem['q2']!);
        if (updatedItem.containsKey('a2')) updateCol(6, updatedItem['a2']!);
        if (updatedItem.containsKey('level')) {
          updateCol(7, updatedItem['level']!);
        }
        if (updatedItem.containsKey('tamil')) {
          updateCol(8, updatedItem['tamil']!);
        }
        if (updatedItem.containsKey('hindi')) {
          updateCol(9, updatedItem['hindi']!);
        }
      } else if (type == 'writing') {
        // 0:ID, 1:Focus, 2:Type/Level, 3:Instruction, 4:Input, 5:Answer, 6:Explanation
        if (updatedItem.containsKey('id')) updateCol(0, updatedItem['id']!);
        if (updatedItem.containsKey('focus')) {
          updateCol(1, updatedItem['focus']!);
        }
        if (updatedItem.containsKey('type')) updateCol(2, updatedItem['type']!);
        if (updatedItem.containsKey('instruction')) {
          updateCol(3, updatedItem['instruction']!);
        }
        if (updatedItem.containsKey('input')) {
          updateCol(4, updatedItem['input']!);
        }
        if (updatedItem.containsKey('answer')) {
          updateCol(5, updatedItem['answer']!);
        }
        if (updatedItem.containsKey('explanation')) {
          updateCol(6, updatedItem['explanation']!);
        }
      } else if (type == 'speaking') {
        // 0:ID, 1:Category, 2:Level, 3:Text
        if (updatedItem.containsKey('id')) updateCol(0, updatedItem['id']!);
        if (updatedItem.containsKey('category')) {
          updateCol(1, updatedItem['category']!);
        }
        if (updatedItem.containsKey('level')) {
          updateCol(2, updatedItem['level']!);
        }
        if (updatedItem.containsKey('text')) updateCol(3, updatedItem['text']!);
      } else if (type == 'listening') {
        // 0:ID, 1:Title, 2:Level, 3:Dur, 4:File, 5:Question, 6:Answer
        if (updatedItem.containsKey('id')) updateCol(0, updatedItem['id']!);
        if (updatedItem.containsKey('title')) {
          updateCol(1, updatedItem['title']!);
        }
        if (updatedItem.containsKey('audio_key')) {
          updateCol(4, updatedItem['audio_key']!);
        }
        if (updatedItem.containsKey('question')) {
          updateCol(5, updatedItem['question']!);
        }
        if (updatedItem.containsKey('answer')) {
          updateCol(6, updatedItem['answer']!);
        }
      } else if (type == 'quiz') {
        // 0:ID, 1:Q, 2:Op1, 3:Op2, 4:Op3, 5:Op4, 6:Ans
        if (updatedItem.containsKey('id')) updateCol(0, updatedItem['id']!);
        if (updatedItem.containsKey('question')) {
          updateCol(1, updatedItem['question']!);
        }
        if (updatedItem.containsKey('option1')) {
          updateCol(2, updatedItem['option1']!);
        }
        if (updatedItem.containsKey('option2')) {
          updateCol(3, updatedItem['option2']!);
        }
        if (updatedItem.containsKey('option3')) {
          updateCol(4, updatedItem['option3']!);
        }
        if (updatedItem.containsKey('option4')) {
          updateCol(5, updatedItem['option4']!);
        }
        if (updatedItem.containsKey('answer')) {
          updateCol(6, updatedItem['answer']!);
        }
      }

      targetList[index] = newRow;
      await _saveDataToPrefs(key, targetList);
    }
  }

  Future<void> _mergeAndSaveVocabulary(
    List<List<dynamic>> newRows, {
    bool replace = false,
  }) async {
    // Ensure base data is loaded
    await _loadVocabData();

    // Create a map for existing words to check duplicates easily
    // Key: English Word (lowercased) -> Value: Row Data
    Map<String, List<dynamic>> dataMap = {};

    // 1. Add existing asset/cached data (ONLY if not replacing)
    if (!replace) {
      for (var row in _cachedVocabData!) {
        if (row.length > 1) {
          String key = row[1].toString().toLowerCase().trim();
          if (key.isNotEmpty) dataMap[key] = row;
        }
      }
    }

    // 2. Add/Update with new rows
    for (var row in newRows) {
      if (row.length > 1) {
        String key = row[1].toString().toLowerCase().trim();
        if (key.isNotEmpty) {
          dataMap[key] = row; // Overwrites if exists, adds if new
        }
      }
    }

    // 3. Convert back to list
    _cachedVocabData = dataMap.values.toList();

    // 4. Save to SharedPreferences
    await _saveDataToPrefs('custom_vocabulary', _cachedVocabData!);
  }

  Future<void> _mergeAndSaveVerbs(
    List<List<dynamic>> newRows, {
    bool replace = false,
  }) async {
    await _loadVerbData();
    Map<String, List<dynamic>> dataMap = {};

    if (!replace) {
      for (var row in _cachedVerbData!) {
        if (row.length > 1) {
          String fullForm = row[1].toString();
          String base = fullForm.split('/')[0].toLowerCase().trim();
          if (base.isNotEmpty) dataMap[base] = row;
        }
      }
    }

    for (var row in newRows) {
      if (row.length > 1) {
        String fullForm = row[1].toString();
        String base = fullForm.split('/')[0].toLowerCase().trim();
        if (base.isNotEmpty) dataMap[base] = row;
      }
    }

    _cachedVerbData = dataMap.values.toList();
    await _saveDataToPrefs('custom_verbs', _cachedVerbData!);
  }

  Future<void> _mergeAndSaveGeneric(
    String type,
    List<List<dynamic>> newRows, {
    bool replace = false,
  }) async {
    // Ensure data loaded
    switch (type) {
      case 'reading':
        await _loadReadingData();
        break;
      case 'writing':
        await _loadWritingData();
        break;
      case 'speaking':
        await _loadSpeakingData();
        break;
      case 'listening':
        await _loadListeningData();
        break;
      case 'quiz':
        await _loadQuizData();
        break;
    }

    // Get current cache reference
    List<List<dynamic>> cache = [];
    switch (type) {
      case 'reading':
        cache = _cachedReadingData ?? [];
        break;
      case 'writing':
        cache = _cachedWritingData ?? [];
        break;
      case 'speaking':
        cache = _cachedSpeakingData ?? [];
        break;
      case 'listening':
        cache = _cachedListeningData ?? [];
        break;
      case 'quiz':
        cache = _cachedQuizData ?? [];
        break;
    }

    Map<String, List<dynamic>> dataMap = {};
    List<List<dynamic>> finalRows = [];

    if (replace) {
      // OVERWRITE MODE: Just take newRows, filtering invalid ones
      // We do NOT use a Map here because IDs might be duplicated across lessons (e.g. 1, 2, 3 for Lesson 1, then 1, 2, 3 for Lesson 2)
      for (var row in newRows) {
        if (row.isNotEmpty) {
          // We expect at least an ID or some content.
          // If user has spaces/empty rows, we skip them.
          // We check if the row has significant content (more than just empty strings)
          bool hasContent = row.any(
            (cell) => cell.toString().trim().isNotEmpty,
          );
          if (hasContent) {
            finalRows.add(row);
          }
        }
      }
    } else {
      // MERGE MODE (Legacy): Deduplicate by ID
      // Use ID (column 0) as key
      for (var row in cache) {
        if (row.isNotEmpty) {
          String id = row[0].toString().trim();
          if (id.isNotEmpty) dataMap[id] = row;
        }
      }

      for (var row in newRows) {
        if (row.isNotEmpty) {
          String id = row[0].toString().trim();
          if (id.isNotEmpty) dataMap[id] = row;
        }
      }
      finalRows = dataMap.values.toList();
    }

    List<List<dynamic>> merged = finalRows;

    // Update cache and save
    String key = 'custom_$type';
    switch (type) {
      case 'reading':
        _cachedReadingData = merged;
        break;
      case 'writing':
        _cachedWritingData = merged;
        break;
      case 'speaking':
        _cachedSpeakingData = merged;
        break;
      case 'listening':
        _cachedListeningData = merged;
        break;
      case 'quiz':
        _cachedQuizData = merged;
        break;
    }

    await _saveDataToPrefs(key, merged);
  }

  Future<void> _saveDataToPrefs(String key, List<List<dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = json.encode(data);
    await prefs.setString(key, jsonString);
    debugPrint("Saved ${data.length} items to $key (Local)");

    // Sync to Cloud
    try {
      await FirebaseFirestore.instance
          .collection('library_content')
          .doc(key)
          .set({
            'data': jsonString,
            'timestamp': FieldValue.serverTimestamp(),
            'count': data.length,
          });
      debugPrint("Uploaded $key to Firestore");
    } catch (e) {
      debugPrint("Error uploading $key to Firestore: $e");
    }
  }

  Future<bool> _syncWithCloud(String key) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('library_content')
          .doc(key)
          .get();

      if (doc.exists && doc.data() != null) {
        // We could compare timestamps here to avoid unnecessary writes,
        // but for now, cloud is truth.
        String? cloudJson = doc.data()!['data'] as String?;
        if (cloudJson != null && cloudJson.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          String? localJson = prefs.getString(key);

          if (cloudJson != localJson) {
            await prefs.setString(key, cloudJson);
            debugPrint("Downloaded update for $key from Cloud");
            _parseAndCache(key, cloudJson); // FORCE UPDATE CACHE IMPACT
            return true; // Updated
          }
        }
      }
      return false; // No change
    } catch (e) {
      debugPrint("Error syncing $key from Cloud: $e");
      return false;
    }
  }

  void _parseAndCache(String key, String jsonString) {
    try {
      List<dynamic> jsonList = json.decode(jsonString);
      List<List<dynamic>> validList = jsonList
          .map((e) => (e as List).toList())
          .toList();

      if (key == 'custom_vocabulary') {
        _cachedVocabData = validList;
      } else if (key == 'custom_verbs') {
        _cachedVerbData = validList;
      } else if (key == 'custom_reading') {
        _cachedReadingData = validList;
      } else if (key == 'custom_writing') {
        _cachedWritingData = validList;
      } else if (key == 'custom_speaking') {
        _cachedSpeakingData = validList;
      } else if (key == 'custom_listening') {
        _cachedListeningData = validList;
      } else if (key == 'custom_quiz') {
        _cachedQuizData = validList;
      }
    } catch (e) {
      debugPrint("Error parsing synced data for $key: $e");
    }
  }

  Future<void> saveQuizResultForStage(int stage, int score, int total) async {
    final prefs = await SharedPreferences.getInstance();
    final stageService = StageProgressService();
    final scoreKey = stageService.quizScoreKey(stage);
    final totalKey = stageService.quizTotalKey(stage);
    final passedKey = stageService.quizPassedKey(stage);
    final assessmentKey = stageService.assessmentCompletedKey(stage);

    await prefs.setInt(scoreKey, score);
    await prefs.setInt(totalKey, total);
    bool passed = stageService.isAssessmentPassed(score, total);
    await prefs.setBool(passedKey, passed);
    await prefs.setBool(assessmentKey, passed);

    // Cloud sync should not block assessment result UI.
    unawaited(saveProgressToCloud(scoreKey, score));
    unawaited(saveProgressToCloud(totalKey, total));
    unawaited(saveProgressToCloud(passedKey, passed));
    unawaited(saveProgressToCloud(assessmentKey, passed));

    if (total > 0) {
      unawaited(_notifyTeacherOfSuccess('Level $stage', score, total));
    }
  }

  /// Saves a specific progress key to Firestore for the current user.
  Future<void> saveProgressToCloud(String key, dynamic value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc('all_data')
          .set({key: value}, SetOptions(merge: true));
      debugPrint("Cloud Sync: Saved $key=$value");

      // Also track localized total if relevant
      if (key.startsWith('mastery_')) {
        await _updateMasteryTally();
      }
    } catch (e) {
      debugPrint("Error saving progress to cloud: $e");
    }
  }

  Future<void> seedVocabularyForLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();

    // Ensure vocab is loaded
    if (_cachedVocabData == null || _cachedVocabData!.isEmpty) {
      await _loadVocabData();
    }

    int countToUnlock = 0;
    if (level.contains('A1')) {
      countToUnlock = 10; // Start with 10 words
    } else if (level.contains('A2')) {
      countToUnlock = 30;
    } else if (level.contains('B1')) {
      countToUnlock = 60;
    } else if (level.contains('B2')) {
      countToUnlock = 100;
    } else if (level.contains('C1')) {
      countToUnlock = 150;
    }

    if (countToUnlock == 0) return;

    final rows = _cachedVocabData;
    if (rows == null || rows.isEmpty) return;

    // Take first N items as "learned" using vocabulary words (column 2).
    // Some older flows stored serial IDs from column 0, which later blocked
    // game content that expects actual words in learned_vocab_ids.
    final idsToMark = rows
        .take(min(countToUnlock, rows.length))
        .map((row) {
          if (row.length > 2) {
            return row[2].toString().trim();
          }
          return '';
        })
        .where((id) => id.isNotEmpty)
        .toList();

    // Save to Prefs
    final existing = prefs.getStringList('learned_vocab_ids') ?? [];
    final Set<String> combined = {...existing, ...idsToMark};
    await prefs.setStringList('learned_vocab_ids', combined.toList());

    // Sync to Cloud
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'learned_vocab_ids': combined.toList(),
      }, SetOptions(merge: true));
    }

    debugPrint(
      "Seeded $countToUnlock words for level $level. Total: ${combined.length}",
    );
  }

  Future<void> _updateMasteryTally() async {
    // Hidden tally for quick read
    final prefs = await SharedPreferences.getInstance();
    int count = 0;
    for (String key in prefs.getKeys()) {
      if (key.startsWith('mastery_done_')) count++;
    }
    await prefs.setInt('mastery_total_done', count);
  }

  Future<void> saveMasteryProgress(String category, String id) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Legacy Tally
    final key = 'mastery_done_${category}_$id';
    // Only update if not already done, or if we want to be safe.
    // The legacy check prevents re-tallying.
    bool wasDone = prefs.getBool(key) == true;
    if (!wasDone) {
      await prefs.setBool(key, true);
      await saveProgressToCloud(key, true);
      await _updateMasteryTally();
    }

    // 2. New List Logic (For Progress Bars)
    final listKey = 'mastery_${category}_completed';
    final List<String> completed = prefs.getStringList(listKey) ?? [];
    if (!completed.contains(id)) {
      completed.add(id);
      await prefs.setStringList(listKey, completed);
      // Sync list to cloud
      await saveProgressToCloud(listKey, completed);
      debugPrint("Saved mastery progress: $category - $id");

      // Log Activity
      String icon = 'star';
      String color = 'blue';
      if (category == 'reading') icon = 'book';
      if (category == 'writing') {
        icon = 'pen';
        color = 'green';
      }
      if (category == 'speaking') {
        icon = 'mic';
        color = 'orange';
      }
      if (category == 'listening') {
        icon = 'video';
        color = 'purple';
      }

      await logActivity(
        title: '${category[0].toUpperCase()}${category.substring(1)} Mastery',
        subtitle: 'Lesson Completed',
        iconName: icon,
        colorName: color,
      );
    }
  }

  Future<Map<String, double>> getDetailedProgress({String? uid}) async {
    try {
      final targetUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
      if (targetUid == null) {
        return {
          'curriculum': 0.0,
          'mastery': 0.0,
          'daily': 0.0,
          'reading': 0.0,
          'writing': 0.0,
          'listening': 0.0,
          'speaking': 0.0,
        };
      }

      // 1. Curriculum Progress
      final allLessons = getCurriculumLessons();
      int completedLessons = 0;
      final lessonsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .collection('curriculum_progress')
          .get();
      completedLessons = lessonsSnap.docs
          .where((doc) => doc.data()['completed'] == true)
          .length;

      double curriculumP = allLessons.isEmpty
          ? 0
          : completedLessons / allLessons.length;

      // 2. Mastery Progress (Granular)
      await _loadReadingData();
      await _loadWritingData();
      await _loadListeningData();
      await _loadSpeakingData();

      final readingIds =
          _cachedReadingData?.map((e) => e[0].toString()).toSet() ?? {};
      final writingIds =
          _cachedWritingData?.map((e) => e[0].toString()).toSet() ?? {};
      final listeningIds =
          _cachedListeningData?.map((e) => e[0].toString()).toSet() ?? {};
      final speakingIds =
          _cachedSpeakingData?.map((e) => e[0].toString()).toSet() ?? {};

      final progressSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .collection('progress')
          .doc('all_data')
          .get();

      final progData = progressSnap.data() ?? {};
      int cReading = 0;
      int cWriting = 0;
      int cListening = 0;
      int cSpeaking = 0;

      progData.forEach((key, value) {
        if (key.startsWith('mastery_done_') && value == true) {
          String id = key.replaceFirst('mastery_done_', '');
          if (readingIds.contains(id)) {
            cReading++;
          } else if (writingIds.contains(id)) {
            cWriting++;
          } else if (listeningIds.contains(id)) {
            cListening++;
          } else if (speakingIds.contains(id)) {
            cSpeaking++;
          }
        }
      });

      double readingP = readingIds.isEmpty
          ? 0.0
          : (cReading / readingIds.length);
      double writingP = writingIds.isEmpty
          ? 0.0
          : (cWriting / writingIds.length);
      double listeningP = listeningIds.isEmpty
          ? 0.0
          : (cListening / listeningIds.length);
      double speakingP = speakingIds.isEmpty
          ? 0.0
          : (cSpeaking / speakingIds.length);

      // Total Mastery Averaged
      int totalItems =
          readingIds.length +
          writingIds.length +
          listeningIds.length +
          speakingIds.length;
      int totalCompleted = cReading + cWriting + cListening + cSpeaking;
      double masteryP = totalItems == 0 ? 0.0 : (totalCompleted / totalItems);

      // 3. Daily Activity
      double dailyP = 0.0;
      if (uid == null) {
        final prefs = await SharedPreferences.getInstance();
        final stageService = StageProgressService();
        final currentStage = await stageService.getCurrentStage(prefs: prefs);
        final completedStages = currentStage > 1 ? currentStage - 1 : 0;
        dailyP = min(completedStages, 30) / 30.0;
      } else {
        final currentStage = (progData['current_learning_stage'] as int?) ?? 1;
        final completedStages = currentStage > 1 ? currentStage - 1 : 0;
        dailyP = min(completedStages, 30) / 30.0;
      }

      return {
        'curriculum': curriculumP.clamp(0.0, 1.0),
        'mastery': masteryP.clamp(0.0, 1.0),
        'daily': dailyP.clamp(0.0, 1.0),
        'reading': readingP.clamp(0.0, 1.0),
        'writing': writingP.clamp(0.0, 1.0),
        'listening': listeningP.clamp(0.0, 1.0),
        'speaking': speakingP.clamp(0.0, 1.0),
      };
    } catch (e) {
      debugPrint("Error calculating detailed progress: $e");
      return {
        'curriculum': 0.0,
        'mastery': 0.0,
        'daily': 0.0,
        'reading': 0.0,
        'writing': 0.0,
        'listening': 0.0,
        'speaking': 0.0,
      };
    }
  }

  Future<double> getOverallProgress({String? uid}) async {
    final detailed = await getDetailedProgress(uid: uid);
    return (detailed['curriculum']! * 0.5) +
        (detailed['mastery']! * 0.3) +
        (detailed['daily']! * 0.2);
  }

  Future<void> syncProgressFromCloud({bool force = false}) async {
    if (_progressSyncFuture != null) {
      await _progressSyncFuture;
      return;
    }

    const progressSyncCooldown = Duration(seconds: 15);
    final now = DateTime.now();
    if (!force &&
        _lastProgressSyncAt != null &&
        now.difference(_lastProgressSyncAt!) < progressSyncCooldown) {
      debugPrint('Cloud Sync: Skipping duplicate fetch (cooldown).');
      return;
    }

    final future = _syncProgressFromCloudCore();
    _progressSyncFuture = future;
    try {
      await future;
      _lastProgressSyncAt = DateTime.now();
    } finally {
      if (identical(_progressSyncFuture, future)) {
        _progressSyncFuture = null;
      }
    }
  }

  Future<void> _syncProgressFromCloudCore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      debugPrint("Cloud Sync: Fetching progress for ${user.uid}...");
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc('all_data')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final prefs = await SharedPreferences.getInstance();
        final stageService = StageProgressService();
        int asInt(dynamic raw, {int fallback = 0}) {
          if (raw is int) return raw;
          if (raw is double) return raw.round();
          if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
          return fallback;
        }

        final localStageBeforeSync = await stageService.getCurrentStage(
          prefs: prefs,
        );
        var resolvedStage = localStageBeforeSync;
        var stageNeedsRemoteRepair = false;

        final localReminderUpdatedAt =
            prefs.getInt('daily_reminder_updated_at') ?? 0;
        final remoteReminderUpdatedAt = asInt(
          data['daily_reminder_updated_at'],
        );
        final keepLocalReminder =
            localReminderUpdatedAt > remoteReminderUpdatedAt &&
            prefs.containsKey('daily_reminder_minutes');

        final localNotificationsUpdatedAt =
            prefs.getInt('notifications_updated_at') ?? 0;
        final remoteNotificationsUpdatedAt = asInt(
          data['notifications_updated_at'],
        );
        final keepLocalNotifications =
            localNotificationsUpdatedAt > remoteNotificationsUpdatedAt &&
            prefs.containsKey('notifications_enabled');

        final inferredTaskCompletionKeys = <String>{};
        for (var entry in data.entries) {
          final key = entry.key;
          final value = entry.value;

          if ((key == 'daily_reminder_minutes' ||
                  key == 'daily_reminder_updated_at') &&
              keepLocalReminder) {
            continue;
          }

          if ((key == 'notifications_enabled' ||
                  key == 'notifications_updated_at') &&
              keepLocalNotifications) {
            continue;
          }

          if (key == 'user_level') {
            if (value is int) {
              await prefs.setInt('user_xp_level', value);
            }
            continue;
          }

          if (key == 'current_learning_stage') {
            final remoteStage = max(1, asInt(value, fallback: 1));
            if (remoteStage < localStageBeforeSync) {
              stageNeedsRemoteRepair = true;
            }
            resolvedStage = max(resolvedStage, remoteStage);
            await stageService.setCurrentStage(resolvedStage, prefs: prefs);
            continue;
          }

          if (value is bool) {
            await prefs.setBool(key, value);
            if (value && key.startsWith('xp_awarded_task_')) {
              final taskKey = key.substring('xp_awarded_'.length);
              if (taskKey.startsWith('task_')) {
                inferredTaskCompletionKeys.add(taskKey);
              }
            }
          } else if (value is int) {
            await prefs.setInt(key, value);
            if (value > 0 &&
                key.startsWith('task_') &&
                key.endsWith('_score')) {
              final taskKey = key.substring(0, key.length - '_score'.length);
              inferredTaskCompletionKeys.add(taskKey);
            }
          } else if (value is String) {
            await prefs.setString(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          } else if (value is List) {
            // Handle List<String> (e.g., mastery completed lists, black hole items)
            try {
              final listStr = value.map((e) => e.toString()).toList();
              await prefs.setStringList(key, listStr);
            } catch (e) {
              debugPrint("Cloud Sync: Error parsing list for key $key: $e");
            }
          }
        }

        // Backfill completion booleans for legacy data where XP markers were
        // synced but direct task flags were not.
        for (final taskKey in inferredTaskCompletionKeys) {
          final alreadyComplete = prefs.getBool(taskKey) ?? false;
          if (alreadyComplete) continue;
          await prefs.setBool(taskKey, true);
          if (!data.containsKey(taskKey)) {
            await saveProgressToCloud(taskKey, true);
          }
          debugPrint('Cloud Sync: Recovered completion flag for $taskKey');
        }

        final derivedStreak = resolvedStage > 1 ? resolvedStage - 1 : 0;
        final prevStreakDays = prefs.getInt('user_streak_days');
        final prevStageStreak = prefs.getInt('user_stage_streak');
        final streakChanged =
            prevStreakDays != derivedStreak || prevStageStreak != derivedStreak;
        if (streakChanged) {
          await prefs.setInt('user_streak_days', derivedStreak);
          await prefs.setInt('user_stage_streak', derivedStreak);
        }

        if (stageNeedsRemoteRepair) {
          await saveProgressToCloud('current_learning_stage', resolvedStage);
        }
        if (streakChanged) {
          await saveProgressToCloud('user_streak_days', derivedStreak);
          await saveProgressToCloud('user_stage_streak', derivedStreak);
        }

        if (keepLocalReminder) {
          await saveProgressToCloud(
            'daily_reminder_minutes',
            prefs.getInt('daily_reminder_minutes') ?? 9 * 60,
          );
          await saveProgressToCloud(
            'daily_reminder_updated_at',
            localReminderUpdatedAt,
          );
        }

        if (keepLocalNotifications) {
          await saveProgressToCloud(
            'notifications_enabled',
            prefs.getBool('notifications_enabled') ?? true,
          );
          await saveProgressToCloud(
            'notifications_updated_at',
            localNotificationsUpdatedAt,
          );
        }
      } else {
        debugPrint("Cloud Sync: No remote progress found.");
      }
    } catch (e) {
      debugPrint("Error syncing progress from cloud: $e");
    }
  }

  Future<void> addToBlackHoleForStage(
    List<Map<String, String>> wrongAnswers,
    int stage,
  ) async {
    if (wrongAnswers.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    // 1. Add to Global Black Hole (for BlackHoleScreen)
    final globalItems = await getBlackHoleItems();
    bool globalChanged = false;

    for (var item in wrongAnswers) {
      final word = item['word'] ?? '';
      // Check if already in global list
      final alreadyExists = globalItems.any((i) {
        final iWord = i['word'] ?? i['title'] ?? '';
        return iWord.toLowerCase() == word.toLowerCase();
      });

      if (word.isNotEmpty && !alreadyExists) {
        // Enforce consistent structure for Black Hole
        globalItems.add({
          'word': word,
          'id':
              DateTime.now().millisecondsSinceEpoch.toString() +
              Random().nextInt(1000).toString(),
          'meaning': item['correct_answer'] ?? '',
          'type': item['type'] ?? 'vocab',
          'added_at': DateTime.now().toIso8601String(),
        });
        globalChanged = true;
      }
    }

    if (globalChanged) {
      final encodedItems = globalItems.map((i) => jsonEncode(i)).toList();
      await prefs.setStringList(_blackHoleKey, encodedItems);
      unawaited(saveProgressToCloud(_blackHoleKey, encodedItems));
      debugPrint("Added ${wrongAnswers.length} items to Global Black Hole");
    }

    // 2. Keep Level-specific log (history)
    final key = 'blackhole_stage_$stage';
    List<String> dailyWords = prefs.getStringList(key) ?? [];

    for (var item in wrongAnswers) {
      final word = item['word'] ?? '';
      if (word.isNotEmpty && !dailyWords.contains(word)) {
        dailyWords.add(word);
      }
    }

    await prefs.setStringList(key, dailyWords);
  }

  Future<bool> toggleBlackHoleItem(Map<String, String> item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getBlackHoleItems();
    final id = item['id'] ?? item['word'] ?? '';

    final existingIndex = items.indexWhere((i) => (i['id'] ?? i['word']) == id);
    bool added = false;

    if (existingIndex >= 0) {
      items.removeAt(existingIndex);
      added = false;
    } else {
      items.add(item);
      added = true;
    }

    final encodedItems = items.map((i) => jsonEncode(i)).toList();
    await prefs.setStringList(_blackHoleKey, encodedItems);
    // Sync to cloud
    await saveProgressToCloud(_blackHoleKey, encodedItems);
    return added;
  }

  Future<List<Map<String, String>>> getBlackHoleItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? encodedItems = prefs.getStringList(_blackHoleKey);

    // If missing locally, try cloud sync ONCE to restore
    if (encodedItems == null) {
      debugPrint("BlackHole: Local cache missing. Syncing from cloud...");
      await syncProgressFromCloud(force: true);
      encodedItems = prefs.getStringList(_blackHoleKey);
    }

    encodedItems ??= [];

    return encodedItems
        .map((e) => Map<String, String>.from(jsonDecode(e)))
        .toList();
  }

  Future<bool> isInBlackHole(String id) async {
    final items = await getBlackHoleItems();
    return items.any((i) => (i['id'] ?? i['word']) == id);
  }

  Future<void> logActivity({
    required String title,
    required String subtitle,
    required String iconName, // 'quiz', 'book', 'mic', 'pen'
    required String colorName, // 'red', 'blue', 'green', 'orange', 'purple'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(_activityKey) ?? [];

    final newLog = {
      'title': title,
      'subtitle': subtitle,
      'icon': iconName,
      'color': colorName,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Insert at beginning
    logs.insert(0, jsonEncode(newLog));
    if (logs.length > 20) logs = logs.sublist(0, 20); // Keep last 20

    await prefs.setStringList(_activityKey, logs);

    // Sync to cloud (fire & forget)
    saveProgressToCloud(_activityKey, logs);
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(_activityKey) ?? [];

    // If empty locally, we rely on the main 'syncProgressFromCloud'
    // to have populated it if it existed in cloud.

    return logs
        .map((e) {
          try {
            return jsonDecode(e) as Map<String, dynamic>;
          } catch (e) {
            return <String, dynamic>{};
          }
        })
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> saveHighScore(String gameId, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHigh = prefs.getInt('highscore_$gameId') ?? 0;
    if (score > currentHigh) {
      await prefs.setInt('highscore_$gameId', score);
      await saveProgressToCloud('highscore_$gameId', score);
    }
  }

  Future<bool> addXp(int amount) async {
    final normalizedAmount = XpRewardPolicy.normalize(amount);
    if (normalizedAmount <= 0) return false;

    final prefs = await SharedPreferences.getInstance();
    int level =
        prefs.getInt('user_xp_level') ?? prefs.getInt('user_level') ?? 1;
    if (prefs.getInt('user_xp_level') == null &&
        prefs.getInt('user_level') != null) {
      await prefs.setInt('user_xp_level', level);
    }
    int currentXp = prefs.getInt('user_current_xp') ?? 0;
    int totalXp = prefs.getInt('user_total_xp') ?? 0;

    currentXp += normalizedAmount;
    totalXp += normalizedAmount;

    // Level Up Check
    int requiredXp = XpRewardPolicy.requiredXpForLevel(level);
    bool leveledUp = false;
    while (currentXp >= requiredXp) {
      currentXp -= requiredXp;
      level++;
      requiredXp = XpRewardPolicy.requiredXpForLevel(level);
      leveledUp = true;
    }

    await prefs.setInt('user_xp_level', level);
    await prefs.setInt('user_current_xp', currentXp);
    await prefs.setInt('user_total_xp', totalXp);

    // Sync (Fire & Forget)
    saveProgressToCloud('user_xp_level', level);
    saveProgressToCloud('user_level', level);
    saveProgressToCloud('user_total_xp', totalXp);

    return leveledUp;
  }

  Future<void> markItemAsLearned(String type, String id) async {
    final prefs = await SharedPreferences.getInstance();
    String key = type == 'verb' ? 'learned_verbs_ids' : 'learned_vocab_ids';
    List<String> current = prefs.getStringList(key) ?? [];
    if (!current.contains(id)) {
      current.add(id);
      await prefs.setStringList(key, current);
      // Cloud Sync (FIX 1)
      saveProgressToCloud(key, current);
    }
  }
}
