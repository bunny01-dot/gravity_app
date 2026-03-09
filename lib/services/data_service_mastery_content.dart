part of 'data_service.dart';

extension DataServiceMasteryContent on DataService {
  // Reading Logic
  Future<void> _loadReadingData() async {
    final level = await _getLevelSuffix();
    if (_cachedReadingData != null &&
        _cachedReadingData!.isNotEmpty &&
        _cachedReadingLevel == level) {
      return;
    }
    if (_readingLoadFuture != null) {
      await _readingLoadFuture;
      return;
    }

    final future = _loadReadingDataInternal(level);
    _readingLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_readingLoadFuture, future)) {
        _readingLoadFuture = null;
      }
    }
  }

  Future<void> _loadReadingDataInternal(String level) async {
    if (_cachedReadingData != null &&
        _cachedReadingData!.isNotEmpty &&
        _cachedReadingLevel == level) {
      return;
    }

    // Check Prefs
    await _loadLocalDataIfExists('reading');
    if (_cachedReadingData != null &&
        _cachedReadingData!.isNotEmpty &&
        _cachedReadingLevel == level) {
      return;
    }

    try {
      final String rawData = await rootBundle.loadString(
        'assets/reading_exercises.csv',
      );
      final rows = normalizeReadingRows(parseCsvRows(rawData));
      _cachedReadingData = _filterRowsByLevel(
        rows,
        levelColumnIndex: 7,
        level: level,
      );
      _cachedReadingLevel = level;
    } catch (e) {
      debugPrint("Error loading reading data: $e");
      _cachedReadingData = [];
      _cachedReadingLevel = level;
    }
  }

  Future<List<Map<String, String>>> getReadingExercises() async {
    await _loadReadingData();
    if (_cachedReadingData == null || _cachedReadingData!.isEmpty) return [];

    return mapReadingExercises(_cachedReadingData!);
  }

  // Writing Logic
  Future<void> _loadWritingData() async {
    final level = await _getLevelSuffix();
    if (_cachedWritingData != null &&
        _cachedWritingData!.isNotEmpty &&
        _cachedWritingLevel == level) {
      return;
    }
    if (_writingLoadFuture != null) {
      await _writingLoadFuture;
      return;
    }

    final future = _loadWritingDataInternal(level);
    _writingLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_writingLoadFuture, future)) {
        _writingLoadFuture = null;
      }
    }
  }

  Future<void> _loadWritingDataInternal(String level) async {
    if (_cachedWritingData != null &&
        _cachedWritingData!.isNotEmpty &&
        _cachedWritingLevel == level) {
      return;
    }
    await _loadLocalDataIfExists('writing');
    if (_cachedWritingData != null &&
        _cachedWritingData!.isNotEmpty &&
        _cachedWritingLevel == level) {
      return;
    }

    try {
      final String rawData = await rootBundle.loadString(
        'assets/writing_exercises.csv', // Fixed filename
      );
      final rows = normalizeWritingRows(parseCsvRows(rawData));
      _cachedWritingData = _filterRowsByLevel(
        rows,
        levelColumnIndex: 1,
        level: level,
      );
      _cachedWritingLevel = level;
    } catch (e) {
      debugPrint("Error loading writing data: $e");
      _cachedWritingData = [];
      _cachedWritingLevel = level;
    }
  }

  Future<List<Map<String, String>>> getWritingPrompts() async {
    return getWritingExercises(); // Alias for compatibility if needed or fix naming
  }

  Future<List<Map<String, String>>> getWritingExercises() async {
    await _loadWritingData();
    if (_cachedWritingData == null || _cachedWritingData!.isEmpty) return [];

    return mapWritingExercises(_cachedWritingData!);
  }

  // Listening Logic
  Future<void> _loadListeningData() async {
    final level = await _getLevelSuffix();
    if (_cachedListeningData != null &&
        _cachedListeningData!.isNotEmpty &&
        _cachedListeningLevel == level) {
      return;
    }
    if (_listeningLoadFuture != null) {
      await _listeningLoadFuture;
      return;
    }

    final future = _loadListeningDataInternal(level);
    _listeningLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_listeningLoadFuture, future)) {
        _listeningLoadFuture = null;
      }
    }
  }

  Future<void> _loadListeningDataInternal(String level) async {
    if (_cachedListeningData != null &&
        _cachedListeningData!.isNotEmpty &&
        _cachedListeningLevel == level) {
      return;
    }
    await _loadLocalDataIfExists('listening');
    if (_cachedListeningData != null &&
        _cachedListeningData!.isNotEmpty &&
        _cachedListeningLevel == level) {
      return;
    }

    try {
      final String rawData = await rootBundle.loadString(
        'assets/listening_exercises.csv',
      );
      final rows = normalizeListeningRows(parseCsvRows(rawData));
      _cachedListeningData = _filterRowsByLevel(
        rows,
        levelColumnIndex: 7,
        level: level,
      );
      _cachedListeningLevel = level;
    } catch (e) {
      debugPrint("Error loading listening data: $e");
      _cachedListeningData = [];
      _cachedListeningLevel = level;
    }
  }

  Future<List<Map<String, String>>> getListeningExercises() async {
    await _loadListeningData();
    if (_cachedListeningData == null || _cachedListeningData!.isEmpty) {
      return [];
    }

    return mapListeningExercises(_cachedListeningData!);
  }

  // Speaking Logic
  Future<void> _loadSpeakingData() async {
    final level = await _getLevelSuffix();
    if (_cachedSpeakingData != null &&
        _cachedSpeakingData!.isNotEmpty &&
        _cachedSpeakingLevel == level) {
      return;
    }
    if (_speakingLoadFuture != null) {
      await _speakingLoadFuture;
      return;
    }

    final future = _loadSpeakingDataInternal(level);
    _speakingLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_speakingLoadFuture, future)) {
        _speakingLoadFuture = null;
      }
    }
  }

  Future<void> _loadSpeakingDataInternal(String level) async {
    if (_cachedSpeakingData != null &&
        _cachedSpeakingData!.isNotEmpty &&
        _cachedSpeakingLevel == level) {
      return;
    }
    await _loadLocalDataIfExists('speaking');
    if (_cachedSpeakingData != null &&
        _cachedSpeakingData!.isNotEmpty &&
        _cachedSpeakingLevel == level) {
      return;
    }

    try {
      final String rawData = await rootBundle.loadString(
        'assets/speaking_exercises.csv',
      );
      final rows = normalizeSpeakingRows(parseCsvRows(rawData));
      _cachedSpeakingData = _filterRowsByLevel(
        rows,
        levelColumnIndex: 2,
        level: level,
      );
      _cachedSpeakingLevel = level;
    } catch (e) {
      debugPrint("Error loading speaking data: $e");
      _cachedSpeakingData = [];
      _cachedSpeakingLevel = level;
    }
  }

  Future<List<Map<String, String>>> getSpeakingScenarios() async {
    return getSpeakingExercises();
  }

  Future<List<Map<String, String>>> getSpeakingExercises() async {
    await _loadSpeakingData();
    if (_cachedSpeakingData == null || _cachedSpeakingData!.isEmpty) return [];

    return mapSpeakingExercises(_cachedSpeakingData!);
  }

  // Quiz Logic
  Future<void> _loadQuizData() async {
    if (_cachedQuizData != null && _cachedQuizData!.isNotEmpty) return;
    if (_quizLoadFuture != null) {
      await _quizLoadFuture;
      return;
    }

    final future = _loadQuizDataInternal();
    _quizLoadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_quizLoadFuture, future)) {
        _quizLoadFuture = null;
      }
    }
  }

  Future<void> _loadQuizDataInternal() async {
    if (_cachedQuizData != null && _cachedQuizData!.isNotEmpty) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/quiz_data.csv');
    bool loadedFromFile = false;

    // 1. Check Cloud-Synced Local File
    try {
      if (await file.exists()) {
        final content = await file.readAsString();
        _cachedQuizData = parseCsvRows(content);
        if (_cachedQuizData!.isNotEmpty) {
          debugPrint("DataService: Loaded quiz data from LOCAL FILE.");
          loadedFromFile = true;
          // Remove header if needed
          if (_cachedQuizData![0][0].toString().toLowerCase().contains(
            'lesson',
          )) {
            // Logic for removing header or keeping it?
            // Curriculum Screen logic expects header logic or checking,
            // but here we just convert to simple list.
            // We'll leave raw rows for now.
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Error loading local quiz file: $e");
    }

    // 1b. Try Cloud Sync if local file is missing/empty
    if (!loadedFromFile) {
      try {
        await DataServiceCloudSync(this).syncQuizDataFromCloud();
        if (await file.exists()) {
          final content = await file.readAsString();
          _cachedQuizData = parseCsvRows(content);
          if (_cachedQuizData!.isNotEmpty) {
            debugPrint("DataService: Loaded quiz data after CLOUD SYNC.");
            return;
          }
        }
      } catch (e) {
        debugPrint("DataService: Quiz cloud sync failed: $e");
      }
    }

    // 2. Check Prefs (Legacy Custom Edits)
    await _loadLocalDataIfExists('quiz');
    if (_cachedQuizData != null && _cachedQuizData!.isNotEmpty) return;

    // 3. Fallback to bundled assets
    _cachedQuizData = [];
    final assetCandidates = <String>[
      'assets/quiz_data.csv',
      'assets/data/quiz_data.csv',
    ];
    for (final assetPath in assetCandidates) {
      try {
        final rawData = await rootBundle.loadString(assetPath);
        final parsed = parseCsvRows(rawData);
        if (parsed.isNotEmpty) {
          _cachedQuizData = parsed;
          debugPrint("DataService: Loaded quiz data from ASSET ($assetPath).");
          break;
        }
      } catch (_) {
        // Try next asset path.
      }
    }

    if (_cachedQuizData == null || _cachedQuizData!.isEmpty) {
      if (kDebugMode) {
        _cachedQuizData = _buildDebugFallbackQuizRows();
        debugPrint(
          "DataService: Quiz CSV missing. Using DEBUG fallback quiz rows.",
        );
      } else {
        debugPrint(
          "DataService: Quiz data missing. Check assets/quiz_data.csv registration and cloud sync.",
        );
      }
    }
  }

  List<List<dynamic>> _buildDebugFallbackQuizRows() {
    final rows = <List<dynamic>>[];
    final lessons = getCurriculumLessonsData();

    for (final lesson in lessons) {
      final lessonTitle = (lesson['title'] ?? '').trim();
      if (lessonTitle.isEmpty) continue;
      final topic = (lesson['topic'] ?? 'English grammar').trim();

      rows.add([lessonTitle]);
      rows.add([
        'question',
        'option_a',
        'option_b',
        'option_c',
        'option_d',
        'answer',
      ]);
      rows.add([
        'Which topic is covered in $lessonTitle?',
        topic,
        'Arithmetic',
        'Geography',
        'Cooking',
        'A',
      ]);
      rows.add([
        'Pick the best statement for this lesson.',
        'This lesson improves English usage.',
        'This lesson is about robotics hardware.',
        'This lesson is only about math formulas.',
        'This lesson is only about painting.',
        'A',
      ]);
    }

    return rows;
  }

  Future<List<List<dynamic>>> getRawQuizData() async {
    await _loadQuizData();
    return _cachedQuizData ?? [];
  }

  Future<List<Map<String, String>>> getQuizQuestions() async {
    await _loadQuizData();
    if (_cachedQuizData == null || _cachedQuizData!.isEmpty) return [];

    return mapQuizQuestions(_cachedQuizData!);
  }
}
