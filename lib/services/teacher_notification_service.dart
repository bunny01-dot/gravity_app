import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class TeacherNotificationService {
  static final TeacherNotificationService _instance =
      TeacherNotificationService._internal();
  factory TeacherNotificationService() => _instance;
  TeacherNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sends a notification to the teacher dashboard about a student's activity.
  ///
  /// Validation enforced:
  /// - All required fields must be non-empty
  /// - Invalid payloads are logged but not sent
  ///
  /// [studentId]: The UID of the student (required, non-empty)
  /// [studentName]: The display name of the student (required, non-empty)
  /// [activityType]: Category of event (required, non-empty)
  /// [details]: Specific message about the event (required, non-empty)
  Future<void> sendStudentActivityNotification({
    required String studentId,
    required String studentName,
    required String activityType,
    required String details,
  }) async {
    final trimmedStudentId = studentId.trim();
    final trimmedStudentName = studentName.trim();
    final trimmedActivityType = activityType.trim();
    final trimmedDetails = details.trim();

    if (trimmedStudentId.isEmpty) {
      debugPrint('INVALID_NOTIFICATION_PAYLOAD: studentId is empty');
      _logInvalidPayload('studentId', trimmedStudentName, trimmedActivityType);
      return;
    }

    if (trimmedStudentName.isEmpty) {
      debugPrint('INVALID_NOTIFICATION_PAYLOAD: studentName is empty');
      _logInvalidPayload(
        'studentName',
        trimmedStudentName,
        trimmedActivityType,
      );
      return;
    }

    if (trimmedActivityType.isEmpty) {
      debugPrint('INVALID_NOTIFICATION_PAYLOAD: activityType is empty');
      _logInvalidPayload(
        'activityType',
        trimmedStudentName,
        trimmedActivityType,
      );
      return;
    }

    if (trimmedDetails.isEmpty) {
      debugPrint('INVALID_NOTIFICATION_PAYLOAD: details is empty');
      _logInvalidPayload('details', trimmedStudentName, trimmedActivityType);
      return;
    }

    final profile = await _resolveStudentProfile(
      studentId: trimmedStudentId,
      fallbackName: trimmedStudentName,
    );
    final resolvedName = profile['name'] ?? trimmedStudentName;
    final resolvedEmail = profile['email'] ?? '';
    final taskTitle = _toTitleCase(trimmedActivityType.replaceAll('_', ' '));

    try {
      await _firestore.collection('teacher_notifications').add({
        // snake_case keys used by some screens
        'type': trimmedActivityType,
        'student_email': resolvedEmail,
        'student_name': resolvedName,
        'task_title': taskTitle,
        'message': trimmedDetails,
        'isRead': false,
        'targetRole': 'teacher',

        // camelCase keys used by other screens/services
        'studentId': trimmedStudentId,
        'student_id': trimmedStudentId,
        'senderId': trimmedStudentId,
        'studentName': resolvedName,
        'studentEmail': resolvedEmail,
        'activityType': trimmedActivityType,
        'activity_type': trimmedActivityType,
        'details': trimmedDetails,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint(
        'Teacher notification sent: $trimmedActivityType for $resolvedName',
      );
    } catch (e) {
      debugPrint('Error sending teacher notification: $e');
    }
  }

  Future<Map<String, String>> _resolveStudentProfile({
    required String studentId,
    required String fallbackName,
  }) async {
    String resolvedName = fallbackName.trim();
    String resolvedEmail = '';

    try {
      final userDoc = await _firestore.collection('users').doc(studentId).get();
      final userData = userDoc.data();
      if (userData != null) {
        resolvedName = _firstNonEmptyString([
          userData['name'],
          userData['fullName'],
          userData['displayName'],
          userData['studentName'],
          resolvedName,
        ]);
        resolvedEmail = _firstNonEmptyString([
          userData['email'],
          userData['studentEmail'],
          userData['student_email'],
        ]);
      }
    } catch (e) {
      debugPrint('Unable to read users/$studentId for notification: $e');
    }

    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null && authUser.uid == studentId) {
      resolvedName = _firstNonEmptyString([
        resolvedName,
        authUser.displayName,
        authUser.email?.split('@').first,
      ]);
      resolvedEmail = _firstNonEmptyString([resolvedEmail, authUser.email]);
    }

    resolvedName = _firstNonEmptyString([resolvedName, 'Student']);

    return {'name': resolvedName, 'email': resolvedEmail};
  }

  String _firstNonEmptyString(List<dynamic> candidates) {
    for (final value in candidates) {
      final parsed = _readString(value);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }
    return '';
  }

  String _readString(dynamic value) {
    if (value == null) return '';
    final parsed = value.toString().trim();
    if (parsed.isEmpty || parsed.toLowerCase() == 'null') return '';
    return parsed;
  }

  String _toTitleCase(String value) {
    if (value.trim().isEmpty) return 'Student Activity';
    final words = value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .toList();
    return words.join(' ');
  }

  /// Logs invalid notification attempts to Firestore for debugging.
  Future<void> _logInvalidPayload(
    String missingField,
    String studentName,
    String activityType,
  ) async {
    try {
      await _firestore.collection('notification_errors').add({
        'error_type': 'INVALID_NOTIFICATION_PAYLOAD',
        'missing_field': missingField,
        'attempted_student_name': studentName,
        'attempted_activity_type': activityType,
        'timestamp': FieldValue.serverTimestamp(),
        'severity': 'medium',
      });
    } catch (e) {
      // Do not let logging errors break user flow.
      debugPrint('Failed to log invalid payload: $e');
    }
  }
}
