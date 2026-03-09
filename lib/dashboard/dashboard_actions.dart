// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously
part of 'dashboard_screen.dart';

extension DashboardActions on _DashboardScreenState {
  void _syncTabPageController(int index, {bool animate = true}) {
    Future<void> move() async {
      if (!mounted || !_tabPageController.hasClients) return;
      final currentPage = _tabPageController.page?.round();
      if (currentPage == index) return;
      if (animate) {
        await _tabPageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      } else {
        _tabPageController.jumpToPage(index);
      }
    }

    if (_tabPageController.hasClients) {
      unawaited(move());
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(move());
    });
  }

  void _handleTabSideEffects(int index) {
    final settingsTabIndex = _userRole == 'teacher'
        ? 3
        : (_isMasteryFeatureEnabled ? 3 : 2);

    if (index == settingsTabIndex) {
      AnalyticsService().logEvent('settings_opened');
    }

    // ISSUE #1 FIX: Immediate refresh when returning to home
    if (index == 0) {
      _checkDailyProgress(); // Force instant update
    }

    // Tutorial #2: Daily Tasks tab
    if (_userRole == 'student' && index == 1) {
      if (!_isPlacementLocked) {
        _startProgressPolling();
        _showDailyTasksTutorialIfNeeded(); // Show tutorial on first visit
      } else {
        _stopProgressPolling();
      }
    } else {
      _stopProgressPolling();
    }
  }

  void _setDashboardTabIndex(int index, {bool animate = true}) {
    final showMastery = _isMasteryFeatureEnabled && _userRole == 'student';
    final maxIndex = _maxTabIndexForCurrentRole(showMastery);
    final nextIndex = index.clamp(0, maxIndex);

    if (nextIndex == _currentIndex) {
      _syncTabPageController(nextIndex, animate: false);
      return;
    }

    setState(() => _currentIndex = nextIndex);
    _handleTabSideEffects(nextIndex);
    _syncTabPageController(nextIndex, animate: animate);
  }

  void _handleTabPageChanged(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _handleTabSideEffects(index);
  }

  bool _isStageTaskBundleCompleted(SharedPreferences prefs, int stage) {
    if (stage <= 0) return false;
    final hasVocab = prefs.getBool(_stageService.vocabTaskKey(stage)) ?? false;
    final hasVerbs = prefs.getBool(_stageService.verbsTaskKey(stage)) ?? false;
    final hasSpeaking =
        prefs.getBool(_stageService.speakingTaskKey(stage)) ?? false;
    return hasVocab && hasVerbs && hasSpeaking;
  }

  bool _isStageAssessmentCompleted(SharedPreferences prefs, int stage) {
    if (stage <= 0) return false;
    return (prefs.getBool(_stageService.assessmentCompletedKey(stage)) ??
            false) ||
        (prefs.getBool(_stageService.quizPassedKey(stage)) ?? false);
  }

  int _resolveAssessmentStageForLaunch({
    required SharedPreferences prefs,
    required int currentStage,
  }) {
    if (_isStageTaskBundleCompleted(prefs, currentStage) &&
        !_isStageAssessmentCompleted(prefs, currentStage)) {
      return currentStage;
    }

    final previousStage = _stageService.previousStage(currentStage);
    if (_isStageTaskBundleCompleted(prefs, previousStage) &&
        !_isStageAssessmentCompleted(prefs, previousStage)) {
      return previousStage;
    }

    return currentStage;
  }

  void _attendQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlacementQuizScreen()),
    ).then((_) {
      _checkDailyProgress();
      _fetchPlacementState();
      _fetchAssessmentStatus();
    });
  }

  Future<void> _handlePopInvokedWithResult(bool didPop, dynamic result) async {
    if (didPop) return;
    final colorScheme = Theme.of(context).colorScheme;

    // If not on dashboard (index 0), navigate back to dashboard
    if (_currentIndex != 0) {
      _setDashboardTabIndex(0, animate: false);
      return;
    }

    // On dashboard - check for double back press
    final now = DateTime.now();
    final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
        _lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2);

    if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
      _lastBackPressed = now;

      // Show message to press again
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.onPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Press back again to exit',
                  style: TextStyle(color: colorScheme.onPrimary),
                ),
              ),
            ],
          ),
          backgroundColor: colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Close the app correctly
    SystemNavigator.pop();
  }

  void _handleBottomNavTap(int index) {
    _setDashboardTabIndex(index, animate: true);
  }

  void _handleGoToDailyTasksTab() {
    _setDashboardTabIndex(1, animate: true);
    if (!_isPlacementLocked && !_isPlacementStateLoading) {
      _startProgressPolling();
      unawaited(_showDailyTasksTutorialIfNeeded());
    }
  }

  bool _wasTaskCompletionSuccessful(dynamic result) {
    if (result == true) return true;
    if (result is Map) {
      return result['completed'] == true;
    }
    return false;
  }

  int _extractAwardedXp(dynamic result) {
    if (result is! Map) return 0;
    final dynamic raw = result['xpAwarded'];
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    return 0;
  }

  void _handleRecentActivityCompleted() {
    SoundService().playCompletion();
    _confettiController.play();
  }

  void _handleLanguageChanged(String language) {
    if (!mounted) return;
    setState(() {
      _preferredLanguage = language;
    });
  }

  void _handleReadingMasteryTap() {
    if (!_isMasteryFeatureEnabled) return;
    if (_isPlacementLocked) {
      _showMasteryLockedNotice();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReadingScreen()),
    ).then((_) => _fetchMasteryProgress());
  }

  void _handleWritingMasteryTap() {
    if (!_isMasteryFeatureEnabled) return;
    if (_isPlacementLocked) {
      _showMasteryLockedNotice();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WritingScreen()),
    ).then((_) => _fetchMasteryProgress());
  }

  void _handleSpeakingMasteryTap() {
    if (!_isMasteryFeatureEnabled) return;
    if (_isPlacementLocked) {
      _showMasteryLockedNotice();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SpeakingPracticeScreen()),
    ).then((_) => _fetchMasteryProgress());
  }

  void _handleListeningMasteryTap() {
    if (!_isMasteryFeatureEnabled) return;
    if (_isPlacementLocked) {
      _showMasteryLockedNotice();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ListeningScreen()),
    ).then((_) => _fetchMasteryProgress());
  }

  void _showMasteryLockedNotice() {
    showModernDialog(
      context,
      title: "Mastery practice needs personalization",
      message:
          "Complete the placement quiz to begin focused practice at your level.",
      primaryButtonText: "Got it",
      onPrimaryPressed: () => Navigator.pop(context),
      icon: Icons.lock_rounded,
      accentColor: const Color(0xFFFE5196),
    );
  }

  void _handleAppBarBlackHoleTap() {
    if (_highlightBlackHoleFeature || TutorialHelper.isShowingTutorial) {
      TutorialHelper.dismissCurrentTutorial();
      if (mounted) {
        setState(() {
          _highlightBlackHoleFeature = false;
        });
      }
      unawaited(
        FeatureHighlightService().markSeen(
          featureId: _DashboardScreenState._blackHoleFeatureHighlightId,
          version: 1,
        ),
      );
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BlackHoleScreen()),
    );
  }

  void _handleNotificationsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _userRole == 'teacher'
            ? const TeacherNotificationsScreen()
            : const NotificationsScreen(),
      ),
    ).then((_) => _loadPreferences()); // Refresh badges
  }

  void _handleProfileTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    ).then((_) {
      // Reload preferences to update avatar/name immediately
      _loadPreferences();
    });
  }

  Future<void> _deleteAnnouncement(String id) async {
    // ISSUE #2 FIX: Add proper error handling and ensure state always resolves
    try {
      await _notificationService.deleteNotification(id);
      final deletedIds = await _notificationService.getDeletedIds();
      if (mounted) {
        setState(() {
          _deletedIds = deletedIds;
          _announcementFiltersReady = true;
        });
      }
    } catch (e) {
      debugPrint("Error deleting announcement: $e");
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to delete: $e",
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
            backgroundColor: colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleSyncFromSheet() async {
    // 1. Get Saved URL
    final prefs = await SharedPreferences.getInstance();
    String currentUrl = prefs.getString('google_sheet_url') ?? '';

    // 2. Show Input Dialog
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    TextEditingController controller = TextEditingController(text: currentUrl);
    final newUrl = await showModernDialog<String>(
      context,
      title: "Google Sheet CSV Link",
      message: "Enter the 'Published to Web' CSV link of your Google Sheet.",
      content: TextField(
        controller: controller,
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: "https://docs.google.com/.../pub?output=csv",
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      primaryButtonText: "Sync Now",
      onPrimaryPressed: () => Navigator.pop(context, controller.text.trim()),
      secondaryButtonText: "Cancel",
      onSecondaryPressed: () => Navigator.pop(context),
      icon: Icons.link_rounded,
      accentColor: colorScheme.primary,
    );

    if (newUrl == null || newUrl.isEmpty) return;

    // 3. Save URL
    await prefs.setString('google_sheet_url', newUrl);

    // 4. Show Loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (c) => const RefreshLottieLoader(
        message: "Syncing data...",
        subtitle: "Applying latest Google Sheet updates",
      ),
    );

    // 5. Call DataService
    final success = await data_service.DataService().adminSyncFromUrlToCloud(
      newUrl,
    );

    if (mounted) {
      Navigator.pop(context); // Close loading

      if (success) {
        final scheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Cloud synced successfully from Google Sheet!",
              style: TextStyle(color: scheme.onPrimaryContainer),
            ),
            backgroundColor: scheme.primaryContainer,
          ),
        );
      } else {
        final scheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Sync failed. Check the URL and try again.",
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            backgroundColor: scheme.errorContainer,
          ),
        );
      }
    }
  }

  Future<void> _handleRefreshData() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (c) => const RefreshLottieLoader(
        message: "Refreshing dashboard...",
        subtitle: "Updating your latest data",
      ),
    );

    try {
      // Force refresh in DataService
      await data_service.DataService().forceRefreshData();

      // Wait a bit for effect
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        Navigator.pop(context); // Close loading
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Data cache cleared and reloaded successfully!",
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
            backgroundColor: colorScheme.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error refreshing data: $e",
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
            backgroundColor: colorScheme.errorContainer,
          ),
        );
      }
    }
  }

  Future<void> _handleAssessmentTap() async {
    final prefs = await SharedPreferences.getInstance();
    final currentStage = await _stageService.getCurrentStage(prefs: prefs);
    final reviewStage = _resolveAssessmentStageForLaunch(
      prefs: prefs,
      currentStage: currentStage,
    );
    final hasVocab =
        prefs.getBool(_stageService.vocabTaskKey(reviewStage)) ?? false;
    final hasVerbs =
        prefs.getBool(_stageService.verbsTaskKey(reviewStage)) ?? false;
    final hasSpeaking =
        prefs.getBool(_stageService.speakingTaskKey(reviewStage)) ?? false;

    if (!hasVocab || !hasVerbs || !hasSpeaking) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        showModernDialog(
          context,
          title: "Finish Level $reviewStage Plan",
          message:
              "Complete Level $reviewStage vocabulary, verb practice, and speaking practice before opening the assessment.",
          primaryButtonText: "I Understand",
          onPrimaryPressed: () => Navigator.pop(context),
          icon: Icons.hourglass_empty_rounded,
          accentColor: colorScheme.error,
        );
      }
      return;
    }

    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DailyReviewScreen(stage: reviewStage)),
    );
    // Force immediate refresh with small delay to ensure SharedPreferences is flushed
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await _checkDailyProgress(); // Refresh upon return
    if (!mounted) return;
    setState(() {}); // Force UI rebuild
    if (result is Map && result['nextLevelUnlocked'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Next level unlocked!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool> _ensureAssessmentGateForCurrentStage() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = await _stageService.getCurrentStage(prefs: prefs);
    final previousStage = _stageService.previousStage(stage);

    if (previousStage <= 0) return true;

    final completed = _isStageAssessmentCompleted(prefs, previousStage);
    if (completed) return true;

    if (mounted) {
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please complete the Level $previousStage review to confirm your learning.",
            style: TextStyle(color: colorScheme.onErrorContainer),
          ),
          backgroundColor: colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return false;
  }

  Future<void> _handleGamesUnlockedTap() async {
    SoundService().playTap();
    AnalyticsService().logEvent('daily_tasks_to_games_clicked');
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const GamesGridSheet(),
    );

    // ISSUE #5 FIX: Handle navigation request from LockedGamesView
    if (result == 'go_to_daily_tasks' && mounted) {
      // Close any lingering modals
      Navigator.of(
        context,
        rootNavigator: false,
      ).popUntil((route) => route.isFirst);
      // Switch to Daily Tasks tab (index 1)
      _setDashboardTabIndex(1, animate: true);
    }
  }

  // FIX: Daily Vocabulary Handler - Navigate to Full Page
  Future<void> _handleVocabularyTap() async {
    if (!await _ensureAssessmentGateForCurrentStage()) return;
    SoundService().playTap();
    AnalyticsService().logEvent('daily_vocabulary_tapped');

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const RefreshLottieLoader(
        message: "Loading vocabulary...",
        subtitle: "Preparing your daily words",
      ),
    );

    try {
      final stage = await _stageService.getCurrentStage();
      final contentService = StageContentService();
      final vocabItems = await contentService.getVocabularyForStage(stage);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (vocabItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No vocabulary available for this stage.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Navigate to list screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DailyVocabularyListScreen(
            vocabulary: vocabItems,
            preferredLanguage: _preferredLanguage,
            stageNumber: stage,
          ),
        ),
      );

      // Refresh UI on return if completed
      final completed = _wasTaskCompletionSuccessful(result);
      final xpAwarded = _extractAwardedXp(result);
      if (completed && mounted) {
        if (xpAwarded > 0) {
          _showXpBurstAnimation(xpAwarded);
        }
        await _checkDailyProgress();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context); // Close loading
        debugPrint('Error loading vocabulary: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading vocabulary: $e')));
      }
    }
  }

  // FIX: Daily Verbs Handler - Navigate to Full Page
  Future<void> _handleVerbsTap() async {
    if (!await _ensureAssessmentGateForCurrentStage()) return;
    SoundService().playTap();
    AnalyticsService().logEvent('daily_verbs_tapped');

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const RefreshLottieLoader(
        message: "Loading verbs...",
        subtitle: "Preparing your daily verb set",
      ),
    );

    try {
      final stage = await _stageService.getCurrentStage();
      final contentService = StageContentService();
      final verbItems = await contentService.getVerbsForStage(stage);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (verbItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No verb forms available for this stage.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Navigate to list screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DailyVerbsListScreen(
            verbs: verbItems,
            preferredLanguage: _preferredLanguage,
            stageNumber: stage,
          ),
        ),
      );

      // Refresh UI on return if completed
      final completed = _wasTaskCompletionSuccessful(result);
      final xpAwarded = _extractAwardedXp(result);
      if (completed && mounted) {
        if (xpAwarded > 0) {
          _showXpBurstAnimation(xpAwarded);
        }
        await _checkDailyProgress();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context); // Close loading
        debugPrint('Error loading verbs: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading verbs: $e')));
      }
    }
  }

  Future<void> _handleDailyPronunciation() async {
    if (!await _ensureAssessmentGateForCurrentStage()) return;
    // 1. Check if already done
    // 1. Check if already done - ALLOW RE-OPENING
    if (_isSpeakingDone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You already completed this stage task. You can still practice again.",
          ),
          duration: Duration(seconds: 2),
        ),
      );
      // Removed return to allow re-opening
    }

    const targetSentenceCount = 5;

    // 2. Load a full daily pronunciation set.
    bool isLoading = true;
    BuildContext? loaderDialogContext;
    Future<void> closeLoaderIfVisible() async {
      if (!isLoading) return;
      isLoading = false;
      final dialogContext = loaderDialogContext;
      if (dialogContext == null) return;
      final navigator = Navigator.of(dialogContext, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        loaderDialogContext = dialogContext;
        return const RefreshLottieLoader(
          message: "Loading speaking task...",
          subtitle: "Picking today's pronunciation set",
        );
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 16));

    try {
      final stage = await _stageService.getCurrentStage();
      final items = await _buildDailyPronunciationItems(
        stage: stage,
        targetCount: targetSentenceCount,
      );

      await closeLoaderIfVisible();

      if (items.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No pronunciation sentences available for this stage.",
              ),
            ),
          );
        }
        return;
      }

      if (items.length < targetSentenceCount && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Only ${items.length} pronunciation sentences available now.",
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (context.mounted) {
        _showDailySpeakingLoop(context, items);
      }
    } catch (e) {
      await closeLoaderIfVisible();
      debugPrint("Error loading daily speaking: $e");
    }
  }

  void _showDailySpeakingLoop(
    BuildContext context,
    List<Map<String, String>> items,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailySpeakingChallengeScreen(
          words: items,
          preferredLanguage: _preferredLanguage,
          onCompleted: () async {
            final stage = await _stageService.getCurrentStage();
            await _markTaskDone(
              _stageService.speakingTaskKey(stage),
              "Speaking Practice",
            );
            final xpResult = await DailyTaskCompletionService()
                .awardPronunciationXpIfNeeded(stage: stage);
            if (xpResult.xpAwarded > 0) {
              _showXpBurstAnimation(xpResult.xpAwarded);
            }
            await _checkDailyProgress(); // Refresh Dashboard UI
            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  Future<List<Map<String, String>>> _buildDailyPronunciationItems({
    required int stage,
    required int targetCount,
  }) async {
    final contentService = StageContentService();
    final collected = <Map<String, String>>[];
    final seenKeys = <String>{};

    void addItems(List<Map<String, String>> source) {
      for (final item in source) {
        if (collected.length >= targetCount) break;
        final word = (item['word'] ?? '').trim();
        final rawExample = (item['english_example'] ?? '').trim();
        if (word.isEmpty && rawExample.isEmpty) continue;

        final example = rawExample.isNotEmpty ? rawExample : word;
        final id = (item['id'] ?? '').trim();
        final dedupeKey = id.isNotEmpty
            ? id
            : "${word.toLowerCase()}|${example.toLowerCase()}";
        if (!seenKeys.add(dedupeKey)) continue;

        collected.add({
          'id': id.isNotEmpty ? id : dedupeKey,
          'word': word.isNotEmpty ? word : example,
          'english_example': example,
          'tamil_meaning': item['tamil_meaning'] ?? '',
          'hindi_meaning': item['hindi_meaning'] ?? '',
          'meaning': item['meaning'] ?? '',
        });
      }
    }

    // Primary source: current stage vocabulary.
    addItems(
      await contentService.getVocabularyMapsForStage(
        stage,
        preferredLanguage: _preferredLanguage,
      ),
    );

    // Fallback source: nearby stages until we reach targetCount.
    int offset = 1;
    const maxStageProbe = 30;
    while (collected.length < targetCount && offset <= maxStageProbe) {
      final extra = await contentService.getVocabularyMapsForStage(
        stage + offset,
        preferredLanguage: _preferredLanguage,
      );
      addItems(extra);
      offset++;
    }

    // Hard guarantee: keep challenge length consistent with the UI target.
    if (collected.isNotEmpty && collected.length < targetCount) {
      final seed = List<Map<String, String>>.from(collected);
      int repeatIndex = 0;
      while (collected.length < targetCount) {
        final base = seed[repeatIndex % seed.length];
        final clone = Map<String, String>.from(base);
        clone['id'] =
            "${base['id'] ?? base['word'] ?? 'pronunciation'}_repeat_${collected.length}";
        collected.add(clone);
        repeatIndex++;
      }
    }

    return collected.take(targetCount).toList();
  }

  // Black Hole Tutorial & Navigation
  Future<void> _handleBlackHoleTap() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('black_hole_tutorial_seen') ?? false;

    if (!hasSeenTutorial && mounted) {
      // Show contextual chat-style tutorial
      await showDialog(
        context: context,
        barrierColor: Colors.transparent,
        barrierDismissible: true,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child:
              Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFA18CD1).withValues(alpha: 0.95),
                          const Color(0xFF8E73C7).withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA18CD1).withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const BlackholeIcon(
                                size: 24,
                                color: Colors.white,
                                showGlow: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Black Hole',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ' What is this?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'This is your personal collection of challenging words!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                ' How it works:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                r'| Mark words you find difficult during lessons'
                                '\n'
                                r'| They automatically appear here'
                                '\n'
                                r'| Review and master them at your own pace'
                                '\n'
                                r'| Only uses words you'
                                "'"
                                r've already learned',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFA18CD1),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Got it!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
        ),
      );

      // Mark as seen
      await prefs.setBool('black_hole_tutorial_seen', true);
    }

    // Navigate to Black Hole screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BlackHoleScreen()),
      ).then((_) {
        if (_isMasteryFeatureEnabled) {
          _fetchMasteryProgress();
        }
      });
    }
  }

  Future<void> _handleLogout() async {
    // ISSUE #7 FIX: Set flag to suppress ALL popups during logout
    setState(() {
      _isLoggingOut = true;
    });

    final confirm = await showModernDialog<bool>(
      context,
      title: "Logout",
      message: "Are you sure you want to logout?",
      primaryButtonText: "Logout",
      onPrimaryPressed: () => Navigator.pop(context, true),
      secondaryButtonText: "Cancel",
      onSecondaryPressed: () => Navigator.pop(context, false),
      icon: Icons.logout_rounded,
      accentColor: Colors.orangeAccent,
    );

    if (confirm != true) {
      // User cancelled, reset flag
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
      return;
    }

    try {
      await import_firebase_auth.FirebaseAuth.instance.signOut();

      // Clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        // Navigate to landing screen (single app instance)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LandingScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Error logging out: $e");
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error logging out: $e",
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
            backgroundColor: colorScheme.errorContainer,
          ),
        );
      }
    }
  }

  Future<void> _markAnnouncementRead(String id) async {
    try {
      await _notificationService.markAsRead(id);
      final readIds = await _notificationService.getReadIds();
      if (mounted) {
        setState(() {
          _readIds = readIds;
          _announcementFiltersReady = true;
        });
      }
    } catch (e) {
      debugPrint("Error marking announcement read: $e");
    }
  }
}
