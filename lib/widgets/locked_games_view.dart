import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/tutorial_service.dart';
import 'package:gravity_app/utils/tutorial_helper.dart';
import 'package:gravity_app/services/analytics_service.dart';

class LockedGamesView extends StatefulWidget {
  final VoidCallback? onGoToDailyTasks;

  const LockedGamesView({super.key, this.onGoToDailyTasks});

  @override
  State<LockedGamesView> createState() => _LockedGamesViewState();
}

class _LockedGamesViewState extends State<LockedGamesView> {
  final GlobalKey _lockIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Log analytics when locked games view is shown
    AnalyticsService().logEvent('games_blocked_view_shown');

    // Tutorial #3: Games Locked - Show why games are locked
    _showGamesLockedTutorialIfNeeded();
  }

  Future<void> _showGamesLockedTutorialIfNeeded() async {
    // Wait for first frame to render
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final shouldShow = await TutorialService()
          .shouldShowGamesLockedTutorial();

      if (shouldShow && mounted && !TutorialHelper.isShowingTutorial) {
        // Small delay to ensure layout is complete
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        TutorialHelper.showTutorial(
          context: context,
          targetKey: _lockIconKey,
          title: "Games are Locked",
          message:
              "Games unlock automatically after you finish today's Daily Tasks.",
          accentColor: const Color(0xFFFF9F43),
          alignment: Alignment.center,
          onDismiss: () {
            TutorialService().markGamesLockedTutorialSeen();
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Display locked games message without background overlay
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                key: _lockIconKey, // GlobalKey for Tutorial #3 targeting
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.7,
                        ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 64,
                  color: colorScheme.onSurfaceVariant,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 2.seconds,
              ),
          const SizedBox(height: 32),
          Text(
            "Games Locked",
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Complete your Daily Tasks to unlock the Arcade!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "You must complete all 3 tasks below:",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          // Checklist visual
          _buildRequirementRow(Icons.menu_book_rounded, "Daily Vocabulary"),
          const SizedBox(height: 12),
          _buildRequirementRow(Icons.change_circle_rounded, "Daily Verbs"),
          const SizedBox(height: 12),
          _buildRequirementRow(Icons.mic_rounded, "Daily Pronunciation"),

          const SizedBox(height: 48),
          FilledButton.icon(
            onPressed: () {
              if (widget.onGoToDailyTasks != null) {
                widget.onGoToDailyTasks!();
              } else {
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text(
              "Go to Daily Tasks",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4FACFE)),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
        ),
      ],
    );
  }
}
