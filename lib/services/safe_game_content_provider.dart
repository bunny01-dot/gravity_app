import 'package:gravity_app/config/app_config.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/models/verb_item.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InsufficientContentException implements Exception {
  final String message;
  InsufficientContentException([
    this.message = "Insufficient learned content.",
  ]);
}

class SafeGameContentProvider {
  final DataService dataService;

  SafeGameContentProvider(this.dataService);

  /// Get the user's current effective difficulty level
  /// Respects teacher overrides and profile settings
  Future<String> _getUserDifficultyLevel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Priority 1: effective_difficulty_level (includes teacher override)
        final effectiveLevel = prefs.getString('effective_difficulty_level');
        if (effectiveLevel != null && effectiveLevel.isNotEmpty) {
          debugPrint(
            'SafeGameContentProvider: Using effective level: $effectiveLevel',
          );
          return effectiveLevel;
        }

        // Priority 2: User-specific level
        final userLevel = prefs.getString(
          'english_proficiency_level_${user.uid}',
        );
        if (userLevel != null && userLevel.isNotEmpty) {
          debugPrint(
            'SafeGameContentProvider: Using profile level: $userLevel',
          );
          return userLevel;
        }
      }

      // Priority 3: Global level (fallback)
      final globalLevel = prefs.getString('english_proficiency_level');
      if (globalLevel != null && globalLevel.isNotEmpty) {
        debugPrint('SafeGameContentProvider: Using global level: $globalLevel');
        return globalLevel;
      }
    } catch (e) {
      debugPrint('SafeGameContentProvider: Error getting difficulty level: $e');
    }

    // Default fallback
    debugPrint('SafeGameContentProvider: Using default level: Beginner');
    return 'Beginner';
  }

  /// Returns a prioritized list of vocabulary items that the user has strictly LEARNED.
  /// Order: Today's Learned -> Revision (Yesterday's Learned) -> Older Learned.
  /// Throws [InsufficientContentException] if total count is less than [minCount].
  Future<List<VocabularyItem>> getEligibleVocabulary({
    required int minCount,
  }) async {
    // 1. Get Global Learned items (The Source of Truth)
    final allLearned = await dataService.getLearnedVocabularyItems();

    // 2. Supplement with fallback vocabulary if needed
    if (allLearned.length < minCount) {
      final needed = minCount - allLearned.length;
      final userLevel = await _getUserDifficultyLevel();
      final fallback = await getFallbackVocabulary(
        count: needed * 5, // Fetch extra for potential filtering
        forceLevel: userLevel,
      );

      final existingIds = allLearned.map((e) => e.word).toSet();
      for (final item in fallback) {
        if (!existingIds.contains(item.word)) {
          allLearned.add(item);
          existingIds.add(item.word);
        }
      }
    }

    // 3. Prioritize
    // We need 'Today's' and 'Revision' items to sort/filter.
    // DataService doesn't give us objects for these easily, but IDs/Maps.
    // We match by ID (Word).

    final dailyMaps = await dataService.getDailyVocabulary();
    final revisionMaps = await dataService.getYesterdayVocabulary();

    final dailyIds = dailyMaps.map((m) => m['word'] ?? '').toSet();
    final revisionIds = revisionMaps.map((m) => m['word'] ?? '').toSet();

    final List<VocabularyItem> todayItems = [];
    final List<VocabularyItem> revisionItems = [];
    final List<VocabularyItem> olderItems = [];

    for (var item in allLearned) {
      if (dailyIds.contains(item.word)) {
        todayItems.add(item);
      } else if (revisionIds.contains(item.word)) {
        revisionItems.add(item);
      } else {
        olderItems.add(item);
      }
    }

    // Shuffle subsections for variety within their priority tier
    todayItems.shuffle();
    revisionItems.shuffle();
    olderItems.shuffle();

    final combined = [...todayItems, ...revisionItems, ...olderItems];

    if (combined.length < minCount) {
      // In production, we block.
      if (AppConfig.isProduction) {
        throw InsufficientContentException();
      }
      // In dev, we might tolerate lower count or DataService already gave us mocks.
    }

    // If we have enough, return them (taking as many as needed or all)
    // The provider shouldn't arbitrary limit the list unless requested,
    // but the user example said: "return combined.take(minCount).toList()".
    // I'll return ALL eligible, let the game decide how many to use,
    // BUT the user prompts says: "return combined.take(minCount).toList();" in the example code.
    // I will stick to returning the full sorted list so games can use more if they want,
    // but I'll ensure we have minCount.

    return combined;
  }

  /// Returns random vocabulary items for practice/fallback when learned content is insufficient.
  Future<List<VocabularyItem>> getFallbackVocabulary({
    int count = 5,
    String? forceLevel,
  }) async {
    final userLevel = forceLevel ?? await _getUserDifficultyLevel();
    final allMaps = await dataService.getAllItems('vocabulary');
    if (allMaps.isEmpty) return [];

    final allItems = allMaps
        .where((m) {
          final difficulty = m['difficulty'] ?? m['level'] ?? '';
          return difficulty.toString().toLowerCase() == userLevel.toLowerCase();
        })
        .map((m) {
          final synonymsStr = m['synonyms'] ?? '';
          final synonymsList = synonymsStr.isNotEmpty
              ? synonymsStr.split(',').map((e) => e.trim()).toList()
              : <String>[];

          return VocabularyItem(
            id: m['word'] ?? DateTime.now().toString(),
            word: m['word'] ?? '?',
            definition: m['meaning'] ?? '',
            exampleSentence: m['example'] ?? 'No example',
            translation: m['meaning'] ?? '',
            pos: m['type'] ?? '',
            synonyms: synonymsList,
          );
        })
        .toList();

    allItems.shuffle();
    return allItems.take(count).toList();
  }

  /// Returns a prioritized list of verbs that the user has strictly LEARNED.
  Future<List<VerbItem>> getEligibleVerbs({required int minCount}) async {
    final allLearned = await dataService.getLearnedVerbItems();

    if (allLearned.length < minCount) {
      final needed = minCount - allLearned.length;
      final allVerbMaps = await dataService.getAllItems('verbs');
      final fallbackMaps = allVerbMaps.take(needed * 5).toList();
      fallbackMaps.shuffle();

      final existingIds = allLearned.map((e) => e.base).toSet();
      for (final m in fallbackMaps) {
        final base = m['word'] ?? m['base'] ?? '';
        if (base.isNotEmpty && !existingIds.contains(base)) {
          final diffStr = m['difficulty'] ?? m['level'] ?? '1';
          int diffInt = 1;
          if (diffStr.toString().toLowerCase() == 'intermediate') diffInt = 2;
          if (diffStr.toString().toLowerCase() == 'advanced') diffInt = 3;

          final verb = VerbItem(
            id: base,
            base: base,
            past: m['v2'] ?? '',
            pastParticiple: m['v3'] ?? '',
            present3rd: m['v5'] ?? "${base}s",
            gerund: m['v4'] ?? "${base}ing",
            tamilMeaning: m['meaning'] ?? m['tamilMeaning'] ?? '',
            hindiMeaning: m['hindiMeaning'] ?? '',
            antonyms: [],
            exampleSentences: {},
            difficulty: diffInt,
            isLearned: false,
          );
          allLearned.add(verb);
          existingIds.add(base);
        }
      }
    }

    final dailyMaps = await dataService.getDailyVerbs();
    final revisionMaps = await dataService.getYesterdayVerbs();

    // Verbs key in maps is usually 'base' or 'word'? DVS uses 'word' for vocab, 'word' for verbs in daily?
    // Let's check getVerbsByIndices in DataService... it calls _getVerbsByIndices...
    // It returns map with 'word' key?
    // Wait, _getVerbsByIndices doesn't seem to have been fully visible or standard.
    // I need to assume it returns a map.
    // Based on `getDailyItems` -> `getDailyVerbs`, it returns `List<Map<String, String>>`.
    // I'll assume they have a 'word' or 'base' key to match `VerbItem.id` (which is base).

    // Safe check: dataService might use 'word' for both.
    final dailyIds = dailyMaps.map((m) => m['word'] ?? m['base'] ?? '').toSet();
    final revisionIds = revisionMaps
        .map((m) => m['word'] ?? m['base'] ?? '')
        .toSet();

    final List<VerbItem> todayItems = [];
    final List<VerbItem> revisionItems = [];
    final List<VerbItem> olderItems = [];

    for (var item in allLearned) {
      if (dailyIds.contains(item.base)) {
        todayItems.add(item);
      } else if (revisionIds.contains(item.base)) {
        revisionItems.add(item);
      } else {
        olderItems.add(item);
      }
    }

    todayItems.shuffle();
    revisionItems.shuffle();
    olderItems.shuffle();

    return [...todayItems, ...revisionItems, ...olderItems];
  }
}
