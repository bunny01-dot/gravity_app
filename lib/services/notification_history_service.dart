import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Manages notification history with 7-day retention in Firestore
class NotificationHistoryService {
  static final NotificationHistoryService _instance =
      NotificationHistoryService._internal();
  factory NotificationHistoryService() => _instance;
  NotificationHistoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user's notification history collection
  CollectionReference? _getUserHistoryCollection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notification_history');
  }

  /// Save notification to history when user sees it
  Future<void> saveToHistory({
    required String announcementId,
    required String title,
    required String message,
    required String type,
    required DateTime receivedAt,
  }) async {
    try {
      final collection = _getUserHistoryCollection();
      if (collection == null) return;

      await collection.doc(announcementId).set({
        'announcementId': announcementId,
        'title': title,
        'message': message,
        'type': type,
        'receivedAt': Timestamp.fromDate(receivedAt),
        'readAt': null,
        'dismissedAt': null,
        'expiresAt': Timestamp.fromDate(
          receivedAt.add(const Duration(days: 7)),
        ),
      });

      debugPrint('OK: Notification saved to history: $announcementId');
    } catch (e) {
      debugPrint('Error: Error saving notification to history: $e');
    }
  }

  /// Mark notification as read in history
  Future<void> markAsRead(String announcementId) async {
    try {
      final collection = _getUserHistoryCollection();
      if (collection == null) return;

      await collection.doc(announcementId).update({
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error: Error marking notification as read: $e');
    }
  }

  /// Mark notification as dismissed (user swiped it away)
  Future<void> markAsDismissed(String announcementId) async {
    try {
      final collection = _getUserHistoryCollection();
      if (collection == null) return;

      await collection.doc(announcementId).update({
        'dismissedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('OK: Notification dismissed: $announcementId');
    } catch (e) {
      debugPrint('Error: Error dismissing notification: $e');
    }
  }

  /// Check if user has already received this notification
  Future<bool> hasReceivedNotification(String announcementId) async {
    try {
      final collection = _getUserHistoryCollection();
      if (collection == null) return false;

      final doc = await collection.doc(announcementId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error: Error checking notification history: $e');
      return false;
    }
  }

  /// Get all notification history (for notifications screen)
  Stream<QuerySnapshot> getNotificationHistory() {
    final collection = _getUserHistoryCollection();
    if (collection == null) {
      return const Stream.empty();
    }

    return collection
        .orderBy('receivedAt', descending: true)
        .limit(100)
        .snapshots();
  }

  /// Get only active (non-dismissed) notifications
  Stream<QuerySnapshot> getActiveNotifications() {
    final collection = _getUserHistoryCollection();
    if (collection == null) {
      return const Stream.empty();
    }

    return collection
        .where('dismissedAt', isNull: true)
        .orderBy('receivedAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Auto-cleanup: Delete notifications older than 7 days
  Future<void> cleanupExpiredNotifications() async {
    try {
      final collection = _getUserHistoryCollection();
      if (collection == null) return;

      final now = Timestamp.now();
      final snapshot = await collection
          .where('expiresAt', isLessThan: now)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('[CLEAN] Cleaned up ${snapshot.docs.length} expired notifications');
    } catch (e) {
      debugPrint('Error: Error cleaning up notifications: $e');
    }
  }

  /// Get count of unread notifications
  Future<int> getUnreadCount() async {
    try {
      final collection = _getUserHistoryCollection();
      if (collection == null) return 0;

      final snapshot = await collection
          .where('readAt', isNull: true)
          .where('dismissedAt', isNull: true)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error: Error getting unread count: $e');
      return 0;
    }
  }

  /// Permanently delete a notification from history
  Future<void> permanentlyDelete(String announcementId) async {
    try {
      final collection = _getUserHistoryCollection();
      if (collection == null) return;

      await collection.doc(announcementId).delete();
      debugPrint('[DELETE] Permanently deleted notification: $announcementId');
    } catch (e) {
      debugPrint('Error: Error deleting notification: $e');
    }
  }
}

