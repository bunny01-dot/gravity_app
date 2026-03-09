// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'main.dart';

extension MainAppShellRuntimeRecovery on _EnglishLearningAppState {
  String _resumePolicyRejectReason(_ResumePolicyDecision decision) {
    if (decision.resumeAlreadyAttempted) {
      return 'resume_already_attempted';
    }

    if (!decision.snapshotIsFresh) {
      return 'resume_snapshot_stale_or_missing';
    }

    if (decision.backgroundDuration == null) {
      return 'resume_background_duration_unknown';
    }

    if (decision.backgroundDuration! > kLongBackgroundThreshold) {
      return 'resume_background_too_long';
    }

    return 'resume_policy_rejected';
  }

  void _cancelResumeAttemptDeadline() {
    _resumeAttemptDeadline?.cancel();

    _resumeAttemptDeadline = null;
  }

  Future<void> _restartToSafeHome({
    required String reason,

    bool clearActiveRoute = true,

    bool? isLoggedIn,

    String? role,

    bool? hasCompletedPlacement,
  }) async {
    // Phase-terminal restart: cancel recovery flow, go READY, and route home.

    _cancelResumeAttemptDeadline();

    _recoveryWatchdog?.cancel();

    _activeRecoveryStartedAtMs = null;

    _pendingResumeState = null;

    _isResumingDeepLink = false;

    _isHandlingResume = false;

    _logDiagnostic('authoritative_restart reason=$reason');

    unawaited(
      _persistDiagnosticReason(
        _EnglishLearningAppState._lastForcedSafeRestartReasonKey,

        reason,
      ),
    );

    bool resolvedIsLoggedIn = _effectiveIsLoggedIn;

    String resolvedRole = _effectiveUserRole;

    bool resolvedHasCompletedPlacement = _effectiveHasCompletedPlacement;

    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        _EnglishLearningAppState._resumeIoTimeout,
      );

      final identity = await _resolveAuthoritativeSessionIdentity(prefs: prefs);

      resolvedIsLoggedIn = isLoggedIn ?? identity.isLoggedIn;

      resolvedRole = (role != null && role.isNotEmpty) ? role : identity.role;

      resolvedHasCompletedPlacement =
          hasCompletedPlacement ?? await _resolvePlacementCompletion(prefs);
    } catch (e) {
      _logDiagnostic(
        'authoritative_restart_identity_fallback reason=$reason error=$e',
      );

      resolvedIsLoggedIn = isLoggedIn ?? _effectiveIsLoggedIn;

      resolvedRole = (role != null && role.isNotEmpty)
          ? role
          : _effectiveUserRole;

      resolvedHasCompletedPlacement =
          hasCompletedPlacement ?? _effectiveHasCompletedPlacement;
    }

    if (!mounted) return;

    setState(() {
      _effectiveIsLoggedIn = resolvedIsLoggedIn;

      _effectiveUserRole = resolvedRole;

      _effectiveHasCompletedPlacement = resolvedHasCompletedPlacement;

      _isRestarting = false;

      _homeOverride = null;

      _bumpRestartToken();
    });

    _setPhase(_AppPhase.ready, reason: 'authoritative_restart_$reason');

    await _navigateToGuaranteedSafeHome(reason: reason);

    unawaited(
      _finalizeAuthoritativeRestartCleanup(clearActiveRoute: clearActiveRoute),
    );
  }

  Future<void> _finalizeAuthoritativeRestartCleanup({
    required bool clearActiveRoute,
  }) async {
    try {
      if (clearActiveRoute) {
        await ActiveRouteService.clear().timeout(
          _EnglishLearningAppState._resumeIoTimeout,
        );
      }

      final prefs = await SharedPreferences.getInstance().timeout(
        _EnglishLearningAppState._resumeIoTimeout,
      );

      await prefs
          .setBool(_EnglishLearningAppState._backgroundFlagKey, false)
          .timeout(
            _EnglishLearningAppState._resumeIoTimeout,

            onTimeout: () => false,
          );

      await prefs
          .remove(_EnglishLearningAppState._backgroundAtKey)
          .timeout(
            _EnglishLearningAppState._resumeIoTimeout,

            onTimeout: () => false,
          );

      await _persistSessionSnapshot(
        pendingRecovery: false,

        prefs: prefs,
      ).timeout(_EnglishLearningAppState._resumeIoTimeout, onTimeout: () {});
    } catch (_) {}
  }

  Future<void> _runColdStartRecoveryOnce() async {
    if (_coldRecoveryRanForProcess) return;

    _coldRecoveryRanForProcess = true;

    _setPhase(_AppPhase.recovering, reason: 'process_start_cold_recovery');

    try {
      await _checkColdStartRecovery(force: false).timeout(
        _EnglishLearningAppState._coldStartRecoveryTimeout,

        onTimeout: () {
          _logDiagnostic(
            'cold_start_recovery_guard_timeout timeout_ms=${_EnglishLearningAppState._coldStartRecoveryTimeout.inMilliseconds}',
          );

          _isColdStartRecovering = false;

          if (_isRestarting && _activeRecoveryRunId > 0) {
            unawaited(
              _forceExitRecovery(
                _activeRecoveryRunId,

                reason: 'cold_start_guard_timeout',
              ),
            );
          }
        },
      );
    } catch (e) {
      _logDiagnostic('cold_start_recovery_unhandled_error: $e');
    } finally {
      _setPhase(_AppPhase.ready, reason: 'cold_recovery_complete');
    }
  }

  void _logRecovery(int runId, String message) {
    debugPrint('Recovery[$runId]: $message');
  }

  bool _isCurrentRecoveryRun(int runId) {
    return mounted && _isRestarting && _activeRecoveryRunId == runId;
  }

  void _startRecoveryWatchdog(int runId) {
    _recoveryWatchdog?.cancel();

    _recoveryWatchdog = Timer(
      _EnglishLearningAppState._recoveryHardTimeout,

      () {
        if (!_isRestarting || runId != _activeRecoveryRunId) return;

        _logRecovery(runId, 'watchdog timeout -> forcing recovery exit');

        unawaited(_forceExitRecovery(runId, reason: 'watchdog_timeout'));
      },
    );
  }

  Future<void> _forceExitRecovery(int runId, {required String reason}) async {
    if (!_isCurrentRecoveryRun(runId)) return;

    _recoveryWatchdog?.cancel();

    _cancelResumeAttemptDeadline();

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final startedAtMs = _activeRecoveryStartedAtMs;

    final durationMs = startedAtMs == null
        ? 0
        : (nowMs - startedAtMs).clamp(0, 600000);

    _activeRecoveryStartedAtMs = null;

    if (!mounted) return;

    setState(() {
      _homeOverride = null;

      _isRestarting = false;
    });

    _setPhase(_AppPhase.ready, reason: 'force_exit_$reason');

    unawaited(_recordRecoveryExit(reason: reason, durationMs: durationMs));

    try {
      await _persistSessionSnapshot(
        pendingRecovery: false,
      ).timeout(_EnglishLearningAppState._resumeIoTimeout);
    } catch (_) {}

    _logDiagnosticOnce(
      'recovery_end',

      'recovery_end_epoch_ms=$nowMs duration_ms=$durationMs reason=$reason',
    );

    _logRecovery(runId, 'exit complete ($reason)');
  }

  Future<void> _recordRecoveryExit({
    required String reason,

    required int durationMs,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        _EnglishLearningAppState._resumeIoTimeout,
      );

      await prefs.setString(
        _EnglishLearningAppState._lastRecoveryExitReasonKey,

        reason,
      );

      await prefs.setInt(
        _EnglishLearningAppState._lastRecoveryDurationMsKey,

        durationMs,
      );
    } catch (_) {}
  }
}
