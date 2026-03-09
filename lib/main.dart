import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb, defaultTargetPlatform
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';
import 'teacher_dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gravity_app/services/sfx/sfx_manager.dart';
import 'package:gravity_app/auth/login_screen.dart';
import 'package:gravity_app/services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;
import 'package:gravity_app/widgets/gravity_logo.dart';
import 'package:gravity_app/screens/initialization_error_screen_fixed.dart';
import 'package:gravity_app/widgets/system_crash_card.dart'; // Import Crash Card
import 'firebase_options.dart';
import 'package:gravity_app/services/teacher_notification_service.dart';

import 'package:gravity_app/utils/sound_navigation_observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:gravity_app/core/lifecycle/app_lifecycle_manager.dart';
import 'package:gravity_app/services/student_data_preloader.dart';
import 'package:gravity_app/services/placement_state_service.dart';
import 'package:gravity_app/services/stage_progress_service.dart';
import 'package:gravity_app/screens/placement_entry_screen.dart';
import 'package:gravity_app/services/active_route_service.dart';
import 'package:gravity_app/services/stage_content_service.dart';
import 'package:gravity_app/services/daily_task_completion_service.dart';
import 'package:gravity_app/screens/daily_quiz_screen.dart';
import 'package:gravity_app/screens/daily_speaking_challenge_screen.dart';
import 'package:gravity_app/screens/lesson_future_continuous_screen.dart';
import 'package:gravity_app/screens/lesson_direct_indirect_speech_screen.dart';
import 'package:gravity_app/screens/lesson_prepositions_screen.dart';
import 'package:gravity_app/screens/lesson_subjects_screen.dart';
import 'package:gravity_app/screens/lesson_parts_of_speech_screen.dart';
import 'package:gravity_app/screens/lesson_articles_screen.dart';
import 'package:gravity_app/widgets/recovery_debug_panel.dart';
import 'package:gravity_app/widgets/global_xp_overlay.dart';
import 'package:gravity_app/services/auth_service.dart';
import 'package:gravity_app/services/app_theme_service.dart';
import 'package:gravity_app/core/theme/app_theme.dart';
import 'package:lottie/lottie.dart';

// ...

import 'package:flutter/services.dart';

part 'main_bootstrap_shell.dart';
part 'main_app_shell.dart';
part 'main_app_shell_runtime.dart';
part 'main_recovery_widgets.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
final int _processStartEpochMs = DateTime.now().millisecondsSinceEpoch;
// Resume is an optimization. If confidence is low, force a safe restart.
const Duration kMaxResumeWindow = Duration(seconds: 3);
const Duration kLongBackgroundThreshold = Duration(minutes: 10);

Future<String> _resolvePersistedUserRole({
  required SharedPreferences prefs,
  required String? authEmail,
  String fallbackRole = 'student',
}) async {
  final roleFromAuth = authEmail == null
      ? null
      : AuthService().getUserRole(authEmail);
  final currentPrefRole = prefs.getString('user_role');
  final resolvedRole = roleFromAuth ?? currentPrefRole ?? fallbackRole;
  if (currentPrefRole != resolvedRole) {
    try {
      await prefs.setString('user_role', resolvedRole);
    } catch (_) {}
  }
  return resolvedRole;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Global Error Handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _reportErrorToTeacher(details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    _reportErrorToTeacher(error, stack);
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return SystemCrashCard(details: details);
  };
  // First install launch gets full intro; later cold launches use a shorter one.
  final prefs = await SharedPreferences.getInstance();
  _isInitialAppLaunch = !(prefs.getBool('has_launched_once') ?? false);
  if (_isInitialAppLaunch) {
    await prefs.setBool('has_launched_once', true);
  }
  // Load saved theme before first frame to avoid light->dark flash.
  await AppThemeService.loadThemeModePreference();

  runApp(const AppBootstrapShell());
}

void _reportErrorToTeacher(dynamic error, StackTrace? stack) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Get student name from SharedPreferences (more reliable)
    final prefs = await SharedPreferences.getInstance();
    final studentName =
        prefs.getString('user_name') ??
        user.displayName ??
        user.email?.split('@')[0] ??
        'Student';

    //  FIX: Abstract error into teacher-friendly category
    String errorCategory = _categorizeError(error.toString());
    String severity = _getErrorSeverity(error.toString());

    // Send abstracted notification (human-readable)
    TeacherNotificationService().sendStudentActivityNotification(
      studentId: user.uid,
      studentName: studentName,
      activityType: 'app_error',
      details: '$errorCategory|$severity', // Format: category|severity
    );

    //  Store full technical details in Firestore for developers
    try {
      await FirebaseFirestore.instance.collection('app_errors').add({
        'studentId': user.uid,
        'studentName': studentName,
        'errorMessage': error.toString(),
        'stackTrace': stack?.toString() ?? 'No stack trace',
        'category': errorCategory,
        'severity': severity,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'Flutter',
        'resolved': false,
      });
    } catch (e) {
      debugPrint('Failed to log error to Firestore: $e');
    }
  }
}

//  Categorize errors into user-friendly types
String _categorizeError(String errorMsg) {
  final msg = errorMsg.toLowerCase();

  if (msg.contains('renderflex') ||
      msg.contains('overflow') ||
      msg.contains('viewport')) {
    return 'UI Layout Issue';
  } else if (msg.contains('network') ||
      msg.contains('socket') ||
      msg.contains('connection')) {
    return 'Network Connection Issue';
  } else if (msg.contains('firebase') || msg.contains('firestore')) {
    return 'Data Sync Issue';
  } else if (msg.contains('null') || msg.contains('type')) {
    return 'Data Processing Issue';
  } else if (msg.contains('permission') || msg.contains('denied')) {
    return 'Permission Issue';
  } else if (msg.contains('format') || msg.contains('parse')) {
    return 'Data Format Issue';
  } else {
    return 'Technical Issue';
  }
}

//  Determine error severity
String _getErrorSeverity(String errorMsg) {
  final msg = errorMsg.toLowerCase();

  // Critical: Data loss, crashes, auth issues
  if (msg.contains('exception') ||
      msg.contains('fatal') ||
      msg.contains('crash')) {
    return 'high';
  }

  // Medium: Network, state errors
  if (msg.contains('network') ||
      msg.contains('timeout') ||
      msg.contains('state')) {
    return 'medium';
  }

  // Low: UI, rendering, minor issues
  if (msg.contains('overflow') ||
      msg.contains('render') ||
      msg.contains('layout')) {
    return 'low';
  }

  return 'medium'; // Default
}
