// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'main.dart';

extension MainAppShellRuntimeRestart on _EnglishLearningAppState {
  Future<void> _restartToSafeScreen({
    required bool forceLogin,

    String? role,

    String? lastRoute,

    String reason = 'unspecified',

    bool bypassCooldown = false,
  }) async {
    if (!mounted) return;

    if (_isRestarting) {
      _logRecovery(
        _activeRecoveryRunId,

        'restart skipped ($reason) because recovery is already active',
      );

      return;
    }

    final now = DateTime.now();

    if (!bypassCooldown &&
        _lastRecoveryAt != null &&
        now.difference(_lastRecoveryAt!) <
            _EnglishLearningAppState._recoveryCooldown) {
      _logRecovery(
        _activeRecoveryRunId,

        'restart skipped ($reason) due cooldown window',
      );

      return;
    }

    _lastRecoveryAt = now;

    final runId = ++_activeRecoveryRunId;

    _isRestarting = true;

    _activeRecoveryStartedAtMs = now.millisecondsSinceEpoch;

    _setPhase(_AppPhase.recovering, reason: 'restart_$reason');

    _logDiagnosticOnce(
      'recovery_start',

      'recovery_start_epoch_ms=${now.millisecondsSinceEpoch} reason=$reason',
    );

    _logDiagnosticOnce(
      'forced_restart_reason',

      'forced_safe_restart_reason=$reason',
    );

    unawaited(
      _persistDiagnosticReason(
        _EnglishLearningAppState._lastForcedSafeRestartReasonKey,

        reason,
      ),
    );

    _logRecovery(
      runId,

      'entered (reason=$reason, lastRoute=${lastRoute ?? "null"})',
    );

    _startRecoveryWatchdog(runId);

    try {
      final targetRole = role ?? _effectiveUserRole;

      final prefs = await SharedPreferences.getInstance().timeout(
        _EnglishLearningAppState._resumeIoTimeout,
      );

      final hasCompletedPlacement = await _resolvePlacementCompletion(prefs);

      ActiveRouteState? activeState;

      try {
        activeState = await ActiveRouteService.load().timeout(
          _EnglishLearningAppState._resumeIoTimeout,

          onTimeout: () => null,
        );
      } catch (_) {
        activeState = null;
      }

      if (!_isCurrentRecoveryRun(runId)) return;

      _pendingResumeState = activeState;

      setState(() {
        _effectiveIsLoggedIn = forceLogin;

        _effectiveUserRole = targetRole;

        _effectiveHasCompletedPlacement = hasCompletedPlacement;

        _homeOverride = null;

        _bumpRestartToken();
      });

      final route = _deriveHomeRouteName(
        isLoggedIn: forceLogin,

        role: targetRole,

        hasCompletedPlacement: hasCompletedPlacement,
      );

      await _persistSessionSnapshot(
        pendingRecovery: false,

        routeOverride: route,

        prefs: prefs,
      );

      final navigatorReady = await _waitForNavigatorReady();

      if (!_isCurrentRecoveryRun(runId)) return;

      if (navigatorReady) {
        await _resumeUserProgressIfNeeded();
      } else {
        _logRecovery(
          runId,

          'navigator not ready after restart; using safe root home only',
        );
      }

      _logRecovery(runId, 'state restored using safe route');
    } catch (e) {
      _logRecovery(runId, 'restart flow failed: $e');

      if (_isCurrentRecoveryRun(runId)) {
        setState(() {
          _effectiveIsLoggedIn = forceLogin;

          _effectiveUserRole = role ?? _effectiveUserRole;

          _homeOverride = null;

          _bumpRestartToken();
        });
      }
    } finally {
      await _forceExitRecovery(runId, reason: 'restart_complete');
    }
  }

  Future<void> _checkColdStartRecovery({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        _EnglishLearningAppState._resumeIoTimeout,
      );

      final snapshot = _loadSessionSnapshot(prefs);

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final snapshotPendingRaw = snapshot?.pendingRecovery ?? false;

      final snapshotSavedAtMs = snapshot?.savedAtMillis ?? 0;

      final snapshotAgeMs = snapshotSavedAtMs > 0
          ? nowMs - snapshotSavedAtMs
          : -1;

      final snapshotPending =
          snapshotPendingRaw &&
          snapshotAgeMs >= 0 &&
          snapshotAgeMs <=
              _EnglishLearningAppState._recoveryStateMaxAge.inMilliseconds;

      final wasBackgrounded =
          prefs.getBool(_EnglishLearningAppState._backgroundFlagKey) ?? false;

      final backgroundAtMs =
          snapshot?.backgroundAtMillis ??
          prefs.getInt(_EnglishLearningAppState._backgroundAtKey);

      final backgroundAgeMs = backgroundAtMs == null
          ? -1
          : nowMs - backgroundAtMs;

      final isBackgroundStateFresh =
          wasBackgrounded &&
          backgroundAgeMs >= 0 &&
          backgroundAgeMs <=
              _EnglishLearningAppState._recoveryStateMaxAge.inMilliseconds;

      if (snapshotPendingRaw && !snapshotPending) {
        await prefs
            .remove(_EnglishLearningAppState._sessionSnapshotKey)
            .timeout(_EnglishLearningAppState._resumeIoTimeout);

        _logDiagnostic(
          'stale_snapshot_recovery_flag_cleared age_ms=$snapshotAgeMs max_age_ms=${_EnglishLearningAppState._recoveryStateMaxAge.inMilliseconds}',
        );
      }

      if (wasBackgrounded && !isBackgroundStateFresh) {
        await prefs
            .setBool(_EnglishLearningAppState._backgroundFlagKey, false)
            .timeout(_EnglishLearningAppState._resumeIoTimeout);

        await prefs
            .remove(_EnglishLearningAppState._backgroundAtKey)
            .timeout(_EnglishLearningAppState._resumeIoTimeout);

        _logDiagnostic(
          'stale_background_recovery_flag_cleared age_ms=$backgroundAgeMs max_age_ms=${_EnglishLearningAppState._recoveryStateMaxAge.inMilliseconds}',
        );
      }

      final classification = isBackgroundStateFresh || snapshotPending
          ? 'warm_restore'
          : 'cold_start';

      _logDiagnosticOnce(
        'cold_warm_classification',

        'cold_vs_warm=$classification background=$isBackgroundStateFresh snapshot_pending=$snapshotPending force=$force',
      );

      final shouldRecover = force || isBackgroundStateFresh || snapshotPending;

      if (!shouldRecover) return;

      _isColdStartRecovering = true;

      await prefs
          .setBool(_EnglishLearningAppState._backgroundFlagKey, false)
          .timeout(_EnglishLearningAppState._resumeIoTimeout);

      await prefs
          .remove(_EnglishLearningAppState._backgroundAtKey)
          .timeout(_EnglishLearningAppState._resumeIoTimeout);

      final authUser = FirebaseAuth.instance.currentUser;

      final authHasUser = authUser != null;

      final prefsLoggedIn =
          prefs.getBool('is_logged_in') ?? _effectiveIsLoggedIn;

      final snapshotLoggedIn = snapshot?.isLoggedIn ?? prefsLoggedIn;

      if (prefsLoggedIn != authHasUser) {
        await prefs
            .setBool('is_logged_in', authHasUser)
            .timeout(
              _EnglishLearningAppState._resumeIoTimeout,

              onTimeout: () => false,
            );
      }

      if (snapshotLoggedIn != authHasUser) {
        _logDiagnostic(
          'cold_start_auth_snapshot_mismatch auth=$authHasUser snapshot=$snapshotLoggedIn',
        );
      }

      final shouldStayLoggedIn = authHasUser;

      final recoveredRole = shouldStayLoggedIn
          ? await _resolvePersistedUserRole(
              prefs: prefs,

              authEmail: authUser.email,

              fallbackRole: snapshot?.role ?? _effectiveUserRole,
            ).timeout(
              _EnglishLearningAppState._resumeIoTimeout,

              onTimeout: () =>
                  prefs.getString('user_role') ?? _effectiveUserRole,
            )
          : 'student';

      final snapshotRoute = snapshot?.homeRoute ?? '';

      final lastRoute = snapshotRoute.isNotEmpty
          ? snapshotRoute
          : prefs.getString(_EnglishLearningAppState._lastHomeRouteKey);

      debugPrint(
        'Recovery: cold-start restore triggered (background=$wasBackgrounded, snapshotPending=$snapshotPending, forced=$force)',
      );

      await _restartToSafeScreen(
        forceLogin: shouldStayLoggedIn,

        role: recoveredRole,

        lastRoute: lastRoute,

        reason: force
            ? 'cold_start_forced_recovery'
            : 'cold_start_snapshot_recovery',

        bypassCooldown: true,
      );
    } catch (e) {
      debugPrint('Recovery: cold-start check failed: $e');
    } finally {
      _isColdStartRecovering = false;
    }
  }
}
