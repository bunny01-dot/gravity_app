import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gravity_app/services/notification_service.dart';
import 'package:gravity_app/widgets/notification_permission_tutorial.dart';

/// ISSUE #2: Helper service to check and show notification tutorial contextually
class NotificationTutorialHelper {
  static final NotificationTutorialHelper _instance =
      NotificationTutorialHelper._internal();
  factory NotificationTutorialHelper() => _instance;
  NotificationTutorialHelper._internal();

  final NotificationService _notificationService = NotificationService();
  bool _hasShownThisSession = false;

  /// Check if we should show the tutorial and show it if needed
  /// Returns true if tutorial was shown, false otherwise
  Future<bool> checkAndShowTutorialIfNeeded(
    BuildContext context, {
    bool force = false,
  }) async {
    // Don't show multiple times in same session unless forced
    if (_hasShownThisSession && !force) {
      return false;
    }

    // Check if user is a student
    final isStudent = await _isCurrentUserStudent();
    if (!isStudent) {
      // Teachers don't need notification tutorial
      return false;
    }

    // Note: Currently showing tutorial regardless of announcement existence
    // Future enhancement: Only show if announcements exist
    // final hasAnnouncements = await _checkForAnnouncements();

    // Should we show tutorial?
    final shouldShow = await _notificationService.shouldShowTutorial();

    if (shouldShow || force) {
      // Show tutorial
      if (context.mounted) {
        _hasShownThisSession = true;
        await showNotificationPermissionTutorial(
          context,
          isStudent: isStudent,
          onComplete: () {
            debugPrint('NotificationTutorialHelper: Tutorial completed');
          },
        );
        return true;
      }
    }

    return false;
  }

  /// Check if current user is a student
  Future<bool> _isCurrentUserStudent() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return true; // Default to student

      final data = doc.data();
      final role = data?['role'] ?? 'student';
      return role == 'student';
    } catch (e) {
      debugPrint('Error checking user role: $e');
      return true; // Default to student
    }
  }

  /// Reset the session flag (for testing or force re-show)
  void resetSession() {
    _hasShownThisSession = false;
  }

  /// Show tutorial immediately (bypasses all checks)
  Future<void> showTutorialNow(BuildContext context) async {
    final isStudent = await _isCurrentUserStudent();
    if (context.mounted) {
      await showNotificationPermissionTutorial(context, isStudent: isStudent);
    }
  }
}
