// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'main.dart';

extension MainAppShellRuntimeAuth on _EnglishLearningAppState {
  Widget _buildTeacherDashboard() {
    return TeacherDashboard(onLogout: _handleLogout);
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Logout: Firebase signOut failed: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('is_logged_in', false);
    } catch (e) {
      debugPrint('Logout: Failed to update local login state: $e');
    }

    if (!mounted) return;

    setState(() {
      _effectiveIsLoggedIn = false;

      _effectiveUserRole = 'student';

      _homeOverride = null;
    });

    unawaited(
      _persistSessionSnapshot(
        pendingRecovery: false,

        routeOverride: _EnglishLearningAppState._routeLanding,
      ),
    );

    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),

      (_) => false,
    );
  }

  Future<void> _initFCM() async {
    // FCM is not fully supported on Windows/Linux targets by the official plugin yet.

    bool isFCMSupported =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (isFCMSupported) {
      try {
        debugPrint(
          "Attempting FCM init on supported platform: ${defaultTargetPlatform.name}",
        );

        // Initialize FCM with role isolation

        if (widget.userRole == 'teacher') {
          await FCMService().initForTeacher();
        } else {
          await FCMService().initForStudent();
        }

        debugPrint(" FCM initialized");

        // Request Permission Interactively if needed (ensure context is ready?)

        // Ideally we do this on a user action, but for now we do it on app launch since it's a critical feature.
      } catch (e) {
        debugPrint(
          " FCM initialization failed (Push Notifications disabled): $e",
        );
      }
    }
  }
}
