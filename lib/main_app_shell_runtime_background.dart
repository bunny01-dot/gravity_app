// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'main.dart';

extension MainAppShellRuntimeBackground on _EnglishLearningAppState {
  Future<void> _markBackgrounded() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final backgroundAt = DateTime.now().millisecondsSinceEpoch;

      await prefs.setBool(_EnglishLearningAppState._backgroundFlagKey, true);

      await prefs.setInt(
        _EnglishLearningAppState._backgroundAtKey,

        backgroundAt,
      );

      final route = _deriveHomeRouteName(
        isLoggedIn: _effectiveIsLoggedIn,

        role: _effectiveUserRole,

        hasCompletedPlacement: _effectiveHasCompletedPlacement,
      );

      await _persistHomeRoute(route, prefs: prefs);

      await _persistSessionSnapshot(
        pendingRecovery: true,

        backgroundAtMillis: backgroundAt,

        routeOverride: route,

        prefs: prefs,
      );
    } catch (e) {
      debugPrint('Recovery: failed to mark backgrounded: $e');
    }
  }

  Future<void> _markForegrounded() async {
    if (mounted) {
      setState(() {
        _isBackgrounded = false;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_EnglishLearningAppState._backgroundFlagKey, false);

      await prefs.remove(_EnglishLearningAppState._backgroundAtKey);

      await _persistSessionSnapshot(
        pendingRecovery: false,

        routeOverride:
            prefs.getString(_EnglishLearningAppState._lastHomeRouteKey) ??
            _deriveHomeRouteName(
              isLoggedIn: _effectiveIsLoggedIn,

              role: _effectiveUserRole,

              hasCompletedPlacement: _effectiveHasCompletedPlacement,
            ),

        prefs: prefs,
      );
    } catch (e) {
      debugPrint('Recovery: failed to mark foregrounded: $e');
    }
  }

  Future<bool> _resolvePlacementCompletion(SharedPreferences prefs) async {
    try {
      await PlacementStateService.ensureInitialized().timeout(
        _EnglishLearningAppState._resumeIoTimeout,
      );

      final status = await PlacementStateService.getPlacementQuizStatus()
          .timeout(_EnglishLearningAppState._resumeIoTimeout);

      return status == PlacementStateService.statusCompleted;
    } catch (_) {
      return _effectiveHasCompletedPlacement;
    }
  }

  String _deriveHomeRouteName({
    required bool isLoggedIn,

    required String role,

    required bool hasCompletedPlacement,
  }) {
    if (!isLoggedIn) return _EnglishLearningAppState._routeLanding;

    if (role == 'teacher') {
      return _EnglishLearningAppState._routeTeacherDashboard;
    }

    if (!hasCompletedPlacement) return _EnglishLearningAppState._routePlacement;

    return _EnglishLearningAppState._routeDashboard;
  }

  Widget _buildGuaranteedSafeHome() {
    if (!_firebaseReady) {
      return const InitializationErrorScreen();
    }

    if (_effectiveIsLoggedIn) {
      if (_effectiveUserRole == 'teacher') {
        return _buildTeacherDashboard();
      }
      return _effectiveHasCompletedPlacement
          ? DashboardScreen(
              themeMode: AppThemeService.themeModeNotifier.value,
              onThemeModeChanged: _handleThemeModeChanged,
            )
          : const PlacementEntryScreen();
    }
    return const LandingScreen();
  }
}
