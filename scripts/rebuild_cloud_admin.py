import re
from pathlib import Path
import textwrap

cloud_path = Path(r'e:/Apps/gravity_app/lib/services/data_service_cloud_sync.dart')
admin_path = Path(r'e:/Apps/gravity_app/lib/services/data_service_admin.dart')

# Extract existing method blocks from current cloud file (best-effort)
cloud_lines = cloud_path.read_text(encoding='utf-8').splitlines()

methods = {}

start_regex = re.compile(r'^  [^ ].*\(')
header_regex = re.compile(r'^  .*\)\s*(async\s*)?\{')
name_regex = re.compile(r'^  [^\(]*\b([A-Za-z0-9_]+)\s*\(')

idx = 0
while idx < len(cloud_lines):
    line = cloud_lines[idx]
    if start_regex.match(line):
        name_match = name_regex.match(line)
        if name_match:
            name = name_match.group(1)
            header_end = None
            for j in range(idx, len(cloud_lines)):
                if header_regex.match(cloud_lines[j]):
                    header_end = j
                    break
            if header_end is None:
                idx += 1
                continue
            end = None
            for j in range(header_end + 1, len(cloud_lines)):
                if re.match(r'^  }\s*$', cloud_lines[j]):
                    end = j
                    break
            if end is None:
                idx += 1
                continue
            block = '\n'.join(cloud_lines[idx:end + 1])
            if name not in methods:
                methods[name] = block
            idx = end + 1
            continue
    idx += 1


def normalize_block(block: str) -> str:
    lines = block.splitlines()
    first_non_empty = None
    for l in lines:
        if l.strip():
            first_non_empty = l
            break
    if first_non_empty is None:
        return block
    if first_non_empty.startswith('  '):
        return block
    return '\n'.join((f"  {l}" if l.strip() else l) for l in lines)


manual_blocks = {}

manual_blocks['syncQuizDataFromCloud'] = textwrap.dedent(r"""
  Future<void> syncQuizDataFromCloud() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/quiz_data.csv');

      // Check metadata or just always download if requested explicitly
      final ref = FirebaseStorage.instance.ref().child('data/quiz_data.csv');

      // We can check metadata to see if updated, but forceRefresh implies "Give me latest".
      await ref.writeToFile(file);
      debugPrint("DataService: Quiz Quiz data downloaded to ${file.path}");
    } catch (e) {
      debugPrint("DataService: Cloud sync failed or file not found: $e");
      // Not fatal, will fallback to asset
    }
  }
""").strip('\n')

manual_blocks['importCsvFromUrl'] = textwrap.dedent(r"""
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
""").strip('\n')

manual_blocks['_mergeAndSaveVocabulary'] = textwrap.dedent(r"""
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
""").strip('\n')

manual_blocks['_mergeAndSaveVerbs'] = textwrap.dedent(r"""
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
""").strip('\n')

manual_blocks['_mergeAndSaveGeneric'] = textwrap.dedent(r"""
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
""").strip('\n')

manual_blocks['_saveDataToPrefs'] = textwrap.dedent(r"""
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
""").strip('\n')

manual_blocks['_syncWithCloud'] = textwrap.dedent(r"""
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
""").strip('\n')

manual_blocks['_parseAndCache'] = textwrap.dedent(r"""
  void _parseAndCache(String key, String jsonString) {
    try {
      List<dynamic> jsonList = json.decode(jsonString);
      List<List<dynamic>> validList = jsonList
          .map((e) => (e as List).toList())
          .toList();

      if (key == 'custom_vocabulary')
        _cachedVocabData = validList;
      else if (key == 'custom_verbs')
        _cachedVerbData = validList;
      else if (key == 'custom_reading')
        _cachedReadingData = validList;
      else if (key == 'custom_writing')
        _cachedWritingData = validList;
      else if (key == 'custom_speaking')
        _cachedSpeakingData = validList;
      else if (key == 'custom_listening')
        _cachedListeningData = validList;
      else if (key == 'custom_quiz')
        _cachedQuizData = validList;
    } catch (e) {
      debugPrint("Error parsing synced data for $key: $e");
    }
  }
""").strip('\n')

manual_blocks['saveProgressToCloud'] = textwrap.dedent(r"""
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
""").strip('\n')

manual_blocks['_updateMasteryTally'] = textwrap.dedent(r"""
  Future<void> _updateMasteryTally() async {
    // Hidden tally for quick read
    final prefs = await SharedPreferences.getInstance();
    int count = 0;
    for (String key in prefs.getKeys()) {
      if (key.startsWith('mastery_done_')) count++;
    }
    await prefs.setInt('mastery_total_done', count);
  }
""").strip('\n')

manual_blocks['getBlackHoleItems'] = textwrap.dedent(r"""
  Future<List<Map<String, String>>> getBlackHoleItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? encodedItems = prefs.getStringList(_blackHoleKey);

    // If missing locally, try cloud sync ONCE to restore
    if (encodedItems == null) {
      debugPrint("BlackHole: Local cache missing. Syncing from cloud...");
      await syncProgressFromCloud();
      encodedItems = prefs.getStringList(_blackHoleKey);
    }

    encodedItems ??= [];

    return encodedItems
        .map((e) => Map<String, String>.from(jsonDecode(e)))
        .toList();
  }
""").strip('\n')

manual_blocks['logActivity'] = textwrap.dedent(r"""
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
""").strip('\n')

cloud_order = [
    'wipeAllLibraryData',
    'listenToUserChanges',
    'dispose',
    'forceRefreshData',
    'syncQuizDataFromCloud',
    'importCsvFromUrl',
    'deleteItem',
    'updateItem',
    '_mergeAndSaveVocabulary',
    '_mergeAndSaveVerbs',
    '_mergeAndSaveGeneric',
    '_saveDataToPrefs',
    '_syncWithCloud',
    '_parseAndCache',
    'saveQuizResult',
    'saveProgressToCloud',
    'seedVocabularyForLevel',
    '_updateMasteryTally',
    'saveMasteryProgress',
    'getDetailedProgress',
    'getOverallProgress',
    'syncProgressFromCloud',
    'addToBlackHole',
    'toggleBlackHoleItem',
    'getBlackHoleItems',
    'isInBlackHole',
    'logActivity',
    'getRecentActivity',
    'saveHighScore',
    'addXp',
    'markItemAsLearned',
]

cloud_header = [
    '// NOTE: Cloud-sync methods intentionally mix local mutation and remote I/O.',
    '// Extracted verbatim from DataService; do not refactor or reorder.',
    "part of 'data_service.dart';",
    '',
    'extension DataServiceCloudSync on DataService {',
    '  String get _blackHoleKey => DataService._blackHoleKey;',
    '  String get _activityKey => DataService._activityKey;',
]

cloud_blocks = []
for name in cloud_order:
    block = methods.get(name) or manual_blocks.get(name)
    if not block:
        raise SystemExit(f'Missing method body for cloud: {name}')
    cloud_blocks.append(normalize_block(block))

cloud_content = '\n'.join(cloud_header) + '\n\n' + '\n\n'.join(cloud_blocks) + '\n\n}'
cloud_path.write_text(cloud_content + '\n', encoding='utf-8')

admin_blocks = []

admin_blocks.append(textwrap.dedent(r"""
  Future<void> _notifyTeacherOfSuccess(
    String dateStr,
    int score,
    int total,
  ) async {
    // Log Activity
    await logActivity(
      title: 'Daily Quiz',
      subtitle: 'Scored $score/$total',
      iconName: 'quiz',
      colorName: 'purple',
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Add to Firestore 'teacher_notifications' collection
      // Matching the schema expected by TeacherNotificationsScreen
      await FirebaseFirestore.instance.collection('teacher_notifications').add({
        'type':
            'task_completion', // Use 'task_completion' to get the checkmark icon
        'student_email': user.email ?? 'Unknown Email',
        'student_name':
            user.displayName ?? user.email?.split('@')[0] ?? 'Student',
        'studentId': user.uid,
        'task_title': 'Daily Quiz',
        'message': 'Scored $score/$total on $dateStr quiz!',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false, // Teacher screen uses 'isRead'
        'targetRole': 'teacher',
      });

      debugPrint("Teacher notification sent for Quiz Success");
    } catch (e) {
      debugPrint("Error sending teacher notification: $e");
    }
  }
""").strip('\n'))

admin_blocks.append(textwrap.dedent(r"""
  Future<bool> adminSyncFromUrlToCloud(String url) async {
    try {
      debugPrint("DataService: Fetching data from Google Sheet...");
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        String csvContent = response.body;

        // Basic Validation: Check if it looks like CSV/HTML
        if (csvContent.toLowerCase().contains("<!doctype html>")) {
          debugPrint(
            "DataService: URL returned HTML instead of CSV. Check the link.",
          );
          return false;
        }

        debugPrint("DataService: Uploading to Cloud Storage...");
        final ref = FirebaseStorage.instance.ref().child('data/quiz_data.csv');

        // Upload as String
        // Upload as String
        await ref.putString(csvContent);

        debugPrint("DataService: Cloud update complete. Refreshing local...");
        await forceRefreshData();

        return true;
      } else {
        debugPrint("DataService: Failed to fetch URL: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("DataService: Admin Sync Error: $e");
      return false;
    }
  }
""").strip('\n'))

admin_blocks.append(textwrap.dedent(r"""
  Future<String?> getUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['role'] as String?;
      }
    } catch (e) {
      debugPrint("DataService: Error getting user role: $e");
    }
    return null;
  }
""").strip('\n'))

admin_blocks.append(textwrap.dedent(r"""
  Future<Map<String, dynamic>> getUserStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {'role': 'student', 'isBlocked': false};

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5)); // Added timeout

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Sync critical fields to prefs immediately
        final prefs = await SharedPreferences.getInstance();
        if (data['user_level'] != null) {
          await prefs.setInt('user_level', data['user_level']);
        }
        // Fix: Also sync difficulty level (String) to a separate key
        if (data['effective_difficulty_level'] != null) {
          await prefs.setString(
            'english_proficiency_level',
            data['effective_difficulty_level'],
          );
        }
        String? startDateStr;
        if (data['progress_start_date'] != null) {
          final ts = data['progress_start_date'] as Timestamp;
          startDateStr = ts.toDate().toIso8601String();
        } else if (data['createdAt'] != null) {
          final ts = data['createdAt'] as Timestamp;
          startDateStr = ts.toDate().toIso8601String();
        }

        if (startDateStr != null) {
          await prefs.setString('progress_start_date', startDateStr);
        }

        return {
          'role': data['role'] ?? 'student',
          'isBlocked': data['isBlocked'] ?? false,
          'force_onboarding': data['force_onboarding'] ?? false,
          'user_level': data['user_level'] ?? 1,
          'progress_start_date': startDateStr,
        };
      }
    } catch (e) {
      debugPrint("DataService: Error getting user status: $e");
    }
    return {'role': 'student', 'isBlocked': false};
  }
""").strip('\n'))

admin_blocks.append(textwrap.dedent(r"""
  Future<void> resetStudentProgress(String uid) async {
    try {
      // 1. Delete Progress Subcollection (Batch delete for safety)
      final progressRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('progress');

      final snapshots = await progressRef.get();
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }

      // 2. Reset User Fields in Main Doc
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      batch.update(userRef, {
        'user_level': 1,
        'user_current_xp': 0,
        'user_total_xp': 0,
        'user_streak_days': 0,
        'points': 0,
        'badges': [],
        'lastActive': FieldValue.serverTimestamp(),
        'progress_start_date':
            FieldValue.serverTimestamp(), // Reset start time for Pending Lessons
        'force_onboarding': true, // signal to client to reset local prefs
        'assessment_status': FieldValue.delete(),
        'english_proficiency_level': FieldValue.delete(),
      });

      await batch.commit();
      debugPrint("? Progress reset for student: $uid");
    } catch (e) {
      debugPrint("? Error resetting progress: $e");
      throw e;
    }
  }
""").strip('\n'))

admin_blocks.append(textwrap.dedent(r"""
  Future<void> setUserLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest';

    await prefs.setString('english_proficiency_level_$userId', level);

    // Clear caches to force reload of level-specific data
    _cachedVocabData = null;
    _cachedVerbData = null;
    _cachedReadingData = null;
    _cachedWritingData = null;
    _cachedSpeakingData = null;
    _cachedListeningData = null;

    debugPrint('DataService: User Level set to $level. Caches cleared.');

    // Sync to Cloud
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'english_proficiency_level': level,
      }, SetOptions(merge: true));
    }
  }
""").strip('\n'))

admin_blocks.append(textwrap.dedent(r"""
  Future<String?> getAssessmentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest';

    // 1. Check Local Prefs
    String? status = prefs.getString('assessment_status_$userId');
    if (status != null) return status;

    // 2. Check Cloud
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5)); // Added timeout
        if (doc.exists) {
          final cloudStatus = doc.data()?['assessment_status'];
          if (cloudStatus != null) {
            // Cache locally
            await prefs.setString('assessment_status_$userId', cloudStatus);
            return cloudStatus;
          }
        }
      } catch (e) {
        debugPrint("Error fetching assessment status from cloud: $e");
      }
    }

    return null;
  }
""").strip('\n'))

admin_blocks.append(textwrap.dedent(r"""
  Future<void> setAssessmentStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest';

    await prefs.setString('assessment_status_$userId', status);

    // Sync to Cloud if possible
    try {
      // final user = FirebaseAuth.instance.currentUser; // Already declared above
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'assessment_status': status,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error syncing assessment status to cloud: $e");
    }
  }
""").strip('\n'))

admin_blocks.append(textwrap.dedent(r"""
  Future<void> savePlacementResult(String levelCode, int score) async {
    // Map A/B/C to internal strings
    String fullLevel = "Beginner (A1)";
    if (levelCode == 'A') fullLevel = "Advanced (C1)";
    if (levelCode == 'B') fullLevel = "Intermediate (B1)";
    if (levelCode == 'C') fullLevel = "Beginner (A1)";

    // 1. Set the Level
    await setUserLevel(fullLevel);

    // 2. Mark Assessment as Completed
    await setAssessmentStatus('completed');

    // 3. Reset Learning Day to Day 1 starting NOW
    await LearningDayService().resetLearningProgress();

    // 3. Save additional metadata
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest';
    final now = DateTime.now();
    await prefs.setString(
      'assessment_timestamp_$userId',
      now.toIso8601String(),
    );

    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'assessment_score': score,
        'assessment_timestamp': FieldValue.serverTimestamp(),
        'placement_level_code': levelCode,
      }, SetOptions(merge: true));
    }

    debugPrint(
      "? Placement result saved: $levelCode ($fullLevel) with score $score",
    );
  }
""").strip('\n'))

admin_header = [
    '// NOTE: Admin/role methods intentionally mix local mutation and remote I/O.',
    '// Extracted verbatim from DataService; do not refactor or reorder.',
    "part of 'data_service.dart';",
    '',
    'extension DataServiceAdmin on DataService {',
]

admin_content = '\n'.join(admin_header) + '\n\n' + '\n\n'.join(normalize_block(b) for b in admin_blocks) + '\n\n}'
admin_path.write_text(admin_content + '\n', encoding='utf-8')

print('Rebuilt cloud/admin service files.')
