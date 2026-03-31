import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
// For blur effect

enum LevelMapLayout { zigZag, spiral, timeline }

class MasteryLevelMap extends StatefulWidget {
  final String title;
  final List<Map<String, String>> exercises;
  final List<String> completedIds;
  final Map<String, int>? scoreMap; // ID -> Score (0-100)
  final Function(Map<String, String>) onTapExercise;
  final bool Function(Map<String, String> exercise, int index)?
  isLockedOverride;
  final String Function(Map<String, String> exercise, int index)?
  lockReasonOverride;
  final void Function(Map<String, String> exercise, int index)? onLockedTap;
  final int? unlockedLevelCount;
  final VoidCallback onBack;
  final bool useStarRating;
  final LevelMapLayout layoutType;
  final List<Widget>? actions;
  final bool showInfoButton;

  const MasteryLevelMap({
    super.key,
    required this.title,
    required this.exercises,
    required this.completedIds,
    required this.onTapExercise,
    this.isLockedOverride,
    this.lockReasonOverride,
    this.onLockedTap,
    required this.onBack,
    this.unlockedLevelCount,
    this.scoreMap,
    this.useStarRating = false,
    this.layoutType = LevelMapLayout.zigZag,
    this.actions,
    this.showInfoButton = true,
  });

  @override
  State<MasteryLevelMap> createState() => _MasteryLevelMapState();
}

class _MasteryLevelMapState extends State<MasteryLevelMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _pathController;
  late ConfettiController _confettiController;
  late ScrollController _scrollController;
  bool _isAnimatingPath = false;

  @override
  void initState() {
    super.initState();
    _pathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // Create scroll controller with initial offset
    _scrollController = ScrollController();
    // Use post-frame callback for tutorials only
    if (widget.showInfoButton) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkStarTutorial();
      });
    }
  }

  void _checkStarTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('star_system_info_seen_v2') ?? false;
    if (!seen) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _showStarSystemInfo();
      });
    }
  }

  void _showStarSystemInfo() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: 300.ms,
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white24
                      : onSurface.withValues(alpha: 0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "How to Earn Stars",
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildStarRow(1, "Complete the Story"),
                  const SizedBox(height: 16),
                  _buildStarRow(2, "Pass the Quiz"),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4FACFE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Got it!"),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().scale(curve: Curves.easeOutBack, duration: 300.ms),
        );
      },
    ).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('star_system_info_seen_v2', true);
    });
  }

  Widget _buildStarRow(int stars, String text) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            stars,
            (index) => const Padding(
              padding: EdgeInsets.only(right: 2.0),
              child: Icon(Icons.star_rounded, color: Colors.amber, size: 24),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.78),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(MasteryLevelMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.completedIds.length > oldWidget.completedIds.length) {
      // New level unlocked! Trigger animation.
      _startPathAnimation();
      _confettiController.play();

      // Auto-move ONLY on real progress
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentLevel();
      });
    }
  }

  Future<void> _startPathAnimation() async {
    if (!mounted) return;
    setState(() {
      _isAnimatingPath = true;
    });
    await _pathController.forward(from: 0.0);
    if (mounted) {
      setState(() {
        _isAnimatingPath = false;
      });
    }
  }

  void _scrollToCurrentLevel({bool animate = true}) {
    if (!mounted || widget.exercises.isEmpty) return;

    // Find first unfinished level or last level if all done
    int targetIndex = 0;
    if (widget.unlockedLevelCount != null) {
      final maxCount = widget.exercises.length;
      final int count = widget.unlockedLevelCount!.clamp(1, maxCount);
      targetIndex = count >= maxCount ? maxCount - 1 : count - 1;
    } else {
      for (int i = 0; i < widget.exercises.length; i++) {
        if (!widget.completedIds.contains(widget.exercises[i]['id'])) {
          targetIndex = i;
          break;
        }
        if (i == widget.exercises.length - 1) targetIndex = i;
      }
    }

    if (targetIndex > 0 || !animate) {
      const double spacingY = 140.0;
      // Calculate position: Index * Spacing - Padding/Offset so it's centered or near top
      double offset = (targetIndex * spacingY) - 100;
      if (offset < 0) offset = 0;

      // Ensure we don't scroll past max extent
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (offset > maxScroll) offset = maxScroll;

        if (animate) {
          _scrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
          );
        } else {
          // Instant jump for initial load
          _scrollController.jumpTo(offset);
        }
      }
    }
  }

  @override
  void dispose() {
    _pathController.dispose();
    _confettiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    // Determine status
    // We assume exercises are ordered.
    // 'currentLevelIndex' is the first index that is NOT completed.
    // However, users might skip or filter.
    // Logic: A level is Locked if the Previous level is NOT completed.
    // Level 0 is always unlocked.

    // Better logic for filtered list:
    // If we are viewing "Beginner", we treat it as a sequence.

    int currentLevelIndex = 0;
    if (widget.unlockedLevelCount != null && widget.exercises.isNotEmpty) {
      final maxCount = widget.exercises.length;
      final int count = widget.unlockedLevelCount!.clamp(1, maxCount);
      currentLevelIndex = count >= maxCount ? maxCount : count - 1;
    } else {
      // Find the first one not completed
      for (int i = 0; i < widget.exercises.length; i++) {
        if (!widget.completedIds.contains(widget.exercises[i]['id'])) {
          currentLevelIndex = i;
          break;
        }
        // If all checked (last one), then current is last+1 (all done)
        if (i == widget.exercises.length - 1) {
          currentLevelIndex = i + 1;
        }
      }
    }

    return Stack(
      children: [
        // Background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: isDark
                    ? const [Color(0xFF1B1B2F), Color(0xFF000000)]
                    : const [Color(0xFFF4F8FF), Color(0xFFE7F0FF)],
              ),
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: onSurface,
                      ),
                      onPressed: widget.onBack,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    if (widget.showInfoButton)
                      IconButton(
                        icon: Icon(
                          Icons.info_outline_rounded,
                          color: onSurface.withValues(alpha: 0.62),
                          size: 20,
                        ),
                        onPressed: _showStarSystemInfo,
                        tooltip: "How to earn stars",
                      ),
                    if (widget.actions != null) ...widget.actions!,
                  ],
                ),
              ),

              // Map
              Expanded(
                child: widget.exercises.isEmpty
                    ? Center(
                        child: Text(
                          "No missions available yet. Check back later!",
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.62),
                          ),
                        ),
                      )
                    : _buildMap(
                        currentLevelIndex,
                        isDark: isDark,
                        onSurface: onSurface,
                      ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            // Realistic Physics
            gravity: 0.3,
            emissionFrequency: 0.05,
            numberOfParticles: 20, // Burst of particles
            maxBlastForce: 20,
            minBlastForce: 5,
            // Smaller Particles
            createParticlePath: (size) {
              final path = Path();
              // Create a small rectangle (confetti strip)
              path.addRect(
                Rect.fromLTWH(0, 0, size.width * 0.5, size.height * 0.25),
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
              Colors.amber,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMap(
    int currentLevelIndex, {
    required bool isDark,
    required Color onSurface,
  }) {
    const int crossAxisCount = 3;
    const double nodeSize = 60.0;
    const double spacingY = 140.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final rows = (widget.exercises.length / crossAxisCount).ceil();
        final totalHeight = rows * spacingY + 100;

        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 20, bottom: 50),
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                // Paths
                AnimatedBuilder(
                  animation: _pathController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(width, totalHeight),
                      painter: _PathPainter(
                        itemCount: widget.exercises.length,
                        crossAxisCount: crossAxisCount,
                        spacingY: spacingY,
                        nodeSize: nodeSize,
                        completedIndex: currentLevelIndex,
                        layoutType: widget.layoutType,
                        animateLastPath: _isAnimatingPath,
                        animationValue: _pathController.value,
                        isDark: isDark,
                      ),
                    );
                  },
                ),

                // Nodes
                ...List.generate(widget.exercises.length, (index) {
                  final exercise = widget.exercises[index];

                  // Helper to get stars for any index
                  int getStars(int i) {
                    if (i < 0 || i >= widget.exercises.length) return 0;
                    final ex = widget.exercises[i];
                    int s = 0;
                    if (ex['storybook_completed'] == 'true') s++;
                    if (ex['quiz_completed'] == 'true') s++;
                    if (ex['master_quiz_completed'] == 'true') {
                      s++; // Phase 1 Key
                    }
                    return s > 3 ? 3 : s;
                  }

                  final bool hasOverride = widget.isLockedOverride != null;
                  final bool overrideLocked = hasOverride
                      ? widget.isLockedOverride!(exercise, index)
                      : false;

                  // If override exists, it is authoritative.
                  // Otherwise, unlock sequentially based on completion.
                  bool isLocked = hasOverride
                      ? overrideLocked
                      : index > currentLevelIndex;
                  String? lockReason;
                  if (isLocked) {
                    if (widget.lockReasonOverride != null) {
                      lockReason = widget.lockReasonOverride!(exercise, index);
                    } else if (index > 0) {
                      lockReason =
                          "Complete ${widget.exercises[index - 1]['title']} first";
                    } else {
                      lockReason = "Complete previous missions first";
                    }
                  }

                  final isCompleted = getStars(index) >= 1;
                  // Simple: index == 0 is current if 0 stars.
                  // Basically finding the "furthest usable level".
                  // Let's rely on isLocked logic.
                  // If I am !isLocked, and (I am incomplete OR Next is Locked).
                  // But 'currentLevelIndex' (from parent logic) drives animation.
                  // Let's assume passed 'index == currentLevelIndex' logic is still approximately valid
                  // or redefine isCurrent here.

                  // Better:
                  final isCurrent = !isLocked && !isCompleted;
                  // If all are completed, the last one might be 'current'.
                  // For now, let's stick to !isLocked && stars < 1.

                  // Zig-Zag Logic
                  final row = index ~/ crossAxisCount;
                  final isRowEven = row % 2 == 0;
                  int col = index % crossAxisCount;
                  if (!isRowEven) {
                    col = (crossAxisCount - 1) - col;
                  }

                  final sectionWidth = width / crossAxisCount;

                  Offset pos;
                  if (widget.layoutType == LevelMapLayout.timeline) {
                    pos = Offset(60, (index * spacingY) + 20 + (nodeSize / 2));
                  } else {
                    final px = (col * sectionWidth) + (sectionWidth / 2);
                    final py = (row * spacingY) + 20 + (nodeSize / 2);
                    pos = Offset(px, py);
                  }

                  final dx = pos.dx - (nodeSize / 2);
                  final dy = pos.dy - (nodeSize / 2);

                  return Positioned(
                    left: dx,
                    top: dy,
                    child: _buildNode(
                      exercise,
                      index,
                      isCompleted,
                      isLocked,
                      isCurrent,
                      nodeSize,
                      isDark: isDark,
                      onSurface: onSurface,
                      lockReason: lockReason,
                    ),
                  );
                }),

                // TIMELINE TITLES (Visible only in timeline mode)
                if (widget.layoutType == LevelMapLayout.timeline)
                  ...List.generate(widget.exercises.length, (index) {
                    final exercise = widget.exercises[index];
                    final bool hasOverride = widget.isLockedOverride != null;
                    final bool isLocked = hasOverride
                        ? widget.isLockedOverride!(exercise, index)
                        : index > currentLevelIndex;
                    final dy = (index * spacingY) + 20 + (nodeSize / 2);
                    // Offset text to right of node
                    // Node center x = 60. So text starts at 100?
                    return Positioned(
                      left: 100,
                      top: dy - 10, // Vertically center text
                      right: 20,
                      child: Text(
                        widget.exercises[index]['title'] ??
                            'Mission ${index + 1}',
                        style: TextStyle(
                          color: isLocked
                              ? onSurface.withValues(alpha: 0.38)
                              : onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),

                // Confetti overlay aligned to the top center of the map mostly,
                // but since it's a scrollable view, we might want it fixed in the PARENT stack.
                // However, putting it here means it moves with scroll which is odd.
                // Re-reading user request: "confetti on curriculum levels completion".
                // Usually confetti rains from top of SCREEN.
                // I will add ConfettiWidget in the main build method's Stack instead.
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNode(
    Map<String, String> exercise,
    int index,
    bool isCompleted,
    bool isLocked,
    bool isCurrent,
    double size, {
    required bool isDark,
    required Color onSurface,
    String? lockReason,
  }) {
    // Check for 3-Star Completion flags
    final hasStorybook = exercise['storybook_completed'] == 'true';
    final hasQuiz = exercise['quiz_completed'] == 'true';
    final hasMasterQuiz = exercise['master_quiz_completed'] == 'true';

    // 3-Star Calculation (Additive)
    int stars = 0;
    if (widget.useStarRating) {
      if (hasStorybook) stars++;
      if (hasQuiz) stars++;
      if (hasMasterQuiz) stars++;
    }

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          if (widget.onLockedTap != null) {
            widget.onLockedTap!(exercise, index);
            return;
          }
          // Show feedback for locked lesson
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lockReason ?? "Complete previous missions first"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        widget.onTapExercise(exercise);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // STAR RATING (Above Node)
          if (widget.useStarRating)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final isEarned = index < stars;
                  return Icon(
                    isEarned ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isEarned
                        ? Colors.amber
                        : (isDark
                              ? Colors.white24
                              : onSurface.withValues(alpha: 0.3)),
                    size: 14,
                  );
                }),
              ),
            ),

          // Node with checkmarks
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                    width: size,
                    height: size,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLocked
                          ? (isDark
                                ? const Color(0xFF2E2E3E)
                                : const Color(0xFFD2DFF5))
                          : isCompleted
                          ? (widget.layoutType == LevelMapLayout.spiral
                                ? const Color(0xFF4A148C)
                                : const Color(0xFF0D47A1))
                          : const Color(0xFF643FDB),
                      boxShadow: [
                        BoxShadow(
                          color: isCompleted
                              ? (stars >= 2
                                    ? Colors.amber.withValues(alpha: 0.4)
                                    : Colors.lightBlueAccent.withValues(
                                        alpha: 0.4,
                                      ))
                              : const Color(0xFF643FDB).withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: isCurrent ? 5 : 2,
                        ),
                      ],
                      border: Border.all(
                        color: isLocked
                            ? (isDark
                                  ? Colors.white10
                                  : onSurface.withValues(alpha: 0.2))
                            : isCompleted
                            ? (stars == 3
                                  ? Colors.amber
                                  : Colors.lightBlueAccent)
                            : Colors.white,
                        width: isCurrent ? 3 : 2,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isCompleted
                            ? [
                                widget.layoutType == LevelMapLayout.spiral
                                    ? const Color(0xFF7B1FA2)
                                    : const Color(0xFF4FACFE),
                                widget.layoutType == LevelMapLayout.spiral
                                    ? const Color(0xFF4A148C)
                                    : const Color(0xFF00F2FE),
                              ]
                            : [
                                const Color(0xFF8A2387),
                                const Color(0xFFE94057),
                              ],
                      ),
                    ),
                    child: isLocked
                        ? Icon(
                            Icons.lock_outline_rounded,
                            color: isDark
                                ? Colors.white24
                                : onSurface.withValues(alpha: 0.35),
                            size: 28,
                          )
                        : isCompleted
                        ? Icon(
                            // Trophy for 3 stars, Check for others
                            (widget.useStarRating && stars == 3)
                                ? Icons.emoji_events_rounded
                                : Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 32,
                          )
                        : Text(
                            "${index + 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  )
                  .animate(target: isCurrent ? 1 : 0)
                  .scale(
                    end: const Offset(1.1, 1.1),
                    duration: 1000.ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(end: const Offset(1.0, 1.0), duration: 1000.ms),

              // REMOVED CORNER STARS (Replaced by Row)
            ],
          ),

          if (widget.layoutType !=
              LevelMapLayout.timeline) // Hide small label in timeline mode
            const SizedBox(height: 12),

          if (widget.layoutType != LevelMapLayout.timeline)
            Container(
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black54
                    : Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(8),
                border: isCurrent
                    ? Border.all(
                        color: const Color(0xFF643FDB).withValues(alpha: 0.5),
                      )
                    : (!isDark
                          ? Border.all(color: onSurface.withValues(alpha: 0.1))
                          : null),
              ),
              child: Text(
                exercise['title'] ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  color: isDark ? Colors.white : onSurface,
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final int itemCount;
  final int crossAxisCount;
  final double spacingY;
  final double nodeSize;
  final int completedIndex;
  final LevelMapLayout layoutType;
  final bool animateLastPath;
  final bool isDark;
  final double animationValue; // 0.0 to 1.0 for the active segment

  _PathPainter({
    required this.itemCount,
    required this.crossAxisCount,
    required this.spacingY,
    required this.nodeSize,
    required this.completedIndex,
    this.layoutType = LevelMapLayout.zigZag,
    this.animateLastPath = false,
    required this.isDark,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint activePaint = Paint()
      ..color = layoutType == LevelMapLayout.spiral
          ? const Color(0xFFAB47BC)
          : const Color(0xFF643FDB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final Paint lockedPaint = Paint()
      ..color = isDark
          ? Colors.white10
          : const Color(0xFFB8CAE8).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final sectionWidth = size.width / crossAxisCount;

    for (int i = 0; i < itemCount - 1; i++) {
      final p1 = _getOffset(i, sectionWidth);
      final p2 = _getOffset(i + 1, sectionWidth);

      // Determine if this specific path segment is "fully active", "animating", or "locked".
      // Paths connect i -> i+1.
      // If completedIndex is 5, then 0->1, 1->2, 2->3, 3->4, 4->5 should be potentially active.

      bool isAnimating = (animateLastPath && i == completedIndex - 1);
      bool isFullyActive = (i < completedIndex) && !isAnimating;

      // For spiral, we draw curves; else lines
      Path path = Path();
      if (layoutType == LevelMapLayout.spiral) {
        path.moveTo(p1.dx, p1.dy);
        double cx = (p1.dx + p2.dx) / 2;
        double cy = (p1.dy + p2.dy) / 2;
        if (i % 2 == 0) {
          cx += 40;
        } else {
          cx -= 40;
        }
        path.quadraticBezierTo(cx, cy, p2.dx, p2.dy);
      } else {
        path.moveTo(p1.dx, p1.dy);
        path.lineTo(p2.dx, p2.dy);
      }

      // 1. Draw Background (Locked) Trace
      canvas.drawPath(path, lockedPaint);

      // 2. Draw Active/Animating Trace
      if (isFullyActive) {
        canvas.drawPath(path, activePaint);
      } else if (isAnimating) {
        // Draw partial path based on animationValue
        try {
          // Use PathMetrics to extract partial path
          final metrics = path.computeMetrics().first;
          // Apply easing curve for smoother animation
          final curvedValue = Curves.easeInOut.transform(animationValue);
          final extract = metrics.extractPath(
            0.0,
            metrics.length * curvedValue,
          );
          canvas.drawPath(extract, activePaint);

          // Draw moving node indicator at current position
          if (curvedValue > 0.01 && curvedValue < 0.99) {
            final currentPos = metrics.getTangentForOffset(
              metrics.length * curvedValue,
            );
            if (currentPos != null) {
              // Draw glow effect (outer ring)
              final glowPaint = Paint()
                ..color =
                    (layoutType == LevelMapLayout.spiral
                            ? const Color(0xFFAB47BC)
                            : const Color(0xFFFE5196))
                        .withValues(alpha: 0.3)
                ..style = PaintingStyle.fill;
              canvas.drawCircle(currentPos.position, 16, glowPaint);

              // Draw middle ring
              final middlePaint = Paint()
                ..color =
                    (layoutType == LevelMapLayout.spiral
                            ? const Color(0xFFAB47BC)
                            : const Color(0xFFFE5196))
                        .withValues(alpha: 0.6)
                ..style = PaintingStyle.fill;
              canvas.drawCircle(currentPos.position, 10, middlePaint);

              // Draw core moving node
              final nodePaint = Paint()
                ..color = Colors.white
                ..style = PaintingStyle.fill;
              canvas.drawCircle(currentPos.position, 6, nodePaint);

              // Add sparkle effect (small ring)
              final sparklePaint = Paint()
                ..color = Colors.white.withValues(alpha: 0.8)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2;
              canvas.drawCircle(currentPos.position, 8, sparklePaint);
            }
          }
        } catch (e) {
          // Fallback if metrics fail
          if (animationValue > 0.5) canvas.drawPath(path, activePaint);
        }
      }
    }
  }

  Offset _getOffset(int index, double sectionWidth) {
    if (layoutType == LevelMapLayout.timeline) {
      // Vertical Line on the left
      return Offset(60, (index * spacingY) + 20 + (nodeSize / 2));
    }

    final row = index ~/ crossAxisCount;
    final isRowEven = row % 2 == 0;
    int col = index % crossAxisCount;
    if (!isRowEven) col = (crossAxisCount - 1) - col;

    final dx = (col * sectionWidth) + (sectionWidth / 2);
    final dy = (row * spacingY) + 20 + (nodeSize / 2);
    return Offset(dx, dy);
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.completedIndex != completedIndex ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.isDark != isDark;
  }
}
