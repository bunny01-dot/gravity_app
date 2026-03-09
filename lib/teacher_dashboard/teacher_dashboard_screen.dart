import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'package:gravity_app/services/data_service.dart' as data_service;
import 'package:gravity_app/services/notification_service.dart';
import 'package:gravity_app/screens/teacher_notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gravity_app/services/fcm_service.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:gravity_app/widgets/animated_bottom_nav.dart';
import 'package:gravity_app/widgets/modern_glass_dialog.dart';
import 'package:gravity_app/screens/student_detail_screen.dart';
import 'package:gravity_app/teacher_dashboard/widgets/teacher_dashboard_header.dart';
import 'package:gravity_app/teacher_dashboard/widgets/teacher_dashboard_stats.dart';
import 'package:gravity_app/teacher_dashboard/widgets/teacher_empty_state.dart';
import 'package:gravity_app/teacher_dashboard/widgets/teacher_filters_bar.dart';
import 'package:gravity_app/teacher_dashboard/widgets/teacher_notifications_section.dart';
import 'package:gravity_app/teacher_dashboard/widgets/teacher_student_list.dart';
import 'package:gravity_app/teacher_dashboard/shared/teacher_panel.dart';
import 'package:gravity_app/teacher_dashboard/shared/teacher_translucent_card.dart';

// ZERO-COST: Cache imports
import 'package:gravity_app/core/cache/students_cache.dart';
import 'package:gravity_app/core/cache/attendance_cache.dart';
import 'package:gravity_app/core/cache/teacher_notifications_cache.dart';
import 'package:gravity_app/screens/teacher_debug_errors_screen.dart';
import 'package:gravity_app/screens/teacher_feedback_screen.dart';
import 'package:gravity_app/services/auth_service.dart';
import 'package:lottie/lottie.dart';

part 'teacher_dashboard_shell.dart';
part 'teacher_dashboard_tabs.dart';
part 'teacher_dashboard_library.dart';
part 'teacher_dashboard_notifications.dart';
part 'teacher_dashboard_students.dart';
part 'teacher_dashboard_actions.dart';

class TeacherDashboard extends StatefulWidget {
  final VoidCallback? onLogout;
  const TeacherDashboard({super.key, this.onLogout});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;
  final data_service.DataService _dataService = data_service.DataService();
  String _userEmail = '';

  // Library State
  String _selectedCategory = 'vocabulary';
  final List<String> _categories = [
    'vocabulary',
    'verbs',
    'reading',
    'writing',
    'speaking',
    'listening',
    'quiz',
  ];

  // Settings
  bool _notificationsEnabled = true;
  String _photoUrl = '';

  final NotificationService _notificationService = NotificationService();
  Set<String> _deletedIds = {};
  Set<String> _readIds = {}; // Added read IDs

  // Double-back press to exit
  DateTime? _lastBackPressed;

  // ZERO-COST: Cache refresh timer (replaces real-time listeners)
  Timer? _cacheRefreshTimer;
  int _notificationCount = 0;
  bool _notificationsReady = false;
  bool _isDashboardPullRefreshing = false;
  bool _showDashboardPullRefreshLottie = false;
  Timer? _dashboardPullRefreshLottieTimer;

  @override
  void initState() {
    super.initState();
    _loadTeacherInfo();
    _notificationService.init();
    _setupCacheRefreshTimer(); // ZERO-COST: Periodic cache refresh
    FCMService().subscribeToTopic('teachers');
    _ensureTeacherRole();
  }

  /// Self-repair: Ensure the user is marked as teacher in DB
  Future<void> _ensureTeacherRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await user.getIdTokenResult(true);
      final claims = token.claims ?? const <String, dynamic>{};
      final hasTeacherClaim =
          claims['role'] == 'teacher' || claims['admin'] == true;
      final isTeacherEmail = AuthService().isTeacher(user.email);

      // Avoid role self-escalation attempts for non-teacher accounts.
      // Firestore rules intentionally block this and would emit permission-denied.
      if (!hasTeacherClaim && !isTeacherEmail) {
        debugPrint(
          'TeacherDashboard: skip teacher-role self-repair (insufficient authority)',
        );
        return;
      }

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final doc = await docRef.get();

      if (doc.exists) {
        if (doc.data()?['role'] != 'teacher') {
          debugPrint('TeacherDashboard: fixing teacher role in Firestore');
          await docRef.update({'role': 'teacher'});
        }
      } else {
        debugPrint('TeacherDashboard: creating teacher doc in Firestore');
        await docRef.set({
          'email': user.email,
          'role': 'teacher',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint(
          'TeacherDashboard: permission denied while ensuring teacher role; skipped',
        );
        return;
      }
      debugPrint('TeacherDashboard: failed to ensure teacher role: $e');
    } catch (e) {
      debugPrint('TeacherDashboard: failed to ensure teacher role: $e');
    }
  }

  @override
  void dispose() {
    _dashboardPullRefreshLottieTimer?.cancel();
    _cacheRefreshTimer?.cancel();
    super.dispose();
  }

  /// ZERO-COST: Periodic cache refresh instead of real-time listeners
  /// Refreshes every 5 minutes to check for new notifications
  void _setupCacheRefreshTimer() {
    // Initial load
    _refreshNotificationCount();

    // Refresh every 5 minutes (instead of real-time)
    _cacheRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _refreshNotificationCount(),
    );
  }

  Future<void> _refreshNotificationCount() async {
    try {
      // Fetch latest notifications from CORRECT cache
      final notifications = await TeacherNotificationsCache()
          .getNotifications();

      // Count unread: Not deleted AND Not read
      final unread = notifications.where((n) {
        final id = n['id'] as String;
        return !_deletedIds.contains(id) && !_readIds.contains(id);
      }).length;

      if (mounted) {
        setState(() {
          _notificationCount = unread;
          _notificationsReady = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to refresh notification count: $e');
      if (mounted) {
        setState(() {
          _notificationsReady = true;
        });
      }
    }
  }

  Future<void> _loadTeacherInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('user_email') ?? '';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _deletedIds = (prefs.getStringList('teacher_deleted_notifications') ?? [])
          .toSet();
      _readIds = (prefs.getStringList('teacher_read_notifications') ?? [])
          .toSet();
      _photoUrl = prefs.getString('photo_url') ?? '';
    });

    // Check Cloud for updates
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('photo_url')) {
          final photo = data['photo_url'];
          await prefs.setString('photo_url', photo);
          if (mounted) setState(() => _photoUrl = photo);
        } else {
          await prefs.remove('photo_url');
          if (mounted) setState(() => _photoUrl = '');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false, // We'll handle the pop manually
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        // If not on dashboard (index 0), navigate back to dashboard
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return;
        }

        // On dashboard - check for double back press
        final now = DateTime.now();
        final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
            _lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2);

        if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
          _lastBackPressed = now;

          // Show message to press again
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.black87),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Press back again to exit',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFFFD700),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        // Close the app
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF030305)
            : theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Background Blobs
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (isDark ? const Color(0xFFFFD700) : colorScheme.primary)
                          .withValues(alpha: isDark ? 0.15 : 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (isDark ? const Color(0xFFFFA500) : colorScheme.secondary)
                          .withValues(alpha: isDark ? 0.1 : 0.08),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  TeacherDashboardHeader(
                    title: _getAppBarTitle(),
                    notificationCount: _notificationsReady
                        ? _notificationCount
                        : null,
                    photoUrl: _photoUrl,
                    onNotificationsPressed: _handleNotificationsTap,
                    onProfilePressed: _handleProfileTap,
                  ),
                  // Main Content
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: [
                        _buildDashboardTab(),
                        _buildStudentsTab(),
                        _buildLibraryTab(),
                        _buildSettingsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }
}

class _LibraryEntry {
  final String? header;
  final Map<String, String>? item;

  const _LibraryEntry._({this.header, this.item});

  factory _LibraryEntry.header(String title) {
    return _LibraryEntry._(header: title);
  }

  factory _LibraryEntry.item(Map<String, String> item) {
    return _LibraryEntry._(item: item);
  }

  bool get isHeader => header != null;
}

class _StageMetrics {
  final int currentStage;
  final int completedStages;
  final int assessmentCompleted;

  const _StageMetrics({
    required this.currentStage,
    required this.completedStages,
    required this.assessmentCompleted,
  });

  int get assessmentTotal => completedStages;

  factory _StageMetrics.empty() {
    return const _StageMetrics(
      currentStage: 1,
      completedStages: 0,
      assessmentCompleted: 0,
    );
  }
}
