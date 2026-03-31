import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gravity_app/services/data_service.dart' as data_service;
import 'package:gravity_app/services/sound_service.dart'; // Import SoundService
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/profile_screen.dart';
import 'package:gravity_app/mastery/reading_screen.dart';

import 'package:gravity_app/mastery/listening_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gravity_app/services/notification_service.dart';
import 'package:gravity_app/screens/notifications_screen.dart';
import 'package:gravity_app/screens/teacher_notifications_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as import_firebase_auth;
import 'package:gravity_app/services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gravity_app/services/stage_content_service.dart';
import 'package:gravity_app/screens/daily_vocabulary_list_screen.dart';
import 'package:gravity_app/screens/daily_verbs_list_screen.dart';
import 'package:gravity_app/screens/daily_review_screen.dart'; // Import DailyReviewScreen
import 'package:gravity_app/screens/stage_journey_map_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/main.dart';
import 'package:gravity_app/services/stage_progress_service.dart';
import 'package:gravity_app/services/daily_task_completion_service.dart';
import 'package:gravity_app/widgets/games_hub_card.dart';
import 'package:gravity_app/widgets/modern_glass_dialog.dart';
import 'package:gravity_app/services/placement_state_service.dart';
import 'package:gravity_app/services/user_level_service.dart';
import 'package:gravity_app/services/xp_reward_policy.dart';
import 'package:gravity_app/widgets/custom_animations.dart';

import 'package:gravity_app/widgets/animated_bottom_nav.dart';
import 'package:gravity_app/widgets/blackhole_icon.dart';
import 'package:gravity_app/widgets/space_dust_background.dart';
// TODO: Uncomment after running: flutter pub add image_picker image_cropper firebase_storage
// import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:io';

import 'package:gravity_app/screens/speaking_practice_screen.dart';
import 'package:gravity_app/screens/daily_speaking_challenge_screen.dart'; // Add import
import 'package:gravity_app/widgets/refresh_lottie_loader.dart';
import 'package:gravity_app/widgets/mastery_card.dart'; // New Mastery Card Widget

import 'package:gravity_app/screens/black_hole_screen.dart';
import 'package:gravity_app/mastery/writing_screen.dart'; // Re-import WritingScreen
import 'package:gravity_app/screens/placement_quiz_screen.dart';
import 'package:gravity_app/screens/account_blocked_screen.dart';
// import 'package:gravity_app/widgets/offline_banner.dart'; // Removed
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:gravity_app/features/dashboard/widgets/home_tab.dart'; // Import HomeTab
import 'package:gravity_app/features/dashboard/widgets/settings_tab.dart'; // Extracted SettingsTab
import 'package:gravity_app/services/tutorial_service.dart';
import 'package:gravity_app/services/feature_highlight_service.dart';
import 'package:gravity_app/features/tutorial/onboarding_screen.dart';
import 'package:gravity_app/utils/tutorial_helper.dart';
import 'package:gravity_app/widgets/coach_mark_overlay.dart'
    show CoachMarkHighlightShape;

import 'package:gravity_app/dashboard/widgets/dashboard_games.dart';
import 'package:gravity_app/dashboard/widgets/dashboard_header.dart';
import 'package:gravity_app/dashboard/widgets/dashboard_progress.dart';
import 'package:gravity_app/dashboard/widgets/dashboard_recent_activity.dart';
import 'package:gravity_app/dashboard/widgets/dashboard_stats.dart';
import 'package:gravity_app/dashboard/widgets/dashboard_tasks.dart';
import 'package:gravity_app/dashboard/shared/dashboard_card.dart';
import 'package:gravity_app/dashboard/shared/dashboard_library_action_header.dart';
import 'package:gravity_app/dashboard/shared/dashboard_section_header.dart';
import 'package:gravity_app/widgets/recovery_debug_panel.dart';

import 'package:gravity_app/services/analytics_service.dart';
part 'dashboard_init.dart';
part 'dashboard_shell_helpers.dart';
part 'dashboard_notifications.dart';
part 'dashboard_tasks.dart';
part 'dashboard_tutorial.dart';
part 'dashboard_actions.dart';
part '../dashboard_helpers.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver, RouteAware {
  // Mastery feature flag (kept disabled, feature hidden from users)
  static const bool _enableMasteryFeature = false;
  static const String _studentPlanTabLabel = 'Tasks';
  bool get _isMasteryFeatureEnabled => _enableMasteryFeature;

  int _currentIndex = 0;
  final PageController _tabPageController = PageController();
  bool _isConnected = true; // Track connection
  StreamSubscription? _internetSubscription;
  StreamSubscription? _announcementSubscription;
  final data_service.DataService _dataService = data_service.DataService();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<RemoteMessage>? _remoteNotificationTapSubscription;
  StreamSubscription<String?>? _localNotificationTapSubscription;
  static const String _pendingDailyTasksNavKey = 'pending_daily_tasks_nav';
  String _userRole = 'student';
  String _userEmail = '';
  Timer? _offlineTimer;
  Timer? _progressPollingTimer; // Auto-refresh timer for daily progress
  late ConfettiController _confettiController;
  final StageProgressService _stageService = StageProgressService();
  bool _showLevelUpOverlay = false;
  String _levelUpLabel = '';
  int _totalXp = 0;
  int _xpLevel = 1;
  int _currentXp = 0;
  int _requiredXp = XpRewardPolicy.requiredXpForLevel(1);
  int _xpBurstAmount = 0;
  int _xpBurstVersion = 0;
  bool _showXpBurst = false;
  Timer? _xpBurstTimer;

  // Track notifications state locally as well if needed, or rely on StreamBuilder
  Set<String> _readIds = {};
  Set<String> _deletedIds = {};
  Set<String> _teacherReadIds = {};
  Set<String> _teacherDeletedIds = {};
  bool _announcementFiltersReady = false;

  double _overallProgress = 0.0;
  int _streakCount = 0;
  bool _isStreakLoaded = false;
  String? _currentDayLabel;

  // Mastery Progress State
  double _readingProgress = 0.0;
  double _writingProgress = 0.0;
  double _speakingProgress = 0.0;
  double _listeningProgress = 0.0;

  // Double-back press to exit
  DateTime? _lastBackPressed;

  // ISSUE #7 FIX: Suppress all popups during logout
  bool _isLoggingOut = false;

  // Tutorial GlobalKeys
  final GlobalKey _dailyChecklistKey = GlobalKey();
  final GlobalKey _masteryCardKey = GlobalKey();
  final GlobalKey _blackHoleFeatureKey = GlobalKey();
  static const String _blackHoleFeatureHighlightId = 'black_hole_focus_quiz';
  bool _highlightBlackHoleFeature = false;

  // Assessment Status
  bool _isAssessmentCompleted = false;

  bool _isAttentionModalActive = false;
  Map<String, dynamic>? _pendingImportantAnnouncement;
  List<String> _pendingImportantAnnouncementIds = [];

  // Placement Quiz Status
  String _placementQuizStatus = PlacementStateService.statusNotStarted;
  bool _isPlacementStateLoading = true;

  bool get _isPlacementQuizCompleted =>
      _placementQuizStatus == PlacementStateService.statusCompleted;
  bool get _isPlacementLocked => !_isPlacementQuizCompleted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize Confetti immediately (synchronous, must happen before build)
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Wrap all other init operations in try-catch to prevent crashes
    _safeInit();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _internetSubscription?.cancel();
    _announcementSubscription?.cancel();
    _remoteNotificationTapSubscription?.cancel();
    _localNotificationTapSubscription?.cancel();
    _offlineTimer?.cancel();
    _progressPollingTimer?.cancel();
    _xpBurstTimer?.cancel();
    _confettiController.dispose();
    _tabPageController.dispose();
    _dataService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _announcementSubscription?.cancel();
      _announcementSubscription = null;
    }
    if (state == AppLifecycleState.resumed) {
      _setupNotificationListener();
      _checkDailyProgress();
      _checkLevelUpgradeCelebration();
      _fetchStreak();
      unawaited(_fetchPlacementState());
      _navigateToPendingDailyTasks();
    }
  }

  @override
  void didPopNext() {
    // Recompute pending state when returning to dashboard.
    _checkDailyProgress();
    _checkLevelUpgradeCelebration();
    _fetchStreak();
    unawaited(_fetchPlacementState());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final bool showMastery = _isMasteryFeatureEnabled && _userRole == 'student';
    return PopScope(
      canPop: false, // We'll handle the pop manually
      onPopInvokedWithResult: _handlePopInvokedWithResult,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF030305), Color(0xFF0B1220)]
                        : const [Color(0xFFF4F8FF), Color(0xFFEAF2FF)],
                  ),
                ),
              ),
            ),
            // Background Blobs
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(
                    alpha: isDark ? 0.15 : 0.1,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondary.withValues(
                    alpha: isDark ? 0.1 : 0.08,
                  ),
                ),
              ),
            ),

            // Space Dust Particles
            if (isDark)
              const Positioned.fill(
                child: IgnorePointer(child: SpaceDustBackground()),
              ),

            SafeArea(
              child: Column(
                children: [
                  // Main Content (Offline Banner REMOVED)

                  // Custom AppBar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 20,
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onLongPress: () =>
                          unawaited(RecoveryDebugPanel.show(context)),
                      child: DashboardHeader(
                        title: _getAppBarTitle(),
                        userRole: _userRole,
                        readIds: _readIds,
                        deletedIds: _deletedIds,
                        teacherReadIds: _teacherReadIds,
                        teacherDeletedIds: _teacherDeletedIds,
                        photoUrl: _photoUrl,
                        avatarSeed: _avatarSeed,
                        notificationsReady: _announcementFiltersReady,
                        blackHoleKey: _blackHoleFeatureKey,
                        highlightBlackHole: _highlightBlackHoleFeature,
                        onBlackHoleTap: _handleAppBarBlackHoleTap,
                        onNotificationsTap: _handleNotificationsTap,
                        onProfileTap: _handleProfileTap,
                      ),
                    ),
                  ),

                  // Main Content
                  Expanded(
                    child: PageView(
                      controller: _tabPageController,
                      onPageChanged: _handleTabPageChanged,
                      children: [
                        HomeTab(
                          userRole: _userRole,
                          streakCount: _streakCount,
                          isStreakLoaded: _isStreakLoaded,
                          overallProgress: _overallProgress,
                          totalXp: _totalXp,
                          deletedAnnouncementIds: _deletedIds,
                          readAnnouncementIds: _readIds,
                          announcementsReady: _announcementFiltersReady,
                          onAnnouncementDeleted: _deleteAnnouncement,
                          onAnnouncementRead: _markAnnouncementRead,
                          isPlacementQuizCompleted: _isPlacementQuizCompleted,
                          isPlacementLocked: _isPlacementLocked,
                          isPlacementStateLoading: _isPlacementStateLoading,
                          isActiveTab: _currentIndex == 0,
                          onAttendQuiz: _attendQuiz,
                          onGoToDailyTasks: _handleGoToDailyTasksTab,
                        ),
                        if (_userRole == 'teacher') ...[
                          Center(
                            child: Text(
                              "Students Management (Coming Soon)",
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          // Teacher Library Tab
                          _buildTeacherLibraryTab(),
                        ] else ...[
                          _buildDailyTasksTab(),
                          if (showMastery) _buildMasteryTab(),
                        ],
                        SettingsTab(
                          onLogout: _handleLogout,
                          onLanguageChanged: _handleLanguageChanged,
                          currentThemeMode: widget.themeMode,
                          onThemeModeChanged: widget.onThemeModeChanged,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Confetti Overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                gravity: 0.4,
                emissionFrequency: 0.02,
                numberOfParticles: 50, // More particles
                maxBlastForce: 30,
                minBlastForce: 10,
                createParticlePath: (size) {
                  final path = Path();
                  // Draw a circle for "small particles" look instead of rects
                  path.addOval(
                    Rect.fromCircle(
                      center: Offset(size.width / 2, size.height / 2),
                      radius: 4,
                    ),
                  );
                  return path;
                },
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.redAccent,
                  Colors.cyanAccent,
                  Colors.amber,
                ],
              ),
            ),
            if (_showXpBurst)
              Positioned(
                top: 96,
                left: 0,
                right: 0,
                child: IgnorePointer(child: Center(child: _buildXpBurstChip())),
              ),
            if (_showLevelUpOverlay)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: LevelUpCelebrationOverlay(levelLabel: _levelUpLabel),
                ),
              ),

            // Connectivity Card (Attached to bottom nav)
            _buildConnectivityCard(),
          ],
        ),
        bottomNavigationBar: Animated3DBottomNav(
          currentIndex: _currentIndex,
          onTap: _handleBottomNavTap,
          role: _userRole,
          showMastery: showMastery,
          studentPlanLabel: _studentPlanTabLabel,
        ),
      ),
    );
  }

  String _preferredLanguage = 'Tamil'; // Restore Default
  double _savedDailyWordCount = 5.0; // Track saved value
  String _avatarSeed = '';
  String _photoUrl = '';

  bool _notificationsEnabled = true;

  // Track transient success state
  bool _showOnlineSuccess = false;

  final DateTime _dashboardStartTime = DateTime.now();

  bool _isVocabDone = false;
  bool _isVerbsDone = false;
  bool _isSpeakingDone = false;
  bool _isQuizDone = false;
  bool _hasLoadedDailyProgress = false;
  final Set<int> _bundleCompletionNotifyInFlight = <int>{};

  // Score percentages for each task
  int _vocabScore = 0;
  int _verbsScore = 0;
  int _speakingScore = 0;
  int _quizScore = 0;

  bool _isNoticeActive = false;

  // Announcement section removed
}
