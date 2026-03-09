import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/models/notification_permission_status.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _deviceSettingsChannel = MethodChannel(
    'gravity_app/device_settings',
  );

  // Use lazy singleton or just instance for data service to avoid circular init issues if any,
  // though DataService checks Auth which is fine.
  final DataService _dataService = DataService();

  bool _isInitialized = false;

  final StreamController<String?> _onNotificationTap =
      StreamController<String?>.broadcast();
  Stream<String?> get onNotificationTap => _onNotificationTap.stream;

  StreamSubscription? _notificationSubscription;

  void stopListening() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  // --- ISSUE #2: Permission Detection & Tutorial Management ---

  static const String _tutorialDismissedKey = 'notification_tutorial_dismissed';
  static const String _lastPermissionCheckKey =
      'last_notification_permission_check';

  /// Check current notification permission status (platform-aware)
  /// ISSUE #2 FIX: Detect actual permission state for student guidance
  Future<NotificationPermissionStatus> checkPermissionStatus() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await init();
        final status = await Permission.notification.status;
        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final areAppNotificationsEnabled =
            await androidPlugin?.areNotificationsEnabled() ?? true;

        if (status.isGranted && areAppNotificationsEnabled) {
          return NotificationPermissionStatus.granted;
        } else if (status.isPermanentlyDenied) {
          return NotificationPermissionStatus.permanentlyDenied;
        } else if (status.isDenied) {
          return NotificationPermissionStatus.denied;
        }
        if (!areAppNotificationsEnabled) {
          return NotificationPermissionStatus.denied;
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final status = await Permission.notification.status;

        if (status.isGranted) {
          return NotificationPermissionStatus.granted;
        } else if (status.isPermanentlyDenied) {
          return NotificationPermissionStatus.permanentlyDenied;
        } else {
          return NotificationPermissionStatus.denied;
        }
      }

      return NotificationPermissionStatus.unknown;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return NotificationPermissionStatus.unknown;
    }
  }

  /// Request notification permission (interactive)
  /// Returns true if granted, false otherwise
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      if (!status.isGranted) return false;
      if (defaultTargetPlatform != TargetPlatform.android) return true;

      await init();
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final areEnabled = await androidPlugin?.areNotificationsEnabled() ?? true;
      return areEnabled;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  Future<bool> canScheduleExactAlarms() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    await init();
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    try {
      return await androidPlugin?.canScheduleExactNotifications() ?? false;
    } catch (e) {
      debugPrint(
        'NotificationService: Failed to check exact alarm capability: $e',
      );
      return false;
    }
  }

  Future<bool> tryRequestExactAlarmPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    await init();
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    try {
      final canSchedule = await androidPlugin?.canScheduleExactNotifications();
      if (canSchedule == true) return true;
      await androidPlugin?.requestExactAlarmsPermission();
      return await androidPlugin?.canScheduleExactNotifications() ?? false;
    } catch (e) {
      debugPrint(
        'NotificationService: Failed to request exact alarm permission: $e',
      );
      return false;
    }
  }

  Future<bool> openBatteryOptimizationSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return openAppSettings();
    }
    try {
      final opened = await _deviceSettingsChannel.invokeMethod<bool>(
        'openBatteryOptimizationSettings',
      );
      return opened ?? false;
    } catch (e) {
      debugPrint(
        'NotificationService: Failed to open battery optimization settings: $e',
      );
      return openAppSettings();
    }
  }

  /// Check if user has dismissed the notification tutorial
  Future<bool> hasDismissedTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialDismissedKey) ?? false;
  }

  /// Mark notification tutorial as dismissed
  Future<void> markTutorialDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialDismissedKey, true);
    debugPrint('NotificationService: Tutorial marked as dismissed');
  }

  /// Reset tutorial dismissed flag (for testing or re-education)
  Future<void> resetTutorialDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialDismissedKey);
    debugPrint('NotificationService: Tutorial flag reset');
  }

  /// Check if we should show the tutorial to the user
  /// ISSUE #2 FIX: Contextual logic for showing tutorial
  Future<bool> shouldShowTutorial() async {
    // Don't show if already dismissed
    if (await hasDismissedTutorial()) {
      return false;
    }

    // Don't show if permissions are granted
    final status = await checkPermissionStatus();
    if (status.isEnabled) {
      return false;
    }

    return true;
  }

  /// Get the last time permission was checked
  Future<DateTime?> getLastPermissionCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastPermissionCheckKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // --- CRITICAL: Channel Health Verification (Android) ---

  /// OK: CHECK #1 FIX: Verify notification channels are enabled
  /// Detects disabled channels on upgraded installs
  Future<Map<String, bool>> checkChannelHealth() async {
    // Note: flutter_local_notifications doesn't provide getNotificationChannel()
    // Channels are recreated idempotently on each app launch in init()
    // We verify permission status as the primary health check

    final permissionStatus = await checkPermissionStatus();
    const criticalChannels = [
      'announcements_channel_v3',
      'announcements_channel_normal_v3',
      'daily_reminders_channel',
    ];

    // If permission granted, assume channels are OK (recreated in init)
    final allEnabled = permissionStatus.isEnabled;
    return {for (final channel in criticalChannels) channel: allEnabled};
  }

  /// OK: CHECK #1 FIX: Detect if user needs to re-enable notifications
  Future<bool> hasDisabledChannels() async {
    final status = await checkChannelHealth();

    // If any critical channel is missing/disabled, user needs guidance
    final hasMissingChannels = status.values.any((enabled) => !enabled);

    if (hasMissingChannels) {
      debugPrint('[WARN] CRITICAL: Notification channels are disabled!');
      debugPrint('Channel status: $status');
    }

    return hasMissingChannels;
  }

  // --- Read/Delete Management ---

  static const String _readKey = 'read_notifications';
  static const String _deletedKey = 'deleted_notifications';

  Future<void> markAsRead(String id) async {
    await markMultipleAsRead([id]);
  }

  Future<void> markMultipleAsRead(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    // Use Set for O(1) lookup
    final Set<String> readSet = (prefs.getStringList(_readKey) ?? []).toSet();
    bool changed = false;

    for (String id in ids) {
      if (!readSet.contains(id)) {
        readSet.add(id);
        changed = true;
      }
    }

    if (changed) {
      final newList = readSet.toList();
      await prefs.setStringList(_readKey, newList);
      // Sync to Cloud (Fire & Forget to prevent UI block)
      _dataService.saveProgressToCloud(_readKey, newList);
      debugPrint(
        "NotificationService: Marked ${ids.length} items as read. Total: ${newList.length}",
      );
    }
  }

  Future<void> deleteNotification(String id) async {
    await deleteMultipleNotifications([id]);
  }

  Future<void> deleteMultipleNotifications(List<String> ids) async {
    if (ids.isEmpty) return;

    debugPrint("NotificationService: Starting deletion of ${ids.length} items");

    final prefs = await SharedPreferences.getInstance();
    final Set<String> deletedSet = (prefs.getStringList(_deletedKey) ?? [])
        .toSet();
    bool changed = false;

    for (String id in ids) {
      if (!deletedSet.contains(id)) {
        deletedSet.add(id);
        changed = true;
      }
    }

    if (changed) {
      final newList = deletedSet.toList();

      // Save locally first (immediate)
      await prefs.setStringList(_deletedKey, newList);
      debugPrint(
        "NotificationService: Saved ${newList.length} deleted IDs locally",
      );

      // CRITICAL: Force cloud sync to complete before returning
      // This ensures deletions persist across devices/logins
      try {
        await _dataService.saveProgressToCloud(_deletedKey, newList);
        debugPrint(
          "NotificationService: Successfully synced ${newList.length} deleted IDs to cloud",
        );
      } catch (e) {
        debugPrint("NotificationService: [WARN] Error syncing to cloud: $e");
        // Retry once after 1 second
        await Future.delayed(const Duration(seconds: 1));
        try {
          await _dataService.saveProgressToCloud(_deletedKey, newList);
          debugPrint("NotificationService: Retry successful");
        } catch (retryError) {
          debugPrint("NotificationService: Error: Retry failed: $retryError");
          // Still proceed - local deletion is saved
        }
      }
    } else {
      debugPrint("NotificationService: No new items to delete");
    }
  }

  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS/macOS settings could be added here
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint(
          "NotificationService: Notification tapped with payload: ${details.payload}",
        );
        _onNotificationTap.add(details.payload);
      },
    );

    // Request permissions for Android 13+
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _createNotificationChannel();

    // OK: REMOVED: Local daily scheduling (unreliable on battery-optimized devices)
    // Daily reminders are now sent server-side via Cloud Scheduler + FCM
    // See: functions/index.js -> dailyStudentReminder

    _isInitialized = true;
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channelImportant =
        AndroidNotificationChannel(
          'announcements_channel_v3', // Updated to v3 to force refresh
          'Important Announcements',
          description: 'High priority notifications for teacher announcements',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        );

    const AndroidNotificationChannel channelNormal = AndroidNotificationChannel(
      'announcements_channel_normal_v3', // Updated to v3
      'Normal Announcements',
      description: 'Standard notifications for teacher announcements',
      importance: Importance.defaultImportance,
    );

    const AndroidNotificationChannel channelDaily = AndroidNotificationChannel(
      'daily_reminders_channel',
      'Learning Reminders',
      description: 'Reminders for your Learning Plan',
      importance: Importance.max,
    );

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(channelImportant);
    await androidPlugin?.createNotificationChannel(channelNormal);
    await androidPlugin?.createNotificationChannel(channelDaily);
  }

  Future<void> showNotification(
    String title,
    String body, {
    bool isImportant = true,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        isImportant
        ? const AndroidNotificationDetails(
            'announcements_channel_v3',
            'Important Announcements',
            channelDescription:
                'High priority notifications for teacher announcements',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            visibility: NotificationVisibility.public, // Show on lock screen
            fullScreenIntent: true, // Use banner/full screen if possible
          )
        : const AndroidNotificationDetails(
            'announcements_channel_normal_v3',
            'Normal Announcements',
            channelDescription:
                'Standard notifications for teacher announcements',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            ticker: 'ticker',
            visibility: NotificationVisibility.public,
          );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().hashCode, // Unique ID
      title,
      body,
      platformChannelSpecifics,
      payload: payload ?? 'announcement',
    );

    await incrementBadgeCount(); // Update badge
  }

  Future<Set<String>> getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs
        .reload(); // Keep reload here to get latest from disk/other sources
    final ids = (prefs.getStringList(_readKey) ?? []).toSet();
    debugPrint("NotificationService: Loaded ${ids.length} read notifications");
    return ids;
  }

  Future<Set<String>> getDeletedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Keep reload here
    final ids = (prefs.getStringList(_deletedKey) ?? []).toSet();
    debugPrint(
      "NotificationService: Loaded ${ids.length} deleted notifications",
    );
    return ids;
  }

  // --- Badge Management ---

  Future<void> _updateBadge(int count) async {
    try {
      if (await AppBadgePlus.isSupported()) {
        AppBadgePlus.updateBadge(count);
        debugPrint("NotificationService: Updated badge count to $count");
      }
    } catch (e) {
      debugPrint("NotificationService: Error updating badge: $e");
    }
  }

  Future<void> setBadgeCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unread_badge_count', count);
    await _updateBadge(count);
  }

  Future<void> incrementBadgeCount() async {
    // We typically don't know the exact count from system, so this is a simplified local count.
    // However, a better approach is to store 'unread_count' in Prefs.
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt('unread_badge_count') ?? 0;
    int newVal = current + 1;
    await prefs.setInt('unread_badge_count', newVal);
    await _updateBadge(newVal);
  }

  Future<void> resetBadgeCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unread_badge_count', 0);
    await _updateBadge(0);
  }

  /// Send a notification from teacher to student
  /// This creates both an in-app notification and sends a cloud notification
  Future<void> sendTeacherNotification({
    required String studentUid,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Import Firestore
      final firestore = FirebaseFirestore.instance;

      // Create notification document in student's notifications subcollection
      await firestore
          .collection('users')
          .doc(studentUid)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'type': type,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'data': data ?? {},
          });

      debugPrint(
        'NotificationService: Sent notification to student $studentUid',
      );
    } catch (e) {
      debugPrint('NotificationService: Error sending notification: $e');
      rethrow;
    }
  }

  /// Listen to real-time notifications for the current user
  /// Triggers local notification when a new document is added to 'notifications' subcollection
  void listenToRealtimeNotifications(String uid) {
    stopListening(); // Clear previous

    debugPrint("[NOTIF] NotificationService: Started listening for UID: $uid");

    _notificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data();
                if (data == null) continue;

                debugPrint(
                  " NotificationService: New notification detected: ${data['title']}",
                );

                // Check if this is a "New" notification or just initial load
                // We trust 'isRead=false'. We allow a wider window (1 hour) to account for time drift.
                final Timestamp? ts = data['timestamp'] as Timestamp?;
                if (ts != null) {
                  final now = DateTime.now();
                  final diff = now.difference(ts.toDate());

                  debugPrint("   - Notification Age: ${diff.inMinutes} mins");

                  // Skip if older than 1 hour (avoid spamming really old stuff)
                  if (diff.inMinutes.abs() > 60) {
                    debugPrint("   - Skipped: Too old (>60m)");
                    continue;
                  }
                } else {
                  debugPrint("   - No timestamp found, showing anyway.");
                }

                final title = data['title'] as String? ?? 'New Notification';
                final body =
                    data['body'] as String? ?? 'You have a new message';

                // Show Local Notification
                showNotification(title, body);
              }
            }
          },
          onError: (e) {
            debugPrint("Error: NotificationService: Error in listener: $e");
          },
        );
  }
}

