part of 'home_tab.dart';

extension _HomeTabSectionsExtension on _HomeTabState {
  Widget _buildPlacementQuizCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Soft warning tone for skipped users
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assessment_rounded,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Personalize Your Learning",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Take the placement quiz to personalize lessons and practice for your level.",
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                debugPrint("DEBUG: HomeTab Placement Quiz CTA pressed");
                if (widget.onAttendQuiz != null) {
                  widget.onAttendQuiz!();
                } else {
                  debugPrint("DEBUG: HomeTab onAttendQuiz is NULL!");
                }
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                "Take Placement Quiz",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.onPrimary,
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).moveY(begin: 20, end: 0);
  }

  Widget _buildWelcomeCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final welcomeGradient = isDark
        ? const [Color(0xFFFFD700), Color(0xFFFFA500)]
        : const [Color(0xFFEAF3FF), Color(0xFFDDEBFF)];
    final welcomeTitleColor = isDark ? Colors.black87 : const Color(0xFF1E3A8A);
    final welcomeSubtitleColor = isDark
        ? Colors.black54
        : const Color(0xFF35507A);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: welcomeGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFFFFD700) : const Color(0xFF2563EB))
                .withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isNewUser ? "Welcome!" : "Welcome Back!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: welcomeTitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ready to continue your learning journey?",
            style: TextStyle(fontSize: 14, color: welcomeSubtitleColor),
          ),
          if (widget.userRole != 'teacher') ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildStreakBadge(),
                _buildProgressBadge(),
                _buildXpBadge(),
              ],
            ),
            const SizedBox(height: 12),
            _buildProgressBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildStreakBadge() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streakReady = widget.isStreakLoaded;
    final isHotStreak = streakReady && widget.streakCount > 0;
    final badgeGradientColors = isDark
        ? const [Color(0xFF0F0F0F), Color(0xFF1F1F1F)]
        : const [Color(0xFF2563EB), Color(0xFF3B82F6)];
    final badgeBorderColor = isDark ? Colors.white24 : const Color(0xFF93C5FD);
    final badgeShadowColor = isDark
        ? Colors.black.withValues(alpha: 0.42)
        : const Color(0xFF2563EB).withValues(alpha: 0.3);

    return GestureDetector(
      key: _streakBadgeKey, // GlobalKey for tutorial targeting
      onTap: streakReady ? _showStreakCelebration : null,
      child: Tooltip(
        message: 'Streak\nLevels completed in your Learning Plan.',
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151515) : const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                badgeGradientColors[0].withValues(alpha: 0.95),
                badgeGradientColors[1].withValues(alpha: 0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: badgeBorderColor.withValues(alpha: 0.7),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: badgeShadowColor,
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!streakReady)
                const Icon(
                  Icons.hourglass_bottom_rounded,
                  color: Colors.white70,
                  size: 18,
                )
              else
                SizedBox(
                  width: isHotStreak ? 20 : 26,
                  height: isHotStreak ? 20 : 26,
                  child: Lottie.asset(
                    isHotStreak
                        ? 'assets/lottie/Fire.json'
                        : 'assets/lottie/Snowflake loading screen.json',
                    repeat: true,
                    animate: true,
                    fit: BoxFit.contain,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                streakReady ? "${widget.streakCount}" : '--',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showStreakCelebration() async {
    if (!widget.isStreakLoaded) return;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = widget.streakCount > 0
        ? colorScheme.tertiary
        : colorScheme.primary;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: accentColor, width: 1.8),
            boxShadow: [
              BoxShadow(color: accentColor, blurRadius: 24, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.streakCount > 0)
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Lottie.asset(
                    'assets/lottie/Fire.json',
                    repeat: true,
                    animate: true,
                    fit: BoxFit.contain,
                  ),
                )
              else
                Icon(
                  Icons.local_fire_department_outlined,
                  size: 88,
                  color: accentColor,
                ),
              const SizedBox(height: 12),
              Text(
                "${widget.streakCount} Level Streak",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Keep the streak by completing this level's Learning Plan and checkpoint quiz.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.75),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("Got it"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBadge() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final badgeBg = colorScheme.surfaceContainerHighest.withValues(alpha: 0.72);

    return GestureDetector(
      onTap: _showProgressExplanation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              "Course Progress: ${(widget.overallProgress * 100).toInt()}%",
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXpBadge() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final badgeBg = colorScheme.surfaceContainerHighest.withValues(alpha: 0.72);

    return Tooltip(
      message: 'Total XP earned from completed daily tasks.',
      textStyle: TextStyle(color: colorScheme.onInverseSurface, fontSize: 12),
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: 14, color: colorScheme.onSurface),
            const SizedBox(width: 4),
            Text(
              "${_formatXpValue(widget.totalXp)} XP",
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _getQuizProgressSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final stageService = StageProgressService();
    final totalQuizzes = DataService().getCurriculumLessons().length;

    if (totalQuizzes <= 0) {
      return {'passed': 0, 'total': 0};
    }

    int passedQuizzes = 0;
    for (int stage = 1; stage <= totalQuizzes; stage++) {
      final passedKey = stageService.quizPassedKey(stage);
      final scoreKey = stageService.quizScoreKey(stage);
      final totalKey = stageService.quizTotalKey(stage);

      bool isPassed = prefs.getBool(passedKey) ?? false;
      if (!isPassed) {
        final score = prefs.getInt(scoreKey);
        final total = prefs.getInt(totalKey);
        if (score != null &&
            total != null &&
            stageService.isAssessmentPassed(score, total)) {
          isPassed = true;
        }
      }

      if (isPassed) {
        passedQuizzes++;
      }
    }

    if (passedQuizzes > totalQuizzes) {
      passedQuizzes = totalQuizzes;
    }

    return {'passed': passedQuizzes, 'total': totalQuizzes};
  }

  Future<void> _showProgressExplanation() async {
    final quizSummary = await _getQuizProgressSummary();
    if (!mounted) return;

    final quizPassed = quizSummary['passed'] ?? 0;
    final quizTotal = quizSummary['total'] ?? 0;
    final totalLessons = DataService().getCurriculumLessons().length;

    await showCourseProgressDialog(
      context: context,
      overallProgress: widget.overallProgress,
      completedLessons: (widget.overallProgress * totalLessons).toInt(),
      totalLessons: totalLessons,
      quizPassed: quizPassed,
      quizTotal: quizTotal,
    );
  }

  Widget _buildProgressBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        FractionallySizedBox(
          widthFactor: widget.overallProgress.clamp(0.01, 1.0),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
