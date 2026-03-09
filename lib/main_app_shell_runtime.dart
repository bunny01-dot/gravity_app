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
