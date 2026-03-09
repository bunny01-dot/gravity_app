// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'main.dart';

extension MainAppShellRuntime on _EnglishLearningAppState {
  void _setPhase(_AppPhase nextPhase, {required String reason}) {
    _logDiagnostic(
      'phase_transition_request instance=$_instanceId from=${_appPhase.name} to=${nextPhase.name} mounted=$mounted reason=$reason',
    );

    final allowReadyToRecovering =
        _appPhase == _AppPhase.ready && nextPhase == _AppPhase.recovering;

    if (nextPhase.index < _appPhase.index && !allowReadyToRecovering) {
      _logDiagnostic(
        'phase_transition_ignored instance=$_instanceId from=${_appPhase.name} to=${nextPhase.name} mounted=$mounted reason=$reason',
      );

      return;
    }

    if (nextPhase == _appPhase) return;

    final previous = _appPhase;

    if (!mounted) {
      if (nextPhase == _AppPhase.recovering) {
        _recoveryOverlaySerial++;
      }

      _appPhase = nextPhase;

      if (nextPhase == _AppPhase.ready) {
        _startupEscapeTimer?.cancel();
      }

      return;
    }

    setState(() {
      _appPhase = nextPhase;

      if (nextPhase == _AppPhase.recovering) {
        _recoveryOverlaySerial++;
      }
    });

    _logDiagnostic(
      'phase_transition instance=$_instanceId ${previous.name}->${nextPhase.name} mounted=$mounted reason=$reason',
    );

    if (nextPhase == _AppPhase.ready) {
      _startupEscapeTimer?.cancel();
    } else {
      _startStartupEscapeTimer(reason: 'phase_${nextPhase.name}_$reason');
    }
  }

  void _resetNavigatorReadinessGate() {
    _navigatorReadyObserver.reset();

    _navigatorReadyCompleter = Completer<void>();
  }

  void _bumpRestartToken() {
    _appRestartToken++;

    _resetNavigatorReadinessGate();
  }

  void _onNavigatorReady() {
    if (_navigatorReadyCompleter.isCompleted) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    _navigatorReadyCompleter.complete();

    _logDiagnosticOnce(
      'navigator_ready',

      'navigator_ready_epoch_ms=$nowMs uptime_ms=${nowMs - _processStartEpochMs}',
    );
  }

  Future<bool> _waitForNavigatorReady({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (!mounted) return false;

    if (_navigatorKey.currentState != null) {
      _onNavigatorReady();
    }

    try {
      await _navigatorReadyCompleter.future.timeout(timeout);

      return true;
    } catch (_) {
      _logDiagnostic(
        'navigator_ready_timeout timeout_ms=${timeout.inMilliseconds}',
      );

      return false;
    }
  }

  _ResumePolicyDecision _buildResumePolicyDecision(
    SharedPreferences prefs, {

    required DateTime now,

    required bool resumeAlreadyAttempted,
  }) {
    final snapshot = _loadSessionSnapshot(prefs);

    final nowMs = now.millisecondsSinceEpoch;

    final snapshotSavedAtMs = snapshot?.savedAtMillis ?? 0;

    final snapshotAgeMs = snapshotSavedAtMs > 0
        ? nowMs - snapshotSavedAtMs
        : -1;

    final snapshotIsFresh =
        snapshot != null &&
        snapshot.pendingRecovery &&
        snapshotAgeMs >= 0 &&
        snapshotAgeMs <=
            _EnglishLearningAppState._recoveryStateMaxAge.inMilliseconds;

    final backgroundAtMs =
        snapshot?.backgroundAtMillis ??
        prefs.getInt(_EnglishLearningAppState._backgroundAtKey);

    Duration? backgroundDuration;

    if (backgroundAtMs != null) {
      final ageMs = nowMs - backgroundAtMs;

      if (ageMs >= 0) {
        backgroundDuration = Duration(milliseconds: ageMs);
      }
    }

    return _ResumePolicyDecision(
      snapshotIsFresh: snapshotIsFresh,

      backgroundDuration: backgroundDuration,

      resumeAlreadyAttempted: resumeAlreadyAttempted,
    );
  }

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
