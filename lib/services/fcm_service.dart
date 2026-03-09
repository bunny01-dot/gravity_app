import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gravity_app/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:gravity_app/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("[MAIL] Background FCM message received: ${message.messageId}");

    // OK: CRITICAL FIX: Do NOT create local notifications here!
    // With hybrid FCM payload (notification + data), Android system tray
    // automatically displays the notification even when app is killed.
    //
    // Creating local notifications here causes:
    // 1. Double notifications (system tray + local)
    // 2. Unreliable delivery on battery-optimized devices
    // 3. Race conditions with foreground handlers
    //
    // The system notification automatically uses the channelId specified
    // in the FCM payload from Cloud Functions.

    // Optional: Log analytics or update badge count only
    debugPrint("Background notification delivered by system tray");
  } catch (e, stack) {
    debugPrint("CRITICAL: Error in background handler: $e\n$stack");
  }
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();

  //  SECURITY FIXED: Service Account Private Key Removed.
  // Admin notifications should now be sent via Firebase Cloud Functions.
  // The client app should NOT have permission to send push notifications directly.

  /// Initialize FCM for student users
  /// ISSUE #3 FIX: Students subscribe to student_announcements only
  Future<void> initForStudent() async {
    await _notificationService.init();
    await _checkAndRequestPermission();
    await unsubscribeFromTopic('teachers');
    await subscribeToTopic('student_announcements');
    await _setupMessageHandlers();
    await _setupTokenHandling();
  }

  /// Initialize FCM for teacher users
  /// ISSUE #3 FIX: Teachers do NOT subscribe to student announcements
  Future<void> initForTeacher() async {
    await _notificationService.init();
    await _checkAndRequestPermission();
    await unsubscribeFromTopic('student_announcements');
    // OK: NEW: Teachers subscribe to 'teachers' topic for student activity notifications
    await subscribeToTopic('teachers');
    debugPrint('OK: Teacher subscribed to "teachers" topic for notifications');
    await _setupMessageHandlers();
    await _setupTokenHandling();
  }

  /// Legacy init method - defaults to student behavior for backward compatibility
  /// Use initForStudent() or initForTeacher() instead
  Future<void> init() async {
    await initForStudent();
  }

  /// Setup message handlers (foreground notifications)
  /// OK: UPDATED: Now handles hybrid FCM payloads
  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[MAIL] Foreground FCM message received: ${message.messageId}');

      // OK: With hybrid payload, prioritize notification field
      String title;
      String body;
      bool isImportant = true;

      if (message.notification != null) {
        // Use notification payload (always present with hybrid approach)
        title = message.notification!.title ?? 'Notification';
        body = message.notification!.body ?? '';

        // Get importance from data payload if available
        if (message.data.containsKey('announcement_type')) {
          isImportant = message.data['announcement_type'] == 'important';
        }
      } else if (message.data.containsKey('title')) {
        // Fallback to data payload (legacy support)
        title = message.data['title'] ?? 'Notification';
        body = message.data['body'] ?? '';

        if (message.data.containsKey('announcement_type')) {
          isImportant = message.data['announcement_type'] == 'important';
        }
      } else {
        // No valid payload
        debugPrint('[WARN] Received FCM message with no notification or data');
        return;
      }

      String? payload;
      final type = message.data['type']?.toString();
      final screen = message.data['screen']?.toString();
      if (type == 'daily_reminder' || screen == 'daily_tasks') {
        payload = 'daily_tasks';
      } else if (type != null && type.isNotEmpty) {
        payload = type;
      }

      // Important announcements should stay as dashboard cards only.
      if (isImportant && screen == 'announcements') {
        debugPrint(
          'Skipping foreground popup for important announcement (dashboard card only).',
        );
        return;
      }

      // Show custom in-app notification (foreground only)
      // Note: System tray notification is suppressed by default when app is foreground
      _notificationService.showNotification(
        title,
        body,
        isImportant: isImportant,
        payload: payload,
      );
    });
  }

  /// Setup FCM token handling
  Future<void> _setupTokenHandling() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint("FCM token acquired.");
      if (token != null && token.trim().isNotEmpty) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint("[WARN] FCM token fetch/save skipped: $e");
    }

    _firebaseMessaging.onTokenRefresh.listen((token) async {
      try {
        if (token.trim().isEmpty) return;
        await _saveTokenToFirestore(token);
      } catch (e) {
        debugPrint("[WARN] FCM token refresh save skipped: $e");
      }
    });
  }

  Future<void> _checkAndRequestPermission() async {
    // 1. Initial check using Firebase Messaging (standard)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Android 13+ Specific Handling
    // On Android 13 (API 33+), the OS dialog must be triggered explicitly if not granted.
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      if (status.isDenied || status.isProvisional) {
        // Force request via permission_handler which tends to be more reliable for the OS dialog
        await Permission.notification.request();
      }
    }

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint("User denied notifications");
    }
  }

  Future<bool> requestPermissionInteractive() async {
    var status = await Permission.notification.status;
    if (status.isPermanentlyDenied) {
      return await openAppSettings();
    } else {
      var result = await Permission.notification.request();
      return result.isGranted;
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final privateTokenRef = userRef.collection('private').doc('device');
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) return;

    final privateTokenPayload = <String, dynamic>{
      'fcmToken': trimmedToken,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    };

    final email = (user.email ?? '').trim();

    try {
      // Keep push token in a private sub-document to avoid exposing it via
      // broad profile reads (leaderboards/classmate lookups).
      await privateTokenRef.set(privateTokenPayload, SetOptions(merge: true));

      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data() ?? <String, dynamic>{};
        final storedEmail = (userData['email'] as String?)?.trim() ?? '';
        if (storedEmail.isEmpty && email.isNotEmpty) {
          await userRef.update({'uid': user.uid, 'email': email});
        }
        return;
      }

      if (email.isEmpty) {
        debugPrint(
          "FCM token sync skipped: user profile missing and email unavailable.",
        );
        return;
      }

      final role = email.toLowerCase() == 'teacher@english.com'
          ? 'teacher'
          : 'student';

      final createPayload = <String, dynamic>{
        'uid': user.uid,
        'email': email,
        'name': (user.displayName ?? '').trim().isEmpty
            ? 'User'
            : user.displayName!.trim(),
        'role': role,
        'provider': user.providerData.isNotEmpty
            ? user.providerData.first.providerId
            : 'firebase',
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      };

      await userRef.set(createPayload, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        if (kDebugMode) {
          debugPrint("FCM token sync skipped by Firestore rules.");
        }
        return;
      }
      rethrow;
    }
  }

  Future<void> sendToTopic({
    required String topic,
    required String title,
    required String body,
    bool isImportant = true,
  }) async {
    // Uses Firebase Cloud Functions to securely send notifications
    // Ensure you have deployed the 'sendAnnouncement' function.

    try {
      final functions = FirebaseFunctions.instance;
      // You can specify region if your function is not in us-central1:
      // final functions = FirebaseFunctions.instanceFor(region: 'us-central1');

      final callable = functions.httpsCallable('sendAnnouncement');
      await callable.call({
        'topic': topic,
        'title': title,
        'body': body,
        'important': isImportant,
      });
      debugPrint("OK: Notification sent via Cloud Function");
    } catch (e) {
      debugPrint("Error: Failed to send notification via Cloud Function: $e");
      // Fallback or User Feedback could go here
    }
  }

  Future<void> notifyAllStudents({
    required String title,
    required String message,
    bool isImportant = true,
  }) async {
    // ISSUE #3 FIX: Use student-specific topic to exclude teachers
    await sendToTopic(
      topic: 'student_announcements',
      title: title,
      body: message,
      isImportant: isImportant,
    );
  }

  @Deprecated('Use notifyAllStudents instead')
  Future<void> notifyAllTeachers({
    required String title,
    required String message,
  }) async {
    await sendToTopic(
      topic: 'teachers',
      title: title,
      body: message,
      isImportant: true,
    );
  }

  Future<void> notifyStudent({
    required String uid,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendIndividualNotification');

      await callable.call({
        'targetUserId': uid,
        'title': title,
        'body': body,
        'data': data ?? {},
      });
      debugPrint("OK: Individual notification sent via Cloud Function to $uid");
    } catch (e) {
      debugPrint("Error: Failed to send individual notification: $e");
      rethrow; // Allow UI to handle error feedback
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}

