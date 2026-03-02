// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'dashboard_screen.dart';

extension DashboardTasks on _DashboardScreenState {
  Widget _buildTeacherLibraryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardSectionHeader(title: "Library Management"),
          const Text(
            "Manage app content and datasets from here.",
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 24),

          // Action 1: Refresh Data
          DashboardCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DashboardLibraryActionHeader(
                  icon: Icons.sync_rounded,
                  color: Colors.orangeAccent,
                  title: "Refresh Content",
                  subtitle:
                      "Reload vocabulary, verbs, and quiz data from source files.",
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _handleRefreshData,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Refresh All Data"),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action 2: Sync from Google Sheet
          DashboardCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DashboardLibraryActionHeader(
                  icon: Icons.link_rounded,
                  color: Colors.greenAccent,
                  title: "Link Google Sheet",
                  subtitle:
                      "Sync quiz data directly from a published Google Sheet CSV link.",
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _handleSyncFromSheet,
                    icon: const Icon(Icons.link),
                    label: const Text("Sync from Web"),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black, // Dark text on green
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const DashboardSectionHeader(title: "Current Assets"),
          const Text(
            "Assets are served from device storage if available (via Cloud Sync), or fallback to bundled assets.",
            style: TextStyle(
              color: Colors.white38,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // --- Dashboard Logic ---

  // --- Core Tasks Logic ---

  Widget _buildPlacementLockedPage({
    required String title,
    required String message,
    IconData icon = Icons.lock_rounded,
    Color accentColor = const Color(0xFF4FACFE),
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accentColor.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyTasksTab() {
    if (_isPlacementStateLoading) {
      return const RefreshLottieLoader(
        message: "Loading daily tasks...",
        subtitle: "Checking your stage and progress",
      );
    }
    if (_isPlacementLocked) {
      return _buildPlacementLockedPage(
        title: "Learning Plan unlocks after the placement quiz",
        message:
            "This helps us assign lessons and practice that fit your level.",
        icon: Icons.lock_clock_rounded,
        accentColor: const Color(0xFF4FACFE),
      );
    }

    return SingleChildScrollView(
      key: ValueKey('daily_tasks_tab_$_currentIndex'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Daily Checklist (Leveler)
          _buildDailyChecklist(),

          if (_isVocabDone && _isVerbsDone) ...[
            const SizedBox(height: 24),
            _buildGamesUnlockedCTA(),
          ],

          const SizedBox(height: 24),

          DashboardDailyTasksSection(
            sectionHeader: const DashboardSectionHeader(
              title: "Learning Activities",
            ),
            savedDailyWordCount: _savedDailyWordCount,
            isQuizDone: _isQuizDone,
            isVocabDone: _isVocabDone,
            isVerbsDone: _isVerbsDone,
            isSpeakingDone: _isSpeakingDone,
            quizScore: _quizScore,
            vocabScore: _vocabScore,
            verbsScore: _verbsScore,
            speakingScore: _speakingScore,
            onAssessmentTap: _handleAssessmentTap,
            onVocabularyTap: _handleVocabularyTap,
            onVerbsTap: _handleVerbsTap,
            onSpeakingTap: _handleDailyPronunciation,
          ),

          const SizedBox(height: 12),

          DashboardRecentActivitySection(
            preferredLanguage: _preferredLanguage,
            onCompleted: _handleRecentActivityCompleted,
          ),
        ],
      ),
    );
  }

  Future<void> _checkDailyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = await _stageService.getCurrentStage(prefs: prefs);

    // Read values
    final bool vocabDone =
        prefs.getBool(_stageService.vocabTaskKey(stage)) ?? false;
    final bool verbsDone =
        prefs.getBool(_stageService.verbsTaskKey(stage)) ?? false;
    final bool speakingDone =
        prefs.getBool(_stageService.speakingTaskKey(stage)) ?? false;
    final bool quizDone =
        (prefs.getBool(_stageService.assessmentCompletedKey(stage)) ?? false) ||
        (prefs.getBool(_stageService.quizPassedKey(stage)) ?? false);

    final int vocabScore =
        prefs.getInt(_stageService.vocabScoreKey(stage)) ?? 0;
    final int verbsScore =
        prefs.getInt(_stageService.verbsScoreKey(stage)) ?? 0;
    final int speakingScore =
        prefs.getInt(_stageService.speakingScoreKey(stage)) ?? 0;
    final int totalXp = prefs.getInt('user_total_xp') ?? 0;
    final int xpLevel =
        prefs.getInt('user_xp_level') ?? prefs.getInt('user_level') ?? 1;
    final int currentXp = prefs.getInt('user_current_xp') ?? 0;
    final int requiredXp = XpRewardPolicy.requiredXpForLevel(xpLevel);

    int quizPercent = 0;
    if (quizDone) {
      final int score = prefs.getInt(_stageService.quizScoreKey(stage)) ?? 0;
      final int total = prefs.getInt(_stageService.quizTotalKey(stage)) ?? 1;
      if (total > 0) {
        quizPercent = ((score / total) * 100).round();
      }
    }

    debugPrint(
      "DailyProgress Check (Level $stage): Vocab=$vocabDone, Verbs=$verbsDone, Speaking=$speakingDone, Assessment=$quizDone ($quizPercent%)",
    );

    final bool vocabJustCompleted = vocabDone && !_isVocabDone;
    final bool verbsJustCompleted = verbsDone && !_isVerbsDone;

    final bool shouldCelebrate =
        _hasLoadedDailyProgress && (vocabJustCompleted || verbsJustCompleted);

    if (shouldCelebrate) {
      SoundService().playCompletion();
      _confettiController.play();
    }

    final bool wasAllDone = _isVocabDone && _isVerbsDone && _isSpeakingDone;
    final bool isAllDone = vocabDone && verbsDone && speakingDone;

    if (isAllDone && !wasAllDone) {
      AnalyticsService().logEvent('daily_tasks_completed');
    }

    if (mounted) {
      setState(() {
        _isVocabDone = vocabDone;
        _isVerbsDone = verbsDone;
        _isSpeakingDone = speakingDone;
        _isQuizDone = quizDone;

        _vocabScore = vocabScore;
        _verbsScore = verbsScore;
        _speakingScore = speakingScore;
        _quizScore = quizPercent;
        _totalXp = totalXp;
        _xpLevel = xpLevel;
        _currentXp = currentXp;
        _requiredXp = requiredXp;
      });
    }

    final bool shouldNotifyAssessmentReady =
        _hasLoadedDailyProgress && isAllDone && !wasAllDone && !quizDone;
    if (shouldNotifyAssessmentReady) {
      _showAssessmentReadySnackBar();
      unawaited(_notifyTeacherDailyBundleComplete(stage: stage));
    }

    _hasLoadedDailyProgress = true;
    await _updateCurrentDayLabel(prefs: prefs);
  }

  void _showAssessmentReadySnackBar() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('You are ready to take the assessment now.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF4FACFE),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _notifyTeacherDailyBundleComplete({required int stage}) async {
    if (_userRole == 'teacher') return;
    if (stage <= 0) return;
    if (_bundleCompletionNotifyInFlight.contains(stage)) return;
    _bundleCompletionNotifyInFlight.add(stage);

    try {
      final prefs = await SharedPreferences.getInstance();
      final notifiedKey = 'teacher_level_completion_notified_stage_$stage';
      final legacyNotifiedKey = 'teacher_daily_bundle_notified_stage_$stage';
      final alreadyNotified =
          (prefs.getBool(notifiedKey) ?? false) ||
          (prefs.getBool(legacyNotifiedKey) ?? false);
      if (alreadyNotified) return;

      final user = import_firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String senderName = (prefs.getString('user_name') ?? '').trim();
      String senderEmail = _userEmail.trim();
      final senderId = user.uid;

      if (senderEmail.isEmpty) {
        senderEmail = user.email ?? '';
      }

      if (senderName.isEmpty || senderName == "Guest User") {
        if (senderEmail.contains('@')) {
          senderName = senderEmail.split('@')[0];
        } else {
          senderName = "Student";
        }
      }

      final taskTitle = 'Level $stage';
      final notificationMessage = 'User $senderName completed level $stage.';

      final notificationPayload = <String, dynamic>{
        'type': 'task_completion',
        'student_email': senderEmail,
        'student_name': senderName,
        'studentName': senderName,
        'studentEmail': senderEmail,
        'task_title': taskTitle,
        'activityType': 'task_completion',
        'activity_type': 'task_completion',
        'details': notificationMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'message': notificationMessage,
        'isRead': false,
        'studentId': senderId,
        'student_id': senderId,
        'senderId': senderId,
      };

      await FirebaseFirestore.instance
          .collection('teacher_notifications')
          .add(notificationPayload);

      await FCMService().sendToTopic(
        topic: 'teachers',
        title: 'Level Completed',
        body: notificationMessage,
        isImportant: true,
      );

      await prefs.setBool(notifiedKey, true);
      debugPrint(
        'Teacher notification sent: level completion (stage=$stage, student=$senderName)',
      );
    } catch (e) {
      debugPrint('Error notifying teacher for level completion: $e');
    } finally {
      _bundleCompletionNotifyInFlight.remove(stage);
    }
  }

  Widget _buildDailyChecklist() {
    // Calculate progress
    int total = 4;
    int done = 0;
    if (_isQuizDone) done++;
    if (_isVocabDone) done++;
    if (_isVerbsDone) done++;
    if (_isSpeakingDone) done++;

    double progress = done / total;

    return DashboardProgressCard(
      containerKey: _dailyChecklistKey, // GlobalKey for Tutorial #2 targeting
      progress: progress,
      xpLevel: _xpLevel,
      currentXp: _currentXp,
      requiredXp: _requiredXp,
      totalXp: _totalXp,
      currentDayLabel: _currentDayLabel,
      isQuizDone: _isQuizDone,
      isVocabDone: _isVocabDone,
      isVerbsDone: _isVerbsDone,
      isSpeakingDone: _isSpeakingDone,
    );
  }

  Widget _buildGamesUnlockedCTA() {
    return DashboardGamesUnlockedCard(onTap: _handleGamesUnlockedTap);
  }

  Future<void> _markTaskDone(
    String key,
    String title, {
    int score = 100,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bool alreadyDone = prefs.getBool(key) ?? false;

    if (!alreadyDone) {
      await prefs.setBool(key, true);
      // Play victory sound + confetti for this task
      SoundService().playCompletion();
      _confettiController.play();

      // Sync to cloud
      _syncTaskToCloud(key, title, score);
    }
    await prefs.setInt('${key}_score', score);
  }

  Future<void> _syncTaskToCloud(
    String key,
    String title,
    int scorePercentage,
  ) async {
    try {
      // Cloud Progress Sync
      await _dataService.saveProgressToCloud(key, true);
      await _dataService.saveProgressToCloud('${key}_score', scorePercentage);

      // Sync task completion status and attendance.
      debugPrint("Syncing task completion to cloud. Title: $title");
      final prefs = await SharedPreferences.getInstance();
      String senderEmail = _userEmail;
      String senderName = prefs.getString('user_name') ?? '';

      final user = import_firebase_auth.FirebaseAuth.instance.currentUser;
      if (senderEmail.isEmpty && user != null) {
        senderEmail = user.email ?? 'Unknown Student';
      }

      // Fallback name if empty or default
      if (senderName.isEmpty || senderName == "Guest User") {
        if (senderEmail.contains('@')) {
          senderName = senderEmail.split('@')[0]; // Use part before @
        } else {
          senderName = "Student";
        }
      }

      if (senderEmail.isNotEmpty) {
        // Mark Attendance
        await _markAttendance(senderEmail, senderName);
        debugPrint(
          "Task synced for student progress: $senderName, task: $title",
        );
      } else {
        debugPrint("User email is empty, skipping attendance mark");
      }
    } catch (e) {
      debugPrint("Error syncing task to cloud: $e");
    }
  }

  Future<void> _markAttendance(String email, [String? name]) async {
    if (_userRole == 'teacher') {
      return; // Teachers don't mark their own attendance
    }

    final now = DateTime.now();
    final dateString = "${now.year}-${now.month}-${now.day}"; // yyyy-m-d
    final user = import_firebase_auth.FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final docId = "${dateString}_${user.uid}";
    final docRef = FirebaseFirestore.instance
        .collection('attendance')
        .doc(docId);

    // Check if already present
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) {
      debugPrint("Marking attendance for current user on $dateString");

      String studentName = name ?? '';
      if (studentName.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        studentName = prefs.getString('user_name') ?? '';
      }

      await docRef.set({
        'studentId': user.uid,
        'studentEmail': email,
        'studentName': studentName,
        'date': dateString,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Present',
      });
    }
  }

  // --- Mastery Tab ---
  Widget _buildMasteryTab() {
    if (!_isMasteryFeatureEnabled) {
      return const SizedBox.shrink();
    }
    if (_isPlacementStateLoading) {
      return const RefreshLottieLoader(
        message: "Loading mastery...",
        subtitle: "Preparing your focused practice",
      );
    }
    if (_isPlacementLocked) {
      return _buildPlacementLockedPage(
        title: "Mastery practice needs personalization",
        message:
            "Complete the placement quiz to begin focused practice at your level.",
        icon: Icons.lock_rounded,
        accentColor: const Color(0xFFFE5196),
      );
    }

    // Log analytics when mastery page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // FIX: Only trigger logic if actually on the Mastery tab (Index 2)
      if (_currentIndex == 2) {
        AnalyticsService().logEvent('mastery_page_opened');
        _showMasteryIntroIfNeeded();
      }
    });

    return SingleChildScrollView(
      key: ValueKey(
        'mastery_tab_$_currentIndex',
      ), // Force rebuild/animate on tab switch
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Mastery",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Optional practice lessons to improve skills over time.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Soft recommendation hint for beginners
          FutureBuilder<bool>(
            future: _shouldShowMasteryRecommendationHint(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: _buildRecommendationHint(),
                );
              }
              return const SizedBox(height: 32);
            },
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio:
                0.85, // ISSUE #7 FIX: Taller cards for multiline text
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              MasteryCard(
                key: _masteryCardKey, // GlobalKey for Tutorial #4 targeting
                title: "Reading",
                icon: Icons.auto_stories_rounded,
                color: const Color(0xFFC779D0),
                animationType: 'float',
                progress: _readingProgress,
                onTap: _handleReadingMasteryTap,
              ),
              MasteryCard(
                title: "Writing",
                icon: Icons.edit_note_rounded,
                color: const Color(0xFFFEAC5E),
                animationType: 'pulse',
                progress: _writingProgress,
                onTap: _handleWritingMasteryTap,
              ),
              MasteryCard(
                title: "Speaking",
                icon: Icons.record_voice_over_rounded,
                color: const Color(0xFF4BC0C8),
                animationType: 'wave',
                progress: _speakingProgress,
                onTap: _handleSpeakingMasteryTap,
              ),
              MasteryCard(
                title: "Listening",
                icon: Icons.headphones_rounded,
                color: const Color(0xFFFE5196),
                animationType: 'bell',
                progress: _listeningProgress,
                onTap: _handleListeningMasteryTap,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Black Hole Card (Wide Banner)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFA18CD1).withValues(alpha: 0.15),
                  const Color(0xFF1E1E2C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFA18CD1).withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _handleBlackHoleTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      // Animated Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA18CD1).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFA18CD1,
                              ).withValues(alpha: 0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child:
                            BlackholeIcon(
                                  size: 32,
                                  color: const Color(0xFFA18CD1),
                                  showGlow: false,
                                )
                                .animate(onPlay: (c) => c.repeat())
                                .rotate(duration: 8.seconds),
                      ),
                      const SizedBox(width: 20),
                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Black Hole",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Your collection of difficult words",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Arrow
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().slideY(begin: 0.2, end: 0, duration: 500.ms).fadeIn(),
        ],
      ),
    );
  }
}
