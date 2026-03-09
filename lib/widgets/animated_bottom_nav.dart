import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/widgets/custom_animations.dart';

class Animated3DBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String role;
  final bool isLocked;
  final bool showMastery;
  final String studentPlanLabel;
  final GlobalKey? keyDashboard;
  final GlobalKey? keyDailyTasks;
  final GlobalKey? keyMastery;
  final GlobalKey? keySettings;

  const Animated3DBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.role = 'student',
    this.isLocked = false,
    this.showMastery = false,
    this.studentPlanLabel = 'Tasks',
    this.keyDashboard,
    this.keyDailyTasks,
    this.keyMastery,
    this.keySettings,
  });

  @override
  State<Animated3DBottomNav> createState() => _Animated3DBottomNavState();
}

class _Animated3DBottomNavState extends State<Animated3DBottomNav> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // Define items based on role
    final isTeacher = widget.role == 'teacher';
    final showMastery = widget.showMastery && !isTeacher;
    final int settingsIndex = isTeacher ? 3 : (showMastery ? 3 : 2);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navBackground = isDark
        ? const Color(0xFF030305).withValues(alpha: 0.9)
        : colorScheme.surface.withValues(alpha: 0.98);
    final topBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : colorScheme.outlineVariant.withValues(alpha: 0.75);
    final shadowColor = colorScheme.shadow.withValues(
      alpha: isDark ? 0.3 : 0.1,
    );

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Container(
        height: 64 + bottomInset,
        padding: EdgeInsets.only(bottom: bottomInset, top: 4),
        decoration: BoxDecoration(
          color: navBackground,
          border: Border(top: BorderSide(color: topBorderColor)),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              0,
              "Dashboard",
              customIcon: AnimatedDashboardIcon(
                isSelected: widget.currentIndex == 0,
              ),
              itemKey: widget.keyDashboard,
            ),

            if (isTeacher) ...[
              // Teachers: Standard Scale Animation (or custom if we had)
              _buildNavItem(1, "Students", icon: Icons.people_rounded),
              _buildNavItem(2, "Library", icon: Icons.library_books_rounded),
            ] else ...[
              _buildNavItem(
                1,
                widget.studentPlanLabel,
                customIcon: AnimatedTasksIcon(
                  isSelected: widget.currentIndex == 1,
                ),
                itemKey: widget.keyDailyTasks,
              ),
              if (showMastery)
                _buildNavItem(
                  2,
                  "Mastery",
                  customIcon: AnimatedMasteryLoop(
                    isSelected: widget.currentIndex == 2,
                  ),
                  itemKey: widget.keyMastery,
                ),
            ],

            _buildNavItem(
              settingsIndex,
              "Settings",
              customIcon: AnimatedSettingsIcon(
                isSelected: widget.currentIndex == settingsIndex,
              ),
              itemKey: widget.keySettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String label, {
    IconData? icon,
    Widget? customIcon,
    GlobalKey? itemKey,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bool isSelected = widget.currentIndex == index;
    final bool isGreyed = widget.isLocked && index != 0;
    final selectedColor = colorScheme.primary;
    final unselectedColor = isDark
        ? Colors.white38
        : colorScheme.onSurfaceVariant;

    return GestureDetector(
      key: itemKey,
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isGreyed ? 0.3 : 1.0,
        child: SizedBox(
          width: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              customIcon ??
                  TweenAnimationBuilder<Color?>(
                    duration: const Duration(milliseconds: 300),
                    tween: ColorTween(
                      begin: unselectedColor,
                      end: isSelected ? selectedColor : unselectedColor,
                    ),
                    builder: (context, color, child) {
                      return Icon(icon ?? Icons.error, color: color, size: 24)
                          .animate(target: isSelected ? 1 : 0)
                          .moveY(
                            end: -2,
                            duration: 300.ms,
                            curve: Curves.easeOut,
                          );
                    },
                  ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: isSelected ? selectedColor : unselectedColor,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'Inter',
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
