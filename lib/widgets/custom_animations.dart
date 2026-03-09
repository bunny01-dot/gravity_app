import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';

// --- Realistic Ding Bell ---
// A bell that pivots sharply like being struck, then settles.
class RingingBellIcon extends StatefulWidget {
  final VoidCallback? onPressed;
  final int? unreadCount;

  const RingingBellIcon({super.key, this.onPressed, this.unreadCount});

  @override
  State<RingingBellIcon> createState() => _RingingBellIconState();
}

class _RingingBellIconState extends State<RingingBellIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Quicker, sharper sound
    );

    if (_hasUnread) {
      _startDingLoop();
    }
  }

  void _startDingLoop() async {
    while (mounted && _hasUnread) {
      await Future.delayed(const Duration(seconds: 4));
      if (mounted && _hasUnread) {
        await _controller.forward(from: 0);
      }
    }
  }

  bool get _hasUnread => widget.unreadCount != null && widget.unreadCount! > 0;

  @override
  void didUpdateWidget(covariant RingingBellIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newCount = widget.unreadCount ?? 0;
    final oldCount = oldWidget.unreadCount ?? 0;
    if (newCount > oldCount) {
      // Immediate ding for new notification
      _controller.forward(from: 0);
    }

    // Manage loop state
    if (newCount > 0 && oldCount == 0) {
      _startDingLoop();
    } else if (newCount == 0 && oldCount > 0) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bellColor = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: () {
        _controller.forward(from: 0);
        widget.onPressed?.call();
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // The Bell - Pivoting from Top Center usually looks most real,
          // but stock Icon pivots from center. We simulates top pivot by shaking.
          // Ding effect: Sharp tilt one way, then decay.
          Icon(
                Icons
                    .notifications_none_rounded, // Use outline for sharper look
                color: bellColor,
                size: 28,
              )
              .animate(controller: _controller, autoPlay: false)
              .shake(
                duration: 800.ms,
                hz: 4, // Fast shake = ding
                rotation: 0.25, // Significant tilt
                curve: Curves.easeOutQuad,
              ),

          // Badge - Realistic Pop
          if (_hasUnread)
            Positioned(
              right: -2,
              top: -2,
              child:
                  Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4757),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFF4757,
                              ).withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            (widget.unreadCount ?? 0) > 9
                                ? '9+'
                                : (widget.unreadCount ?? 0).toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 1.5.seconds,
                        curve: Curves.easeInOut,
                      ),
            ),
        ],
      ),
    );
  }
}

// --- Dashboard - Magnetic Snap ---
// The squares start "exploded" and chaos-rotated, then magnetically snap into a perfect grid.
// --- Dashboard - Magnetic Snap ---
// The squares start "exploded" and chaos-rotated, then magnetically snap into a perfect grid.
class AnimatedDashboardIcon extends StatelessWidget {
  final bool isSelected;
  const AnimatedDashboardIcon({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    // When unselected, show a tidy static grid (so it looks good).
    // When selected, play the "Assemble" animation.
    if (!isSelected) {
      return SizedBox(
        width: 24,
        height: 24,
        child: Stack(
          children: [
            _staticSquare(Alignment.topLeft, color),
            _staticSquare(Alignment.topRight, color),
            _staticSquare(Alignment.bottomLeft, color),
            _staticSquare(Alignment.bottomRight, color),
          ],
        ),
      );
    }

    // Selected: Parts fly in and fix together
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          _animSquare(
            Alignment.topLeft,
            color,
            const Offset(-1, -1),
            delay: 0.ms,
          ),
          _animSquare(
            Alignment.topRight,
            color,
            const Offset(1, -1),
            delay: 50.ms,
          ),
          _animSquare(
            Alignment.bottomLeft,
            color,
            const Offset(-1, 1),
            delay: 100.ms,
          ),
          _animSquare(
            Alignment.bottomRight,
            color,
            const Offset(1, 1),
            delay: 150.ms,
          ),
        ],
      ),
    );
  }

  Widget _staticSquare(Alignment align, Color color) {
    return Align(
      alignment: align,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _animSquare(
    Alignment align,
    Color color,
    Offset dir, {
    required Duration delay,
  }) {
    return Align(
          alignment: align,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )
        .animate(delay: delay) // Staggered entrance
        .move(
          begin: Offset(dir.dx * 8, dir.dy * 8), // Start from further out
          end: Offset.zero,
          duration: 600.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 100.ms)
        .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1));
  }
}

// --- Tasks - Drawing Checkmark ---
// A clipboard appears, and the checkmark is "drawn" onto it.
// --- Tasks - The "Stamp" ---
// Checkmark slams down like a stamp.
class AnimatedTasksIcon extends StatelessWidget {
  final bool isSelected;
  const AnimatedTasksIcon({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    Widget clipboard = Icon(Icons.assignment_outlined, color: color, size: 24);

    // If selected, we animate the clipboard reacting to the stamp
    if (isSelected) {
      clipboard = clipboard.animate().shake(
        delay: 200.ms,
        duration: 300.ms,
        hz: 4,
        curve: Curves.easeInOut,
      ); // Shake exactly when stamp lands
    }

    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          clipboard,

          // The Stamp (Checkmark)
          if (isSelected)
            Positioned(
              child:
                  const Icon(Icons.check, size: 28, color: Colors.greenAccent)
                      .animate()
                      .scale(
                        begin: const Offset(3.0, 3.0), // Start HUGE opacity 0
                        end: const Offset(1.0, 1.0),
                        duration: 250.ms,
                        curve: Curves.easeOutBack, // Slam effect
                      )
                      .fadeIn(duration: 100.ms),
            ),
        ],
      ),
    );
  }
}

// --- Mastery - The "Toss" ---
// Graduation cap tosses up in the air and spins.
// --- Mastery - The "Happy Hop" ---
// The graduation hat sets itself, hops up happily, wiggles, and lands.
class AnimatedMasteryLoop extends StatelessWidget {
  final bool isSelected;
  const AnimatedMasteryLoop({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Icon(Icons.school, color: color, size: 26)
        .animate(target: isSelected ? 1 : 0)
        // Anticipation/Settle logic: Move up slightly when selected, down when unselected
        .moveY(
          begin: 0,
          end: -4, // Stay slightly elevated when selected
          duration: 400.ms,
          curve: Curves.easeOutBack,
        )
        // Happy "Pop" scale
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.15, 1.15),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        )
        // Success Wiggle (Only plays when forward to 1)
        .shake(
          delay: 200.ms,
          duration: 400.ms,
          hz: 3,
          rotation: 0.15,
          curve: Curves.easeInOut,
        );
  }
}

// --- Settings - Smooth Spin ---
// Heavy mechanical spin.
class AnimatedSettingsIcon extends StatelessWidget {
  final bool isSelected;
  const AnimatedSettingsIcon({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    return Icon(Icons.settings, color: color, size: 26)
        .animate(target: isSelected ? 1 : 0)
        .rotate(
          begin: 0,
          end: 0.5,
          duration: 1.seconds,
          curve: Curves.easeOutCubic,
        ); // 180 deg
  }
}

class LevelUpCelebrationOverlay extends StatelessWidget {
  final String levelLabel;

  const LevelUpCelebrationOverlay({super.key, required this.levelLabel});

  @override
  Widget build(BuildContext context) {
    final displayLevel = levelLabel.isEmpty ? 'Advanced' : levelLabel;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            margin: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(0xFF0F172A).withValues(alpha: 0.7),
              border: Border.all(
                color: const Color(0xFF4FACFE).withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4FACFE).withValues(alpha: 0.22),
                  blurRadius: 28,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                      width: 190,
                      height: 190,
                      child: Lottie.asset(
                        'assets/lottie/level_up_celebration.json',
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 250.ms)
                    .scale(
                      begin: const Offset(0.88, 0.88),
                      end: const Offset(1, 1),
                      duration: 350.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 4),
                const Text(
                  "Level Up!",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        "Level: $displayLevel",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 300.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
