// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'dashboard_screen.dart';

extension DashboardTutorial on _DashboardScreenState {
  Future<void> _showTutorialIfNeeded() async {
    try {
      // Check if should show onboarding
      final shouldShow = await TutorialService().shouldShowOnboarding();
      if (shouldShow && mounted) {
        // Delay to let dashboard render first
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const OnboardingScreen(),
          );
        }
      }
    } catch (e) {
      debugPrint("Error showing tutorial: $e");
    }
  }

  Future<void> _showMasteryIntroIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('mastery_intro_seen') ?? false;

    // ISSUE #2 FIX: Check mutual exclusion
    if (seen || TutorialHelper.isShowingTutorial) return;

    if (mounted) {
      // Mark notice as active to block tutorials/notices
      _isNoticeActive = true;
      TutorialService().startTutorial();
      AnalyticsService().logEvent('mastery_intro_shown');

      try {
        await showModernDialog(
          context,
          title: "Mastery Lessons",
          message:
              "These are optional lessons.\nThey may include new words and harder exercises.\n\nYour Learning Plan is enough for steady progress.",
          primaryButtonText: "Continue to Lessons",
          onPrimaryPressed: () =>
              Navigator.of(context, rootNavigator: true).maybePop(),
          secondaryButtonText: "Go to Learning Plan",
          onSecondaryPressed: () {
            Navigator.of(context, rootNavigator: true).maybePop();
            if (mounted) {
              _setDashboardTabIndex(1, animate: true);
            }
          },
          icon: Icons.info_outline_rounded,
          accentColor: Colors.orangeAccent,
          barrierDismissible: false,
        );
      } finally {
        // Release lock
        _isNoticeActive = false;
        TutorialService().endTutorial();
      }

      await prefs.setBool('mastery_intro_seen', true);

      // Retry tutorial after dialog closes (small delay)
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _showMasteryTutorialIfNeeded();
        });
      }
    }
  }

  // Soft recommendation hint for Mastery page
  Future<bool> _shouldShowMasteryRecommendationHint() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('mastery_recommendation_seen') ?? false;

    if (seen) return false; // Already seen, never show again

    final stage = await _stageService.getCurrentStage(prefs: prefs);
    final completedStages = stage > 1 ? stage - 1 : 0;

    // Show hint only if less than 3 stages completed
    if (completedStages < 3) {
      // Mark as seen and log analytics
      await prefs.setBool('mastery_recommendation_seen', true);
      AnalyticsService().logEvent('mastery_recommendation_hint_shown');
      return true;
    }

    // Auto-dismiss: â‰¥ 3 days completed
    return false;
  }

  Widget _buildRecommendationHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommended after a few days of daily learning',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'These lessons are optional and meant for extra practice.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // Tutorial #2: Core Tasks - Show checklist explanation
  Future<void> _showDailyTasksTutorialIfNeeded() async {
    if (!mounted || _userRole != 'student') return;
    if (_currentIndex != 1) return;
    if (_isPlacementLocked || _isPlacementStateLoading) return;

    final tasksCompleted =
        _isVocabDone && _isVerbsDone && _isSpeakingDone && _isQuizDone;
    final shouldShow = await TutorialService().shouldShowDailyTasksTutorial(
      tasksCompleted,
    );

    if (shouldShow && mounted && !TutorialHelper.isShowingTutorial) {
      // Wait for first frame to render
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted || _currentIndex != 1) return;
        if (_isPlacementLocked || _isPlacementStateLoading) return;

        TutorialHelper.showTutorial(
          context: context,
          targetKey: _dailyChecklistKey,
          title: "Today's Learning Plan",
          message:
              "Start with this checklist. Complete Vocab, Verbs, Speaking, and Quiz to keep your streak and XP moving.",
          accentColor: const Color(0xFF4FACFE),
          alignment: Alignment.center,
          highlightShape: CoachMarkHighlightShape.roundedRect,
          highlightPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          onDismiss: () {
            unawaited(TutorialService().markDailyTasksTutorialSeen());
          },
        );
      });
    }
  }

  // Tutorial #4: Mastery - Show that it's optional
  Future<void> _showMasteryTutorialIfNeeded() async {
    if (!mounted) return;
    if (!_isMasteryFeatureEnabled || _userRole != 'student') return;
    if (_currentIndex != 2) return;

    // ISSUE #2 FIX: Check mutual exclusion
    if (_isNoticeActive) return;

    final shouldShow = await TutorialService().shouldShowMasteryTutorial();

    if (shouldShow && mounted && !TutorialHelper.isShowingTutorial) {
      // Wait for first frame to render
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted || _isNoticeActive) return;

        TutorialHelper.showTutorial(
          context: context,
          targetKey: _masteryCardKey,
          title: "Optional Practice",
          message:
              "Mastery lessons are optional. Use them anytime to practice harder skills.",
          accentColor: const Color(0xFFFE5196),
          alignment: Alignment.center,
          highlightShape: CoachMarkHighlightShape.roundedRect,
          highlightPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          onDismiss: () {
            unawaited(TutorialService().markMasteryTutorialSeen());
          },
        );
      });
    }
  }
}
