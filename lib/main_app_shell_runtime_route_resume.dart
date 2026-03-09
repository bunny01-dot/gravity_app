// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'main.dart';

extension MainAppShellRuntimeRouteResume on _EnglishLearningAppState {
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
}
