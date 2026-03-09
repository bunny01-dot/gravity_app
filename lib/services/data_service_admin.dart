// NOTE: Admin/role methods intentionally mix local mutation and remote I/O.
// Extracted verbatim from DataService; do not refactor or reorder.
part of 'data_service.dart';

extension DataServiceAdmin on DataService {
  Future<void> _notifyTeacherOfSuccess(
    String dateStr,
    int score,
    int total,
  ) async {
    // Log Activity
    await logActivity(
      title: 'Checkpoint Quiz',
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
        'studentEmail': user.email ?? '',
        'studentName':
            user.displayName ?? user.email?.split('@')[0] ?? 'Student',
        'studentId': user.uid,
        'student_id': user.uid,
        'senderId': user.uid,
        'task_title': 'Checkpoint Quiz',
        'activityType': 'task_completion',
        'activity_type': 'task_completion',
        'details': 'Scored $score/$total on $dateStr quiz!',
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
          await prefs.setInt('user_xp_level', data['user_level']);
        }
        // Fix: Also sync difficulty level (String) to a separate key
        if (data['effective_difficulty_level'] != null) {
          await prefs.setString(
            'english_proficiency_level',
            data['effective_difficulty_level'],
          );
        }
        return {
          'role': data['role'] ?? 'student',
          'isBlocked': data['isBlocked'] ?? false,
          'force_onboarding': data['force_onboarding'] ?? false,
          'user_level': data['user_level'] ?? 1,
        };
      }
    } catch (e) {
      debugPrint("DataService: Error getting user status: $e");
    }
    return {'role': 'student', 'isBlocked': false};
  }

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
        'user_stage_streak': 0,
        'points': 0,
        'badges': [],
        'lastActive': FieldValue.serverTimestamp(),
        'force_onboarding': true, // signal to client to reset local prefs
        'assessment_status': FieldValue.delete(),
        'english_proficiency_level': FieldValue.delete(),
        'assessment_completed': false,
        'assessment_skipped': false,
        'assessment_timestamp': FieldValue.delete(),
        'assessment_score': FieldValue.delete(),
        'placement_level_code': FieldValue.delete(),
      });

      await batch.commit();
      debugPrint("? Progress reset for student: $uid");
    } catch (e) {
      debugPrint("? Error resetting progress: $e");
      rethrow;
    }
  }

  Future<void> setUserLevel(
    String level, {
    bool fromPlacementQuiz = false,
  }) async {
    if (!fromPlacementQuiz) {
      debugPrint(
        'DataService: Ignored non-placement level update. '
        'Course level is locked to placement quiz result.',
      );
      return;
    }

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
    DayBasedCurriculumService().reset();
    StageContentService().reset();
    VocabularyService().reset();

    debugPrint('DataService: User Level set to $level. Caches cleared.');

    // Sync to Cloud
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'english_proficiency_level': level,
      }, SetOptions(merge: true));
    }
  }

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

  Future<void> savePlacementResult(String levelCode, int score) async {
    // Map A/B/C to internal strings
    String fullLevel = "Beginner (A1)";
    if (levelCode == 'A') fullLevel = "Advanced (C1)";
    if (levelCode == 'B') fullLevel = "Intermediate (B1)";
    if (levelCode == 'C') fullLevel = "Beginner (A1)";

    // 1. Set the Level
    await setUserLevel(fullLevel, fromPlacementQuiz: true);

    final prefs = await SharedPreferences.getInstance();
    final existingEffective =
        prefs.getString('effective_difficulty_level') ?? '';
    if (existingEffective.isEmpty) {
      await prefs.setString('effective_difficulty_level', fullLevel);
    }

    // 2. Mark Assessment as Completed
    await setAssessmentStatus('completed');

    // 3. Save additional metadata (do not reset learning progress)
    final now = DateTime.now();
    await prefs.setBool('assessment_completed', true);
    await prefs.setBool('assessment_skipped', false);
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest';
    await prefs.setString(
      'assessment_timestamp_$userId',
      now.toIso8601String(),
    );

    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'assessment_score': score,
        'assessment_timestamp': FieldValue.serverTimestamp(),
        'placement_level_code': levelCode,
        'assessment_completed': true,
        'assessment_skipped': false,
      }, SetOptions(merge: true));
    }

    debugPrint(
      "? Placement result saved: $levelCode ($fullLevel) with score $score",
    );
  }
}
