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

    if (nextPhase != _AppPhase.ready) {
      _startupReadyDelayTimer?.cancel();
      _startupReadyDelayTimer = null;
    } else if (mounted && previous == _AppPhase.booting) {
      final elapsed = Duration(
        milliseconds: DateTime.now().millisecondsSinceEpoch -
            _processStartEpochMs,
      );
      final remaining =
          _EnglishLearningAppState._minimumColdStartAnimation - elapsed;
      if (remaining > Duration.zero) {
        _startupReadyDelayTimer?.cancel();
        _startupReadyDelayTimer = Timer(remaining, () {
          _startupReadyDelayTimer = null;
          if (!mounted || _appPhase != _AppPhase.booting) return;
          _setPhase(
            _AppPhase.ready,
            reason: '${reason}_after_startup_animation',
          );
        });
        _logDiagnostic(
          'phase_transition_delayed instance=$_instanceId from=${previous.name} to=${nextPhase.name} mounted=$mounted reason=$reason remaining_ms=${remaining.inMilliseconds}',
        );
        return;
      }
    }

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
}
