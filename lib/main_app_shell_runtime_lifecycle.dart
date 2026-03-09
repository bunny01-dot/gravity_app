// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'main.dart';

extension MainAppShellRuntimeLifecycle on _EnglishLearningAppState {
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
}
