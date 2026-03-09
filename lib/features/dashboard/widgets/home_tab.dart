import 'dart:async';

import 'package:flutter/material.dart';

import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/screens/curriculum_screen.dart';
import 'package:gravity_app/screens/black_hole_screen.dart';
import 'package:gravity_app/widgets/games_hub_card.dart';
import 'package:gravity_app/features/dashboard/widgets/announcements_section.dart';
import 'package:gravity_app/features/dashboard/widgets/course_progress_dialog.dart';
import 'package:gravity_app/features/dashboard/widgets/dashboard_activity_item.dart';
import 'package:gravity_app/features/dashboard/widgets/teacher_attendance_section.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:gravity_app/services/tutorial_service.dart';
import 'package:gravity_app/utils/tutorial_helper.dart';
import 'package:gravity_app/widgets/coach_mark_overlay.dart'
    show CoachMarkHighlightShape;
import 'package:gravity_app/widgets/modern_glass_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/stage_progress_service.dart';

part 'home_tab_wall_of_fame.dart';
part 'home_tab_wall_of_fame_scoreboard.dart';
part 'home_tab_wall_of_fame_utils.dart';

part 'home_tab_sections.dart';

class HomeTab extends StatefulWidget {
  final String userRole;
  final int streakCount;
  final bool isStreakLoaded;
  final double overallProgress;
  final int totalXp;
  final Set<String> deletedAnnouncementIds;
  final Set<String> readAnnouncementIds;
  final bool announcementsReady;
  final Function(String) onAnnouncementDeleted;
  final Function(String) onAnnouncementRead;
  final VoidCallback? onGoToDailyTasks;
  final VoidCallback? onAttendQuiz;
  final bool isNewUser;
  final bool isPlacementQuizCompleted;
  final bool isPlacementLocked;
  final bool isPlacementStateLoading;
  final bool isActiveTab;

  const HomeTab({
    super.key,
    required this.userRole,
    required this.streakCount,
    required this.isStreakLoaded,
    required this.overallProgress,
    required this.totalXp,
    required this.deletedAnnouncementIds,
    required this.readAnnouncementIds,
    required this.announcementsReady,
    required this.onAnnouncementDeleted,
    required this.onAnnouncementRead,
    this.onGoToDailyTasks,
    this.onAttendQuiz,
    this.isNewUser = false,
    this.isPlacementQuizCompleted = false,
    this.isPlacementLocked = false,
    this.isPlacementStateLoading = false,
    this.isActiveTab = false,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // TEMP PREVIEW FLAG: Force showing local student name in award card.
  // Remove after visual review.
  static const bool _forceAwardNamePreview = false;
  final GlobalKey _streakBadgeKey = GlobalKey();
  late Stream<DocumentSnapshot> _awardsStream;
  final PageController _awardPageController = PageController();
  Timer? _awardSlideTimer;
  int _awardSlideIndex = 0;
  static final CacheManager _studentOfWeekImageCache = CacheManager(
    Config(
      'student_of_week_image_cache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 50,
    ),
  );

  final Map<String, Future<String?>> _winnerPhotoFutureById = {};
  final Map<String, Future<String>> _resolvedPhotoUrlFutureCache = {};
  String _awardNamePreviewFallback = '';
  String _awardPhotoPreviewFallback = '';
  int _blackHoleWordCount = 0;
  bool _blackHoleCountReady = false;

  @override
  void initState() {
    super.initState();
    // Initialize stream here to prevent recreation on every build
    _awardsStream = FirebaseFirestore.instance
        .collection('system')
        .doc('awards')
        .snapshots();
    _startAwardAutoScroll();
    _loadAwardNamePreviewFallback();
    _refreshBlackHoleWordCount();
    if (widget.isActiveTab) {
      _showDashboardTutorialIfNeeded();
    }
  }

  @override
  void didUpdateWidget(covariant HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userRole != widget.userRole ||
        (!oldWidget.isActiveTab && widget.isActiveTab)) {
      _refreshBlackHoleWordCount();
    }
    if (oldWidget.userRole != widget.userRole) {
      _resolvedPhotoUrlFutureCache.clear();
      _winnerPhotoFutureById.clear();
    }
    if (!oldWidget.isActiveTab && widget.isActiveTab) {
      _showDashboardTutorialIfNeeded();
    }
    if (oldWidget.isStreakLoaded != widget.isStreakLoaded &&
        widget.isActiveTab &&
        widget.isStreakLoaded) {
      _showDashboardTutorialIfNeeded();
    }
  }

  Future<void> _loadAwardNamePreviewFallback() async {
    final prefs = await SharedPreferences.getInstance();
    final name = (prefs.getString('user_name') ?? '').trim();
    final photo = (prefs.getString('photo_url') ?? '').trim();
    if (!mounted) return;
    setState(() {
      _awardNamePreviewFallback = name;
      _awardPhotoPreviewFallback = photo;
    });
  }

  void _startAwardAutoScroll() {
    _awardSlideTimer?.cancel();
    _awardSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_awardPageController.hasClients) return;
      final next = (_awardSlideIndex + 1) % 2;
      _awardPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutQuart,
      );
    });
  }

  @override
  void dispose() {
    _awardSlideTimer?.cancel();
    _awardPageController.dispose();
    _resolvedPhotoUrlFutureCache.clear();
    _winnerPhotoFutureById.clear();
    super.dispose();
  }

  Future<void> _showDashboardTutorialIfNeeded() async {
    if (!widget.isActiveTab ||
        widget.userRole != 'student' ||
        !widget.isStreakLoaded) {
      return;
    }
    // Wait for first frame to render
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !widget.isActiveTab) return;

      final shouldShow = await TutorialService().shouldShowDashboardTutorial(
        widget.streakCount,
      );

      if (shouldShow && mounted && !TutorialHelper.isShowingTutorial) {
        // Small delay to ensure layout is complete
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted || !widget.isActiveTab) return;

        TutorialHelper.showTutorial(
          context: context,
          targetKey: _streakBadgeKey,
          title: "Build Consistency",
          message:
              "This counter grows when you complete your Learning Plan. Stay consistent to keep momentum.",
          accentColor: const Color(0xFFFF9F43), // Orange to match fire icon
          alignment: Alignment.topCenter,
          highlightShape: CoachMarkHighlightShape.pill,
          highlightPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          onDismiss: () {
            unawaited(TutorialService().markDashboardTutorialSeen());
          },
        );
      }
    });
  }

  Future<void> _refreshBlackHoleWordCount() async {
    if (widget.userRole == 'teacher') return;
    try {
      final items = await DataService().getBlackHoleItems();
      if (!mounted) return;
      setState(() {
        _blackHoleWordCount = items.length;
        _blackHoleCountReady = true;
      });
    } catch (e) {
      debugPrint('HomeTab: Failed to load Black Hole count: $e');
      if (!mounted) return;
      setState(() {
        _blackHoleCountReady = true;
      });
    }
  }

  Widget? _buildBlackHoleAttentionBadge() {
    if (!_blackHoleCountReady || _blackHoleWordCount <= 10) return null;
    return Tooltip(
          message:
              'Black Hole has $_blackHoleWordCount words. Tap to review now.',
          child: Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5252),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD166), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Text(
              '!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                height: 1.0,
              ),
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.15, 1.15),
          duration: 700.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .shake(
          hz: 4,
          duration: 420.ms,
          curve: Curves.easeInOut,
          offset: const Offset(1.6, 0),
        );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.isPlacementStateLoading &&
              !widget.isPlacementQuizCompleted &&
              widget.userRole != 'teacher')
            _buildPlacementQuizCard(),
          _buildWelcomeCard(),
          _buildWallOfFame(),

          if (widget.userRole != 'teacher')
            AnnouncementsSection(
              deletedIds: widget.deletedAnnouncementIds,
              readIds: widget.readAnnouncementIds,
              isReady: widget.announcementsReady,
              userRole: widget.userRole,
              onDelete: widget.onAnnouncementDeleted,
              onMarkRead: widget.onAnnouncementRead,
            ),

          if (widget.userRole == 'teacher') const TeacherAttendanceSection(),

          if (widget.userRole == 'teacher') ...[
            const SizedBox(height: 12),
            DashboardActivityItem(
              title: "Mega Quiz",
              subtitle: "Coming Soon - Comprehensive Assessment",
              icon: Icons.quiz_rounded,
              color: const Color(0xFFFFD700), // Gold color
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Mega Quiz feature is planned for future release!",
                    ),
                    backgroundColor: Color(0xFFFFD700),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 16),
          // Structured Learning Section
          Text(
            "Structured Learning",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 12),
          DashboardActivityItem(
            title: "Full Curriculum",
            subtitle:
                "${DataService().getCurriculumLessons().length} English lessons for grammar and usage",
            icon: Icons.school_rounded,
            color: const Color(0xFFFE5196),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CurriculumScreen()),
              );
            },
          ),

          const SizedBox(height: 12),
          DashboardActivityItem(
            title: "Blackhole - Your Difficult Words",
            subtitle: "Review words you struggled with",
            icon: Icons.cyclone,
            color: const Color(0xFF4FACFE),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlackHoleScreen()),
              );
            },
            trailingBadge: _buildBlackHoleAttentionBadge(),
          ),

          const SizedBox(height: 16),
          // Games Hub Section
          GamesHubCard(
            onGoToDailyTasks: widget.onGoToDailyTasks,
            isLocked: false,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _setAwardSlideIndex(int index) {
    if (!mounted) return;
    setState(() => _awardSlideIndex = index);
  }
}
