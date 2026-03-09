import 'dart:io';

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'package:path_provider/path_provider.dart';

import 'package:path/path.dart' as path;

import 'package:archive/archive.dart';

import 'lesson_registry.dart';

enum LessonContentStatus { notDownloaded, downloading, ready, error }

class LessonContentService {
  static final LessonContentService _instance =
      LessonContentService._internal();

  factory LessonContentService() => _instance;

  LessonContentService._internal();

  // Observable status for UI updates

  final Map<String, ValueNotifier<LessonContentStatus>> _statusNotifiers = {};

  final Map<String, ValueNotifier<double>> _progressNotifiers = {};

  // ===========================================================================

  //  CLOUD MANIFEST

  // Mapping ZipKey -> Direct Download URL (OneDrive "download=1" style)

  // ===========================================================================

  final Map<String, String> _lessonManifest = {
    // ROW 1
    'group_past_tense':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQS7YIMPh76UTrUIP7EfUrNXARGQzBqrFWKSJ1P8jhxgeGM?download=1',

    'group_future_tense':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQStK6yAbKZyT5u8Xs0vG_R6AUczwSd8Hnhge84PPLad4yg?download=1',

    'group_present_tense':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQSiMFJxPz8qQZsZ4VNfhoueAdeC2yCpGldUaynOLVh0tSY?download=1',

    'lesson_articles':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQSFtXSFzYzpSoMMb3hxT9nfAQRmtFTYmRL-e-Zq0yfXZRU?download=1',

    'lesson_irregular_verbs':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQTsWmoTivXDTZxNjmpS5ho3AdL5Q7XyaPHy0fqkj5YaBCA?download=1',

    'lesson_2_parts_of_speech':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQSLqp1rxD21RqpbtcwwEvlfAXf7E6TSM3YI3b3NSXI9_Bg?download=1',

    'lesson_verbal_nouns':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQQ4tjG8RJSyQIFRKItuBGaGAZwXcnJkykR4oeKChPNsNaU?download=1',

    'lesson_subject_verb_agreement':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQRHDHabsQutT6KfP8cjPv1uAfyPz54s7qt-YFHFcwR2ydA?download=1',

    // ROW 2
    'lesson_reported_questions':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQQF9GTGPQNXSpRIlaQn3HtzASPAZyrtH8N1e7GO2iYb7ck?download=1',

    'lesson_prepositions':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQQPxOZKlg4CTojIGQWMDQxJAZre__ErFSBy2U9umbN-TUw?download=1',

    'lesson_punctuation':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQQFDXg6iM6ISJokc4i9DqxtAVktXp89v6qBjltVZaF2rjM?download=1',

    'lesson_prefixes_suffixes':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQTtA4ApXBtLSYKOyAhkJm88AVe1n881cYTFu0ei3IXb6wo?download=1',

    'lesson_phrasal_verbs':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQRsTysLjlHvS4bFGv0ozC7TAdxZYNQRB56icgHFznRe1RY?download=1',

    'lesson_idioms':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQShlGadpQitR7efpWQt9Ny3AZvF-ujzYA9-4063Fg4sPDs?download=1',

    'lesson_infinitives_participles':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQROMGiiQmXVSJo1Q3mYZ6JGAfLcCQj8-ruVX5NyuW8VwmI?download=1',

    'lesson_direct_indirect_speech':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQR77gGsU1YYRY6XReFDNnBaAVYDQmo2oA0hKYVJc7EeE_Y?download=1',

    // ROW 3
    'lesson_determiners':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQQlAvRauX5mTYEiWlxlhORtAb2gc4-vskOAo7q1WgpLa2Y?download=1',

    'lesson_correlative_conjunctions':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQQu-t2ApVOdTLbRN0DHp1wKAZ9AsFzfIMXlszEsAT3Dsns?download=1',

    'lesson_comparatives':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQRMoQJx0L6QQqbg915ldBiFASKaGXiimC41DmQBbfoAQpQ?download=1',

    'lesson_conditionals':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQRAVCi_EwgzS4WQq4dnssGxAb0--blsN33iZKYe3rBkDDw?download=1',

    'lesson_linking_words':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQQyE1dE4cSaRZ_bYwP2H07jAVFUweWWyDariFoyDZNa7xw?download=1',

    'lesson_adverbs':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQT3-n59rFWwT4sIu8LGtMptAXKAJJdQOCgPxGcUB8P1CC0?download=1',

    'lesson_active_passive':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQTDQ8l-kqNQTr5yvr0CN1JCAbINF8Of0Hn0uSQpBYrXTfM?download=1',

    'lesson_relative_pronoun':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQQOItzzCtXjQ4ZxdrFsdCm4AReffG74CI6R8k7mqr0ZDaA?download=1',

    // ROW 4
    'lesson_question_types':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQQw8hgVukz2QowWy7m49Cc8AQVP4wv8NsfgbmppqjSwKes?download=1',

    'lesson_sentence_patterns':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQT-4txloawPS73G_z_LD0QtAe6X7cS9z0BbGrxjV7BvMS8?download=1',

    'lesson_types_of_sentences':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQTFgVga8gD5RoXWH-WQRt7TAUmd-yGBoRO3PCEjmuO1zZg?download=1',

    'lesson_modal_verbs':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQQWWR3vtjJ-RbSGvYbUklUtAQG11uXzIgJiTQNDcQoSVtw?download=1',

    'lesson_1_subjects':
        'https://1drv.ms/u/c/dca3937b157b5f79/IQQXUGEeEzZoSpZGyjtF6in2AbwVeX10yhoit9AUJSuoEi0?download=1',
  };

  // ===========================================================================

  //  LOCATION MAP

  // Where to find the files LOCALLY once extracted.

  // ===========================================================================

  final Map<String, String> _lessonFolderMap = {
    // Basic
    'lesson_1_subjects': 'Lesson_01_Subjects',

    'lesson_2_parts_of_speech': 'Lesson_02_PartsOfSpeech',

    // Tenses (Nested in groups)
    'simple_present': 'Lesson_03_Tense_Present/01_Simple_Present',

    'present_continuous':
        'Lesson_03_Tense_Present/02_Continuous_Present', // Corrected path assumption

    'present_perfect': 'Lesson_03_Tense_Present/03_Perfect_Present',

    'present_perfect_continuous':
        'Lesson_03_Tense_Present/04_Perfect_Continuous_Present',

    'simple_past': 'Lesson_04_Tense_Past/01_Simple_Past',

    'past_continuous': 'Lesson_04_Tense_Past/02_Past_Continuous',

    'past_perfect': 'Lesson_04_Tense_Past/03_Past_Perfect',

    'past_perfect_continuous':
        'Lesson_04_Tense_Past/04_Past_Perfect_Continuous',

    'simple_future': 'Lesson_05_Tense_Future/01_Simple_Future',

    'future_continuous': 'Lesson_05_Tense_Future/02_Future_Continuous',

    'future_perfect': 'Lesson_05_Tense_Future/03_Future_Perfect',

    'future_perfect_continuous':
        'Lesson_05_Tense_Future/04_Future_Perfect_Continuous',

    // Advanced & Others
    'lesson_articles': 'Lesson_03_Articles',

    'lesson_sentence_patterns': 'Lesson_07_Sentence_Patterns',

    'lesson_types_of_sentences': 'Lesson_08_Types_of_Sentences',

    'lesson_modal_verbs': 'Lesson_09_Modal_Verbs',

    'lesson_subject_verb_agreement': 'Lesson_Subject_Verb_Agreement',

    'lesson_phrasal_verbs': 'Lesson_Phrasal_Verbs',

    'lesson_active_passive': 'Lesson_12_Active_Passive',

    'lesson_correlative_conjunctions': 'Lesson_Correlative_Conjunctions',

    'lesson_question_types': 'Lesson_14_Question_Types',

    'lesson_irregular_verbs': 'Lesson_15_Irregular_Verbs',

    'lesson_prefixes_suffixes': 'Lesson_Prefixes_Suffixes',

    'lesson_relative_pronoun': 'Lesson_16_Relative_Pronoun',

    'lesson_comparatives': 'Lesson_Comparatives',

    'lesson_punctuation': 'Lesson_Punctuation',

    'lesson_direct_indirect_speech': 'Lesson_Direct_Indirect_Speech',

    'lesson_idioms': 'Lesson_Idioms',

    'lesson_determiners': 'Lesson_Determiners',

    'lesson_prepositions': 'Lesson_Prepositions',

    'lesson_conditionals': 'Lesson_Conditionals',

    'lesson_infinitives_participles': 'Lesson_Infinitives_Participles',

    'lesson_reported_questions': 'Lesson_Reported_Questions',

    'lesson_verbal_nouns': 'Lesson_Verbal_Nouns',

    'lesson_adverbs': 'Lesson_27_Adverbs',

    'lesson_linking_words': 'Lesson_28_Linking_Words',

    'lesson_2_articles': 'Lesson_03_Articles',

    // Aliases for Cloud Migration (Clean IDs)
    'subjects': 'Lesson_01_Subjects',

    'parts_of_speech': 'Lesson_02_PartsOfSpeech',

    'articles': 'Lesson_03_Articles',

    'active_passive': 'Lesson_12_Active_Passive',
  };

  /// Get the mapped folder name for a lesson ID

  String getMappedFolder(String lessonId) {
    return _lessonFolderMap[lessonId] ?? lessonId;
  }

  // ===========================================================================

  //  ZIP PARENT MAP

  // Maps a LessonID to which ZipKey it belongs to.

  // If not in this list, LessonID == ZipKey.

  // ===========================================================================

  final Map<String, String> _zipParentMap = {
    // Present
    'simple_present': 'group_present_tense',

    'present_continuous': 'group_present_tense',

    'present_perfect': 'group_present_tense',

    'present_perfect_continuous': 'group_present_tense',

    // Past
    'simple_past': 'group_past_tense',

    'past_continuous': 'group_past_tense',

    'past_perfect': 'group_past_tense',

    'past_perfect_continuous': 'group_past_tense',

    // Future
    'simple_future': 'group_future_tense',

    'future_continuous': 'group_future_tense',

    'future_perfect': 'group_future_tense',

    'future_perfect_continuous': 'group_future_tense',

    // Aliases for Cloud Migration (Clean IDs -> Zip Keys)
    'subjects': 'lesson_1_subjects',

    'parts_of_speech': 'lesson_2_parts_of_speech',

    'articles': 'lesson_articles',

    'lesson_2_articles': 'lesson_articles',

    'active_passive': 'lesson_active_passive',
  };

  /// Check status of a lesson

  Future<LessonContentStatus> getStatus(String lessonId) async {
    final zipKey = _zipParentMap[lessonId] ?? lessonId;

    if (_statusNotifiers.containsKey(zipKey)) {
      return _statusNotifiers[zipKey]!.value;
    }

    final isDownloaded = await _isLessonDownloaded(lessonId);

    return isDownloaded
        ? LessonContentStatus.ready
        : LessonContentStatus.notDownloaded;
  }

  /// Get a notifier for UI binding

  ValueNotifier<LessonContentStatus> getStatusNotifier(String lessonId) {
    final zipKey = _zipParentMap[lessonId] ?? lessonId;

    if (!_statusNotifiers.containsKey(zipKey)) {
      _statusNotifiers[zipKey] = ValueNotifier(
        LessonContentStatus.notDownloaded,
      );

      // Initialize async

      _isLessonDownloaded(lessonId).then((exists) {
        if (exists) _statusNotifiers[zipKey]!.value = LessonContentStatus.ready;
      });
    }

    return _statusNotifiers[zipKey]!;
  }

  ValueNotifier<double> getProgressNotifier(String lessonId) {
    final zipKey = _zipParentMap[lessonId] ?? lessonId;

    if (!_progressNotifiers.containsKey(zipKey)) {
      _progressNotifiers[zipKey] = ValueNotifier(0.0);
    }

    return _progressNotifiers[zipKey]!;
  }

  /// Download a specific lesson

  Future<void> downloadLesson(String lessonId) async {
    final zipKey = _zipParentMap[lessonId] ?? lessonId;

    final notifier = getStatusNotifier(lessonId); // Uses zipKey internally

    final progressNotifier = getProgressNotifier(lessonId);

    if (notifier.value == LessonContentStatus.ready ||
        notifier.value == LessonContentStatus.downloading) {
      return;
    }

    final url = _lessonManifest[zipKey];

    if (url == null) {
      debugPrint('[WARN] No URL found for lesson: $lessonId (Zip: $zipKey)');

      return;
    }

    try {
      debugPrint(
        '[DOWN] Starting download for $zipKey (Content for $lessonId)',
      );

      notifier.value = LessonContentStatus.downloading;

      final request = http.Request('GET', Uri.parse(url));

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;

        int received = 0;

        final tempDir = await getTemporaryDirectory();

        final zipFile = File(path.join(tempDir.path, '${zipKey}_temp.zip'));

        if (await zipFile.exists()) await zipFile.delete();

        final sink = zipFile.openWrite();

        await response.stream
            .listen(
              (List<int> chunk) {
                sink.add(chunk);

                received += chunk.length;

                if (contentLength > 0) {
                  progressNotifier.value = received / contentLength;
                }
              },

              onDone: () {},

              onError: (e) {
                throw e;
              },
            )
            .asFuture();

        await sink.close();

        debugPrint(' Download complete. Extracting $zipKey...');

        // Extract

        await _extractLessonIds(zipKey, zipFile);

        // Cleanup

        await zipFile.delete();

        notifier.value = LessonContentStatus.ready;

        debugPrint('OK: Lesson $lessonId (via $zipKey) is ready.');
      } else {
        debugPrint('Error: Failed to download $zipKey: ${response.statusCode}');

        notifier.value = LessonContentStatus.error;
      }
    } catch (e) {
      debugPrint('Error: Error downloading $zipKey: $e');

      notifier.value = LessonContentStatus.error;
    }
  }

  Future<void> _extractLessonIds(String zipKey, File zipFile) async {
    final bytes = await zipFile.readAsBytes();

    final archive = ZipDecoder().decodeBytes(bytes);

    final docDir = await getApplicationDocumentsDirectory();

    final lessonsDir = Directory(path.join(docDir.path, 'lessons_assets'));

    // Determine target based on zipKey triggers

    // BUT! Since we might have multiple folders in one zip (like Group Tenses),

    // we should simply extract everything to 'lessons_assets/RootIfNecessary'.

    // However, we want to maintain the structure defined in _lessonFolderMap.

    // If the zip contains "Lesson_03_Tense_Present", we just drop it in lessons_assets.

    // Auto-detect root folder stripping:

    // If zip has "Lesson_04/01_Simple", we want "lessons_assets/Lesson_04/01_Simple".

    // Let's analyze the zip first.

    // If all files are inside a single top-level folder, we strip it IF it doesn't match our specific needs?

    // Actually, usually user ZIPS the "Lesson_01" folder. So inside zip is "Lesson_01/file.png".

    // We want "lessons_assets/Lesson_01/file.png".

    // So we just extract to lessons_assets directly!

    if (!await lessonsDir.exists()) {
      await lessonsDir.create(recursive: true);
    }

    for (final file in archive) {
      if (!file.isFile) continue;

      String filename = file.name; // e.g. "Lesson_01_Subjects/intro.png"

      // Skip Mac garbage

      if (filename.startsWith('__MACOSX') || filename.contains('/.DS_Store')) {
        continue;
      }

      // We extract to lessonsDir.

      // This preserves "Lesson_01_Subjects" if it's in the zip.

      // If the user zipped the CONTENTS (files only), then filename is "intro.png".

      // Then we need to know where to put it.

      String destinationPath;

      if (filename.contains('/')) {
        // Has folder structure. Good.

        destinationPath = path.join(lessonsDir.path, filename);
      } else {
        // Flat file. We need to force it into a folder based on ZipKey?

        // This is risky if one zip feeds multiple lessons.

        // But usually Group Zip has structure.

        // Fallback: If zipKey maps to a single lessonFolder in folderMap, use it.

        // Check if zipKey is a lessonId

        String? folder = _lessonFolderMap[zipKey];

        // Re-check: Maybe zipKey is 'group_present_tense'. That has no single folder.

        // But typically group zips MUST have folders.

        if (folder != null) {
          destinationPath = path.join(lessonsDir.path, folder, filename);
        } else {
          // Just dump in root? Or create a folder named zipKey?

          destinationPath = path.join(lessonsDir.path, zipKey, filename);
        }
      }

      final f = File(destinationPath);

      await f.parent.create(recursive: true);

      await f.writeAsBytes(file.content as List<int>);
    }
  }

  Future<bool> _isLessonDownloaded(String lessonId) async {
    final docDir = await getApplicationDocumentsDirectory();

    String relativeFolder = _lessonFolderMap[lessonId] ?? lessonId;

    final targetDir = Directory(
      path.join(docDir.path, 'lessons_assets', relativeFolder),
    );

    // Simple check: does directory exist and have files?

    return await targetDir.exists() && (await targetDir.list().length) > 0;
  }

  /// Get the local filesystem path for a lesson asset

  /// Returns NULL if not found locally (should fall back to assets bundle)

  Future<File?> getLocalAsset(String lessonId, String assetName) async {
    // Note: We might want to allow partial usage even if "status" isn't fully ready

    // but safer to check status if we track it.

    // However, persistence of _statusNotifiers is poor (memory only).

    // So we just check file existence directly.

    final docDir = await getApplicationDocumentsDirectory();

    // We need to resolve the path carefully.

    // assetName usually comes in as "assets/Lessons/Lesson_01/intro.png" (full path from bundled asset)

    // OR just "intro.png".

    // If it is full path, we strip "assets/Lessons/"?

    // Our _lessonFolderMap stores "Lesson_01_Subjects".

    // If incoming assetName is "assets/Lessons/Lesson_01_Subjects/01_intro.png":

    // We want "lessons_assets/Lesson_01_Subjects/01_intro.png".

    String relativePath;

    if (assetName.startsWith('assets/Lessons/')) {
      // Strip prefix

      relativePath = assetName.replaceFirst('assets/Lessons/', '');
    } else if (assetName.contains('/')) {
      // Assume it is relative to lesson folder? Not safe.

      // Best to rely on _lessonFolderMap if we can.

      // Actually, typically we pass just filename to this method from the Widget?

      // No, current usage in LessonSubjectsScreen is:

      // fallbackAssetPath: '$_assetPath${slide.imagePath}' -> 'assets/Lessons/Lesson_01/img.png'

      // imageName: slide.imagePath -> 'img.png'

      // So assetName is 'img.png'.

      String folder = _lessonFolderMap[lessonId] ?? lessonId;

      relativePath = path.join(folder, assetName);
    } else {
      String folder = _lessonFolderMap[lessonId] ?? lessonId;

      relativePath = path.join(folder, assetName);
    }

    final fullPath = path.join(docDir.path, 'lessons_assets', relativePath);

    final file = File(fullPath);

    if (await file.exists()) return file;

    return null;
  }

  /// Identifies and downloads the next 2 lessons based on current lesson

  Future<void> preloadNextLessons(String currentLessonId) async {
    debugPrint(
      '[REFRESH] Checking preload for next lessons after $currentLessonId',
    );

    final allLessons = _getLinearLessonList();

    int currentIndex = allLessons.indexOf(currentLessonId);

    if (currentIndex == -1) return;

    // Preload next 2

    for (int i = 1; i <= 2; i++) {
      if (currentIndex + i < allLessons.length) {
        final nextId = allLessons[currentIndex + i];

        final status = await getStatus(nextId);

        if (status == LessonContentStatus.ready) {
          // debugPrint('OK: Next lesson already ready: $nextId');
        } else if (status == LessonContentStatus.downloading) {
          // debugPrint(' Next lesson already downloading: $nextId');
        } else {
          debugPrint('[LAUNCH] Triggering preload for: $nextId');

          downloadLesson(nextId);
        }
      }
    }
  }

  /// Helper to linearize the curriculum for finding "next"

  List<String> _getLinearLessonList() {
    List<String> ids = [];

    // Standalone

    ids.addAll(
      LessonRegistry().getStandaloneLessons().map((l) => l['id'] as String),
    );

    // Groups

    for (var group in LessonRegistry().getAllLessonGroups()) {
      ids.addAll(group.lessons.map((l) => l.id));
    }

    // Add other advanced lessons not in groups if necessary

    // (This list needs to be comprehensive for preloading to work effectively across entire app)

    return ids;
  }

  /// Delete a downloaded lesson to free up space

  Future<void> deleteLesson(String lessonId) async {
    final docDir = await getApplicationDocumentsDirectory();

    String relativeFolder = _lessonFolderMap[lessonId] ?? lessonId;

    final targetDir = Directory(
      path.join(docDir.path, 'lessons_assets', relativeFolder),
    );

    if (await targetDir.exists()) {
      await targetDir.delete(recursive: true);

      debugPrint('[DELETE] Deleted lesson assets: $lessonId');

      final zipKey = _zipParentMap[lessonId] ?? lessonId;

      if (_statusNotifiers.containsKey(zipKey)) {
        _statusNotifiers[zipKey]!.value = LessonContentStatus.notDownloaded;
      }
    }
  }
}
