import 'dart:convert';

import 'dart:io';

import 'package:gravity_app/features/daily_sentences/daily_sentence_model.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:csv/csv.dart';

import 'package:flutter/services.dart'; // For rootBundle

import 'package:flutter/foundation.dart'; // For debugPrint

import 'package:firebase_auth/firebase_auth.dart';

import 'package:gravity_app/services/placement_state_service.dart';

import 'package:gravity_app/services/stage_content_service.dart';

import 'package:gravity_app/services/stage_progress_service.dart';

import 'package:path_provider/path_provider.dart';

import 'package:http/http.dart' as http;

class DailySentenceService {
  static final DailySentenceService _instance =
      DailySentenceService._internal();

  factory DailySentenceService() => _instance;

  DailySentenceService._internal();

  static const String _storageKey = 'daily_sentences_history';

  static const int _batchSize = 5;

  // Cache

  List<DailySentence> _allSentences = [];
  Future<void>? _loadSentencesFuture;
  String? _lastLoadedSignature;

  // Local History

  Map<String, String> _userHistory = {};

  final StageProgressService _stageService = StageProgressService();

  final StageContentService _contentService = StageContentService();

  Future<void> init() async {
    await _loadUserHistory();

    await _loadSentences();
  }

  Future<void> _loadSentences() async {
    if (_loadSentencesFuture != null) {
      await _loadSentencesFuture;
      return;
    }

    final future = _loadSentencesInternal();
    _loadSentencesFuture = future;
    try {
      await future;
    } finally {
      if (identical(_loadSentencesFuture, future)) {
        _loadSentencesFuture = null;
      }
    }
  }

  Future<void> _loadSentencesInternal() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest';

    // 1. Determine level and stage/day mapping.
    final difficulty = await PlacementStateService.getCourseLevelSuffix();
    final stage = await _stageService.getCurrentStage();
    final batchIndex = prefs.getInt('daily_sentences_batch_stage_$stage') ?? 0;
    final dayNumber = await _contentService.resolveDayForStage(stage);
    final dayLabel = 'Day $dayNumber';
    final signature = '$userId|$difficulty|$stage|$dayNumber|$batchIndex';

    if (_allSentences.isNotEmpty && _lastLoadedSignature == signature) {
      return;
    }

    debugPrint(
      "DailySentences: Loading for $difficulty, $dayLabel (User: $userId)",
    );

    try {
      String csvData;

      // 2. Check for locally saved CSV first (synced from web).
      final directory = await getApplicationDocumentsDirectory();
      final localFile = File(
        '${directory.path}/daily_sentences_$difficulty.csv',
      );
      bool loadedFromLocal = false;

      if (await localFile.exists()) {
        debugPrint(" DailySentences: Loading from LOCAL FILE ($difficulty)");
        csvData = await localFile.readAsString();
        loadedFromLocal = true;
      } else {
        debugPrint(" DailySentences: Loading from ASSET ($difficulty)");
        final csvPath =
            'assets/Master Sheets/Daily Sentences - $difficulty - Sheet.csv';
        csvData = await rootBundle.loadString(csvPath);
      }

      List<List<dynamic>> rows = const CsvToListConverter().convert(
        csvData,
        eol: '\n',
      );

      if (rows.isNotEmpty &&
          rows[0][0].toString().toLowerCase().contains('day')) {
        rows.removeAt(0);
      }

      List<List<dynamic>> pickRows(List<List<dynamic>> sourceRows) {
        final lowerDayLabel = dayLabel.toLowerCase();
        final dayRows = sourceRows.where((row) {
          if (row.isEmpty) return false;
          final rowDay = row[0].toString().trim().toLowerCase();
          return rowDay == lowerDayLabel;
        }).toList();

        final nonEmptyRows = sourceRows.where((row) => row.isNotEmpty).toList();
        final availableRows = dayRows.length > _batchSize
            ? dayRows
            : nonEmptyRows;
        if (availableRows.isEmpty) return [];

        final totalBatches = (availableRows.length / _batchSize).ceil();
        final normalizedBatch = totalBatches <= 0
            ? 0
            : batchIndex % totalBatches;
        final start = normalizedBatch * _batchSize;

        final selection = availableRows
            .skip(start)
            .take(_batchSize)
            .toList(growable: true);
        if (selection.length < _batchSize) {
          selection.addAll(availableRows.take(_batchSize - selection.length));
        }
        return selection;
      }

      var rowsToUse = pickRows(rows);

      // Ensure 5 sentences even if local CSV is incomplete.
      if (loadedFromLocal && rowsToUse.length < _batchSize) {
        debugPrint(
          "DailySentences: Local CSV returned ${rowsToUse.length} rows, falling back to ASSET.",
        );
        final csvPath =
            'assets/Master Sheets/Daily Sentences - $difficulty - Sheet.csv';
        final assetData = await rootBundle.loadString(csvPath);
        final assetRows = const CsvToListConverter().convert(
          assetData,
          eol: '\n',
        );

        if (assetRows.isNotEmpty &&
            assetRows[0][0].toString().toLowerCase().contains('day')) {
          assetRows.removeAt(0);
        }

        rowsToUse = pickRows(assetRows);
      }

      if (rowsToUse.isNotEmpty && rowsToUse.length < _batchSize) {
        final originalRows = List<List<dynamic>>.from(rowsToUse);
        int i = 0;
        while (rowsToUse.length < _batchSize) {
          rowsToUse.add(originalRows[i % originalRows.length]);
          i++;
        }
      }

      _allSentences = rowsToUse
          .asMap()
          .entries
          .map(
            (entry) => DailySentence.fromCsv(entry.value, rowIndex: entry.key),
          )
          .toList();
      _lastLoadedSignature = signature;
      debugPrint(
        "OK: DailySentences: Loaded ${_allSentences.length} sentences.",
      );
    } catch (e) {
      debugPrint("Error: DailySentences: Error loading CSV: $e");
      _allSentences = [];
      _lastLoadedSignature = null;
    }
  }

  Future<bool> importCsvFromUrl(String url, String difficulty) async {
    try {
      debugPrint("[WEB] DailySentences: Syncing $difficulty from $url");

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();

        final localFile = File(
          '${directory.path}/daily_sentences_$difficulty.csv',
        );

        await localFile.writeAsBytes(response.bodyBytes);

        debugPrint("OK: DailySentences: Saved $difficulty CSV locally.");

        // Reload cache if current level matches
        _lastLoadedSignature = null;
        await _loadSentences();

        return true;
      }

      return false;
    } catch (e) {
      debugPrint("Error: DailySentences: Sync error: $e");

      return false;
    }
  }

  Future<void> _loadUserHistory() async {
    final prefs = await SharedPreferences.getInstance();

    final user = FirebaseAuth.instance.currentUser;

    final userId = user?.uid ?? 'guest';

    final key = '${_storageKey}_$userId';

    final jsonString = prefs.getString(key);

    if (jsonString != null) {
      try {
        _userHistory = Map<String, String>.from(json.decode(jsonString));
      } catch (e) {
        _userHistory = {};
      }
    } else {
      _userHistory = {};
    }
  }

  Future<List<DailySentence>> getDailySentences() async {
    if (_allSentences.isEmpty) {
      await _loadSentences();
    }

    return _allSentences;
  }

  Future<void> markAsSeen(List<DailySentence> sentences) async {
    if (sentences.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    final user = FirebaseAuth.instance.currentUser;

    final userId = user?.uid ?? 'guest';

    final key = '${_storageKey}_$userId';

    final stage = await _stageService.getCurrentStage();

    final stageLabel = 'stage_$stage';

    for (var s in sentences) {
      _userHistory[s.id] = stageLabel;
    }

    await prefs.setString(key, json.encode(_userHistory));
  }

  Future<void> advanceBatchForStage(int stage) async {
    final prefs = await SharedPreferences.getInstance();

    final key = 'daily_sentences_batch_stage_$stage';

    final current = prefs.getInt(key) ?? 0;

    await prefs.setInt(key, current + 1);

    _allSentences.clear();
    _lastLoadedSignature = null;
  }

  Future<void> resetData() async {
    _allSentences.clear();
    _lastLoadedSignature = null;
    _loadSentencesFuture = null;

    _userHistory.clear();

    final prefs = await SharedPreferences.getInstance();

    final user = FirebaseAuth.instance.currentUser;

    final userId = user?.uid ?? 'guest';

    final key = '${_storageKey}_$userId';

    await prefs.remove(key);

    // Also delete local CSV files

    try {
      final directory = await getApplicationDocumentsDirectory();

      for (var diff in ['Beginner', 'Intermediate', 'Advanced']) {
        final file = File('${directory.path}/daily_sentences_$diff.csv');

        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint("[WARN] DailySentenceService: Error deleting local CSVs: $e");
    }

    debugPrint("[CLEAN] DailySentenceService: Data and history cleared.");
  }
}
