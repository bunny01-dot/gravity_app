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

  Future<void> _attemptMissedBackgroundRecoveryOnResume(
    DateTime resumedAt,
  ) async {
    if (_isCheckingMissedResumeRecovery ||
        _isHandlingResume ||
        _isBackgrounded) {
      return;
    }

    _isCheckingMissedResumeRecovery = true;

    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        _EnglishLearningAppState._resumeIoTimeout,
      );

      final snapshot = _loadSessionSnapshot(prefs);

      final nowMs = resumedAt.millisecondsSinceEpoch;

      final backgroundAtMs =
          snapshot?.backgroundAtMillis ??
          prefs.getInt(_EnglishLearningAppState._backgroundAtKey);

      final ageMs = backgroundAtMs == null ? -1 : nowMs - backgroundAtMs;

      final freshBackground =
          ageMs >= 0 &&
          ageMs <= _EnglishLearningAppState._recoveryStateMaxAge.inMilliseconds;

      final persistedBackgroundFlag =
          prefs.getBool(_EnglishLearningAppState._backgroundFlagKey) ?? false;

      final snapshotPending =
          (snapshot?.pendingRecovery ?? false) && freshBackground;

      if (!(persistedBackgroundFlag || snapshotPending)) {
        _recordLifecyclePath('missed_bg_check->no_pending_flags');

        _logDiagnostic(
          'resume_missed_background_check result=no_pending_flags',
        );

        return;
      }

      if (!freshBackground) {
        _recordLifecyclePath('missed_bg_check->stale');

        _logDiagnostic(
          'resume_missed_background_check result=stale age_ms=$ageMs max_age_ms=${_EnglishLearningAppState._recoveryStateMaxAge.inMilliseconds}',
        );

        return;
      }

      if (!mounted || _isBackgrounded) return;

      if (_lastResumeHandledAt != null &&
          resumedAt.difference(_lastResumeHandledAt!) <
              _EnglishLearningAppState._resumeDebounce) {
        _recordLifecyclePath('missed_bg_check->debounced');

        _logDiagnostic('resume_missed_background_check result=debounced');

        return;
      }

      _recordLifecyclePath('missed_bg_check->trigger_recovery age_ms=$ageMs');

      _logDiagnostic(
        'resume_missed_background_check result=trigger_recovery age_ms=$ageMs background_flag=$persistedBackgroundFlag snapshot_pending=$snapshotPending',
      );

      _isBackgrounded = true;

      _resumeAttempted = false;

      _cancelResumeAttemptDeadline();

      _lastResumeHandledAt = resumedAt;

      unawaited(_handleAppResumed());
    } catch (e) {
      _recordLifecyclePath('missed_bg_check->error');

      _logDiagnostic('resume_missed_background_check failed error=$e');
    } finally {
      _isCheckingMissedResumeRecovery = false;
    }
  }

  void _cancelInactiveBackgroundFallback() {
    _inactiveBackgroundTimer?.cancel();

    _inactiveBackgroundTimer = null;
  }

  void _scheduleInactiveBackgroundFallback() {
    if (_isBackgrounded) return;

    _inactiveBackgroundTimer?.cancel();

    _inactiveBackgroundTimer = Timer(
      _EnglishLearningAppState._inactiveBackgroundGrace,

      () {
        _inactiveBackgroundTimer = null;

        if (!mounted || _isBackgrounded) return;

        _recordLifecyclePath('inactive_fallback_timeout->mark_backgrounded');

        _markAppBackgrounded(source: 'inactive_grace_timeout');
      },
    );
  }

  void _markAppBackgrounded({required String source}) {
    if (_isBackgrounded) return;

    _isBackgrounded = true;

    _resumeAttempted = false;

    _cancelResumeAttemptDeadline();

    _captureBackgroundSnapshot();

    unawaited(_markBackgrounded());

    _recordLifecyclePath('background_marked(source=$source)');

    _logDiagnostic('background_marked source=$source');
  }

  void _captureBackgroundSnapshot() {
    final now = DateTime.now();

    if (_lastBackgroundSavedAt != null &&
        now.difference(_lastBackgroundSavedAt!) <
            _EnglishLearningAppState._backgroundSaveDebounce) {
      return;
    }

    _lastBackgroundSavedAt = now;

    unawaited(
      _persistSessionSnapshot(
        pendingRecovery: true,

        backgroundAtMillis: now.millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> _handleAppResumed() async {
    if (_isHandlingResume) return;

    _isHandlingResume = true;

    final runId = ++_resumeEventId;

    _logRecovery(runId, 'resume handler entered');

    try {
      if (!mounted) return;

      if (_isRestarting) {
        _logRecovery(runId, 'resume skipped because recovery is active');

        return;
      }

      if (_resumeAttempted) {
        _logRecovery(runId, 'resume already attempted in this process');

        await _restartToSafeHome(reason: 'resume_already_attempted');

        return;
      }

      // Mark before validation so any uncertainty/failure consumes the attempt.

      _resumeAttempted = true;

      SharedPreferences prefs;

      try {
        prefs = await SharedPreferences.getInstance().timeout(
          _EnglishLearningAppState._resumeIoTimeout,
        );
      } catch (_) {
        _logRecovery(runId, 'resume failed at prefs load');

        await _restartToSafeHome(reason: 'resume_prefs_unavailable');

        return;
      }

      final decision = _buildResumePolicyDecision(
        prefs,

        now: DateTime.now(),

        resumeAlreadyAttempted: false,
      );

      if (!decision.shouldAttemptResume) {
        final reason = _resumePolicyRejectReason(decision);

        final backgroundMs = decision.backgroundDuration?.inMilliseconds ?? -1;

        _logRecovery(
          runId,

          'resume policy rejected (reason=$reason snapshot_fresh=${decision.snapshotIsFresh} background_ms=$backgroundMs)',
        );

        await _restartToSafeHome(reason: reason);

        return;
      }

      // Pre-check: load the active route BEFORE entering the recovering phase.

      // If there is no active lesson (e.g. user was on the dashboard), we can

      // silently mark ready without ever showing the BlockingRecoveryOverlay.

      // This is the fix for the black screen when switching apps from the dashboard.

      ActiveRouteState? resumeTarget;

      try {
        resumeTarget = await ActiveRouteService.load().timeout(
          _EnglishLearningAppState._resumeIoTimeout,

          onTimeout: () => null,
        );
      } catch (_) {
        resumeTarget = null;
      }

      if (resumeTarget == null) {
        _logRecovery(
          runId,

          'pre-check: no active lesson - silent warm resume.',
        );
      } else {
        _logRecovery(
          runId,

          'pre-check: active lesson found - silent warm resume.',
        );
      }

      // Clear pending_recovery immediately on ACCEPT - before any async work.

      unawaited(
        _persistSessionSnapshot(
          pendingRecovery: false,

          prefs: prefs,
        ).timeout(_EnglishLearningAppState._resumeIoTimeout, onTimeout: () {}),
      );

      // NO _startResumeAttempt! We remain in the ready phase seamlessly.

      // We still run background validations and gracefully redirect IF they fail.

      bool isAttemptActive() => mounted; // App is still alive

      // 1) Firebase must be initialized

      if (!_firebaseReady || Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ).timeout(_EnglishLearningAppState._resumeIoTimeout);

          if (mounted) {
            setState(() {
              _firebaseReady = true;
            });
          }

          await _initFCM().timeout(
            _EnglishLearningAppState._resumeIoTimeout,

            onTimeout: () {},
          );
        } catch (e) {
          _logRecovery(runId, 'resume failed at firebase init: $e');

          await _restartToSafeHome(reason: 'resume_firebase_init_failed');

          return;
        }
      }

      if (!isAttemptActive()) return;

      // 2) Auth user must exist

      final authUser = FirebaseAuth.instance.currentUser;

      final hasUser = authUser != null;

      final prefLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (prefLoggedIn != hasUser) {
        await prefs
            .setBool('is_logged_in', hasUser)
            .timeout(
              _EnglishLearningAppState._resumeIoTimeout,

              onTimeout: () => false,
            );
      }

      final role =
          await _resolvePersistedUserRole(
            prefs: prefs,

            authEmail: authUser?.email,

            fallbackRole: _effectiveUserRole,
          ).timeout(
            _EnglishLearningAppState._resumeIoTimeout,

            onTimeout: () => hasUser
                ? (prefs.getString('user_role') ?? 'student')
                : 'student',
          );

      final hasCompletedPlacement = await _resolvePlacementCompletion(prefs);

      if (!isAttemptActive()) return;

      // 3) current_learning_stage must be valid

      final storedStage = await StageProgressService().getCurrentStage(
        prefs: prefs,
      );

      final stageValid = storedStage >= 1;

      if (!hasUser) {
        await _restartToSafeHome(
          reason: 'resume_missing_auth_user',

          isLoggedIn: false,

          role: role,

          hasCompletedPlacement: hasCompletedPlacement,
        );

        return;
      }

      if (!stageValid) {
        await StageProgressService().setCurrentStage(1, prefs: prefs);

        await _restartToSafeHome(
          reason: 'resume_invalid_stage',

          isLoggedIn: true,

          role: role,

          hasCompletedPlacement: hasCompletedPlacement,
        );

        return;
      }

      // resumeTarget was pre-loaded above before entering the recovering phase.

      // It is guaranteed non-null at this point (null case returned early above).

      if (!isAttemptActive()) return;

      // ------------------------------------------------------------

      // WARM RESUME - DO NOT NAVIGATE.

      //

      // _handleAppResumed is only ever called when the Dart process is still

      // alive (_isBackgrounded was true in-memory).  The Flutter navigator

      // stack is unchanged: the lesson/quiz screen is already on it with its

      // state intact.  Pushing a new route here would create a duplicate.

      //

      // All we need to do is:

      //   1. Update auth/role state (done above).

      //   2. Cancel watchdogs if they were active

      //   3. Mark foregrounded.

      //

      // Cold-start navigation (process was killed) is handled separately by

      // _checkColdStartRecovery -> _restartToSafeScreen, NOT here.

      // ------------------------------------------------------------

      _logRecovery(
        runId,

        'warm resume: background validation completed successfully',
      );

      if (mounted) {
        setState(() {
          _effectiveIsLoggedIn = hasUser;

          _effectiveUserRole = role;

          _effectiveHasCompletedPlacement = hasCompletedPlacement;

          _homeOverride = null;
        });
      }

      _cancelResumeAttemptDeadline();

      _recoveryWatchdog?.cancel();

      _blackScreenWatchdog?.cancel();

      unawaited(_markForegrounded());
    } catch (e) {
      _logRecovery(runId, 'resume handler exception: $e');

      await _restartToSafeHome(reason: 'resume_uncaught_exception');
    } finally {
      _logRecovery(runId, 'resume handler exited');

      _isHandlingResume = false;
    }
  }

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

  Future<void> _navigateToGuaranteedSafeHome({required String reason}) async {
    if (!mounted) return;

    final navigatorReady = await _waitForNavigatorReady();

    if (!mounted) return;

    if (!navigatorReady) {
      _logRecovery(
        _activeRecoveryRunId,

        'fallback navigation skipped (navigator not ready): $reason',
      );

      return;
    }

    final navigator = _navigatorKey.currentState;

    if (navigator == null) {
      _logRecovery(
        _activeRecoveryRunId,

        'fallback navigation skipped (navigator missing): $reason',
      );

      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => _buildGuaranteedSafeHome()),

      (_) => false,
    );

    _logRecovery(
      _activeRecoveryRunId,

      'fallback navigated to safe home: $reason',
    );
  }

  Future<void> _routeResumeFallback({
    required String reason,

    bool clearActiveRoute = true,
  }) async {
    if (clearActiveRoute) {
      await ActiveRouteService.clear();
    }

    _logDiagnosticOnce(
      'route_resume_result',

      'route_resume=fallback reason=$reason',
    );

    await _navigateToGuaranteedSafeHome(reason: reason);
  }

  Future<void> _resumeUserProgressIfNeeded() async {
    if (_isResumingDeepLink) return;

    final pending = _pendingResumeState;

    if (pending == null) {
      await _routeResumeFallback(reason: 'no_valid_resume_target');

      return;
    }

    final navigatorReady = await _waitForNavigatorReady();

    if (!navigatorReady) {
      _pendingResumeState = null;

      await _routeResumeFallback(reason: 'resume_navigator_not_ready');

      return;
    }

    _pendingResumeState = null;

    _isResumingDeepLink = true;

    try {
      await _resumeUserProgress(pending);
    } finally {
      _isResumingDeepLink = false;
    }
  }

  Future<void> _resumeUserProgress(ActiveRouteState state) async {
    if (!_effectiveIsLoggedIn) {
      await _routeResumeFallback(reason: 'resume_requires_login');

      return;
    }

    if (_effectiveUserRole == 'teacher') {
      await _routeResumeFallback(reason: 'resume_not_supported_for_teacher');

      return;
    }

    final navigator = _navigatorKey.currentState;

    if (navigator == null) {
      await _routeResumeFallback(reason: 'resume_missing_navigator');

      return;
    }

    try {
      if (state.lessonId == 'daily_quiz' || state.type == 'daily_quiz') {
        // Reuse the screen built during validation in _handleAppResumed if

        // available, to avoid a second async I/O call (which caused a black frame).

        final dailyQuiz =
            _cachedDailyQuizResumeScreen ?? await _buildDailyQuizResumeScreen();

        _cachedDailyQuizResumeScreen = null; // consume the cache

        if (dailyQuiz == null) {
          await _routeResumeFallback(reason: 'no_valid_resume_target');

          return;
        }

        navigator.push(MaterialPageRoute(builder: (_) => dailyQuiz));

        _logDiagnosticOnce(
          'route_resume_result',

          'route_resume=success target=daily_quiz',
        );

        return;
      }

      if (state.lessonId == 'daily_speaking' ||
          state.type == 'daily_speaking') {
        final dailySpeaking = await _buildDailySpeakingResumeScreen();

        if (dailySpeaking == null) {
          await _routeResumeFallback(reason: 'no_valid_resume_target');

          return;
        }

        navigator.push(MaterialPageRoute(builder: (_) => dailySpeaking));

        _logDiagnosticOnce(
          'route_resume_result',

          'route_resume=success target=daily_speaking',
        );

        return;
      }

      final lessonScreen = _buildLessonResumeScreen(state);

      if (lessonScreen == null) {
        await _routeResumeFallback(reason: 'no_valid_resume_target');

        return;
      }

      navigator.push(MaterialPageRoute(builder: (_) => lessonScreen));

      _logDiagnosticOnce(
        'route_resume_result',

        'route_resume=success target=${state.lessonId}:${state.type}',
      );
    } catch (e) {
      debugPrint('Recovery: failed to push resumed route: $e');

      await _routeResumeFallback(reason: 'resume_push_failed');
    }
  }

  Widget? _buildLessonResumeScreen(ActiveRouteState state) {
    final isQuiz = state.type == 'quiz';

    final storyIndex = isQuiz ? 0 : state.index;

    final quizIndex = isQuiz ? state.index : 0;

    switch (state.lessonId) {
      case 'lesson_1_subjects':
        return const LessonSubjectsScreen();

      case 'lesson_2_parts_of_speech':
        return const LessonPartsOfSpeechScreen();

      case 'lesson_2_articles':
        return const LessonArticlesScreen();

      case 'lesson_5_future_continuous':
        return const LessonFutureContinuousScreen();

      case 'lesson_direct_indirect':
        return const LessonDirectIndirectSpeechScreen();

      case 'lesson_prepositions':
        return LessonPrepositionsScreen(
          initialStoryIndex: storyIndex,

          initialQuizIndex: quizIndex,

          initialMode: state.type,
        );
    }

    return null;
  }

  Future<DailyQuizScreen?> _buildDailyQuizResumeScreen() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString('daily_quiz_state_v1');

    if (raw == null || raw.isEmpty) return null;

    Map<String, dynamic> decoded;

    try {
      final data = jsonDecode(raw);

      if (data is! Map<String, dynamic>) return null;

      decoded = data;
    } catch (_) {
      return null;
    }

    final preferredLanguage =
        decoded['preferredLanguage']?.toString() ??
        prefs.getString('preferred_language') ??
        'Tamil';

    final coveredStagesRaw = decoded['coveredStages'] as List?;

    final coveredStages = <int>[];

    if (coveredStagesRaw != null) {
      for (final entry in coveredStagesRaw) {
        final value = entry is int ? entry : int.tryParse(entry.toString());

        if (value != null) coveredStages.add(value);
      }
    }

    int targetStage = decoded['targetStage'] is int
        ? decoded['targetStage'] as int
        : 0;

    if (coveredStages.isEmpty && targetStage <= 0) {
      final stageService = StageProgressService();

      final currentStage = await stageService.getCurrentStage(prefs: prefs);

      // Level assessments now run on the current level.

      targetStage = currentStage;
    }

    final contentService = StageContentService();

    final vocabList = <Map<String, String>>[];

    final verbList = <Map<String, String>>[];

    if (coveredStages.isNotEmpty) {
      for (final stage in coveredStages) {
        final vocab = await contentService.getVocabularyMapsForStage(
          stage,

          preferredLanguage: preferredLanguage,
        );

        final verbs = await contentService.getVerbMapsForStage(
          stage,

          preferredLanguage: preferredLanguage,
        );

        vocabList.addAll(vocab);

        verbList.addAll(verbs);
      }
    } else if (targetStage > 0) {
      vocabList.addAll(
        await contentService.getVocabularyMapsForStage(
          targetStage,

          preferredLanguage: preferredLanguage,
        ),
      );

      verbList.addAll(
        await contentService.getVerbMapsForStage(
          targetStage,

          preferredLanguage: preferredLanguage,
        ),
      );
    }

    if (vocabList.isEmpty && verbList.isEmpty) {
      return null;
    }

    return DailyQuizScreen(
      vocabList: vocabList,

      verbList: verbList,

      preferredLanguage: preferredLanguage,

      stage: targetStage > 0 ? targetStage : null,

      coveredStages: coveredStages,
    );
  }

  Future<DailySpeakingChallengeScreen?>
  _buildDailySpeakingResumeScreen() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString('daily_speaking_state_v1');

    final ts = prefs.getInt('daily_speaking_state_ts');

    if (raw == null || raw.isEmpty || ts == null) return null;

    final ageMs = DateTime.now().millisecondsSinceEpoch - ts;

    if (ageMs > const Duration(hours: 8).inMilliseconds) {
      return null;
    }

    Map<String, dynamic> decoded;

    try {
      final data = jsonDecode(raw);

      if (data is! Map<String, dynamic>) return null;

      decoded = data;
    } catch (_) {
      return null;
    }

    final wordsRaw = decoded['words'];

    if (wordsRaw is! List) return null;

    final words = <Map<String, String>>[];

    for (final entry in wordsRaw) {
      if (entry is! Map) continue;

      words.add(
        entry.map(
          (key, value) =>
              MapEntry(key.toString(), value?.toString().trim() ?? ''),
        ),
      );
    }

    if (words.isEmpty) return null;

    final preferredLanguage =
        (decoded['preferredLanguage']?.toString().trim().isNotEmpty ?? false)
        ? decoded['preferredLanguage'].toString().trim()
        : (prefs.getString('preferred_language') ?? 'Tamil');

    return DailySpeakingChallengeScreen(
      words: words,

      preferredLanguage: preferredLanguage,

      onCompleted: () {
        unawaited(DailyTaskCompletionService().markPronunciationComplete());
      },
    );
  }

  Future<void> _persistHomeRoute(
    String route, {

    SharedPreferences? prefs,
  }) async {
    final storage = prefs ?? await SharedPreferences.getInstance();

    await storage.setString(_EnglishLearningAppState._lastHomeRouteKey, route);

    await storage.setInt(
      _EnglishLearningAppState._lastHomeRouteTsKey,

      DateTime.now().millisecondsSinceEpoch,
    );

    await _persistSessionSnapshot(
      pendingRecovery:
          storage.getBool(_EnglishLearningAppState._backgroundFlagKey) ?? false,

      routeOverride: route,

      prefs: storage,
    );
  }

  Future<void> _persistSessionSnapshot({
    required bool pendingRecovery,

    int? backgroundAtMillis,

    String? routeOverride,

    SharedPreferences? prefs,
  }) async {
    try {
      final storage = prefs ?? await SharedPreferences.getInstance();

      final route =
          routeOverride ??
          _deriveHomeRouteName(
            isLoggedIn: _effectiveIsLoggedIn,

            role: _effectiveUserRole,

            hasCompletedPlacement: _effectiveHasCompletedPlacement,
          );

      final snapshot = _AppSessionSnapshot(
        isLoggedIn: _effectiveIsLoggedIn,

        role: _effectiveUserRole,

        hasCompletedPlacement: _effectiveHasCompletedPlacement,

        homeRoute: route,

        pendingRecovery: pendingRecovery,

        savedAtMillis: DateTime.now().millisecondsSinceEpoch,

        backgroundAtMillis: backgroundAtMillis,
      );

      await storage.setString(
        _EnglishLearningAppState._sessionSnapshotKey,

        jsonEncode(
          snapshot.toJson(
            version: _EnglishLearningAppState._sessionSnapshotVersion,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Recovery: failed to persist session snapshot: $e');
    }
  }

  _AppSessionSnapshot? _loadSessionSnapshot(SharedPreferences prefs) {
    final raw = prefs.getString(_EnglishLearningAppState._sessionSnapshotKey);

    final parsed = _AppSessionSnapshot.fromRaw(
      raw,

      expectedVersion: _EnglishLearningAppState._sessionSnapshotVersion,
    );

    if (parsed != null) return parsed;

    if (raw != null && raw.isNotEmpty) {
      _logDiagnostic(
        'snapshot_discarded expected_version=${_EnglishLearningAppState._sessionSnapshotVersion} reason=invalid_or_mismatch',
      );

      unawaited(prefs.remove(_EnglishLearningAppState._sessionSnapshotKey));
    }

    return null;
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
