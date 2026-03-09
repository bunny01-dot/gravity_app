// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'main.dart';

extension MainAppShellRuntimeWatchdog on _EnglishLearningAppState {
  void _markFirstFrameCommitted() {
    if (!mounted || _firstFrameCommitted) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    _firstFrameCommitted = true;

    _firstFrameCommittedAtMs = nowMs;

    _logDiagnosticOnce(
      'first_frame_committed',
      'first_frame_commit_epoch_ms=$nowMs uptime_ms=${nowMs - _processStartEpochMs}',
    );

    _resolveBlackScreenWatchdogIfSafe();
  }

  void _markReadyUiRendered() {
    if (!mounted || _nonRecoveryUiRendered) return;

    _nonRecoveryUiRendered = true;

    _startupEscapeTimer?.cancel();

    _resolveBlackScreenWatchdogIfSafe();
  }

  void _startStartupEscapeTimer({required String reason}) {
    _startupEscapeTimer?.cancel();

    if (_appPhase == _AppPhase.ready) return;

    _logDiagnostic(
      'startup_escape_armed instance=$_instanceId phase=${_appPhase.name} reason=$reason timeout_ms=${_EnglishLearningAppState._startupEscapeTimeout.inMilliseconds}',
    );

    _startupEscapeTimer = Timer(
      _EnglishLearningAppState._startupEscapeTimeout,
      () {
        if (!mounted) return;

        if (_appPhase == _AppPhase.ready) return;

        _logDiagnostic(
          'startup_escape_timeout instance=$_instanceId phase=${_appPhase.name} timeout_ms=${_EnglishLearningAppState._startupEscapeTimeout.inMilliseconds}',
        );

        if (_isRestarting && _activeRecoveryRunId > 0) {
          unawaited(
            _forceExitRecovery(
              _activeRecoveryRunId,
              reason: 'startup_escape_timeout',
            ),
          );
        }

        _setPhase(_AppPhase.ready, reason: 'startup_escape_timeout');
      },
    );
  }

  void _startBlackScreenWatchdog() {
    _blackScreenWatchdog?.cancel();

    _blackScreenWatchdogResolved = false;

    _blackScreenWatchdog = Timer(
      _EnglishLearningAppState._blackScreenWatchdogTimeout,
      () {
        if (!mounted || _blackScreenWatchdogResolved || _isBackgrounded) return;

        final reason =
            'watchdog_timeout phase=${_appPhase.name} first_frame=$_firstFrameCommitted first_frame_at=$_firstFrameCommittedAtMs ready_ui=$_nonRecoveryUiRendered';

        _logDiagnostic('fatal_black_screen_watchdog $reason');

        unawaited(
          _persistDiagnosticReason(
            _EnglishLearningAppState._lastWatchdogFailureReasonKey,
            reason,
          ),
        );

        unawaited(
          _restartToSafeScreen(
            forceLogin: _effectiveIsLoggedIn,
            role: _effectiveUserRole,
            reason: 'black_screen_watchdog_timeout',
            bypassCooldown: true,
          ),
        );
      },
    );
  }

  void _resolveBlackScreenWatchdogIfSafe() {
    if (_blackScreenWatchdogResolved) return;

    if (!_firstFrameCommitted || !_nonRecoveryUiRendered) return;

    _blackScreenWatchdogResolved = true;

    _blackScreenWatchdog?.cancel();

    _logDiagnostic('black_screen_watchdog_resolved');
  }

  Future<void> _persistDiagnosticReason(String key, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        _EnglishLearningAppState._resumeIoTimeout,
      );

      await prefs.setString(key, reason);
    } catch (_) {}
  }

  void _recordLifecyclePath(String path) {
    _logDiagnostic('lifecycle_path $path');

    unawaited(_persistLifecyclePath(path));
  }

  Future<void> _persistLifecyclePath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        _EnglishLearningAppState._resumeIoTimeout,
      );

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(
        _EnglishLearningAppState._lastLifecyclePathKey,
        path,
      );

      await prefs.setInt(
        _EnglishLearningAppState._lastLifecyclePathTsKey,
        nowMs,
      );
    } catch (_) {}
  }
}
