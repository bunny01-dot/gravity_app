import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/dashboard/widgets/dashboard_stats.dart';

class DashboardProgressCard extends StatefulWidget {
  final Key? containerKey;
  final double progress;
  final int xpLevel;
  final int currentXp;
  final int requiredXp;
  final int totalXp;
  final String? currentDayLabel;
  final bool isQuizDone;
  final bool isVocabDone;
  final bool isVerbsDone;
  final bool isSpeakingDone;

  const DashboardProgressCard({
    super.key,
    this.containerKey,
    required this.progress,
    required this.xpLevel,
    required this.currentXp,
    required this.requiredXp,
    required this.totalXp,
    required this.currentDayLabel,
    required this.isQuizDone,
    required this.isVocabDone,
    required this.isVerbsDone,
    required this.isSpeakingDone,
  });

  @override
  State<DashboardProgressCard> createState() => _DashboardProgressCardState();
}

class _DashboardProgressCardState extends State<DashboardProgressCard> {
  double _animatedXpProgress = 0.0;

  int get _safeRequiredXp => widget.requiredXp <= 0 ? 1 : widget.requiredXp;

  double _targetXpProgress() {
    return (widget.currentXp / _safeRequiredXp).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    // Animate from 0 when dashboard first renders.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _animatedXpProgress = _targetXpProgress();
      });
    });
  }

  @override
  void didUpdateWidget(covariant DashboardProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentXp != widget.currentXp ||
        oldWidget.requiredXp != widget.requiredXp ||
        oldWidget.xpLevel != widget.xpLevel) {
      setState(() {
        _animatedXpProgress = _targetXpProgress();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surface;
    final borderColor = colorScheme.primary.withValues(
      alpha: isDark ? 0.3 : 0.2,
    );
    final titleColor = colorScheme.onSurface;
    final subtitleColor = colorScheme.onSurfaceVariant;

    return Container(
      key: widget.containerKey, // GlobalKey for Tutorial #2 targeting
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        // Removed glow shadow
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Learning Progress",
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.currentDayLabel != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.65,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        widget.currentDayLabel!,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "XP Level ${widget.xpLevel}",
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "${widget.currentXp}/$_safeRequiredXp XP",
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // XP fill bar (animates from 0 on dashboard open and on XP updates)
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.75,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                AnimatedFractionallySizedBox(
                  widthFactor: _animatedXpProgress,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  child:
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                            ],
                          ),
                        ),
                      ).animate().shimmer(
                        duration: 900.ms,
                        color: colorScheme.onPrimary.withValues(alpha: 0.45),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Total XP: ${widget.totalXp}",
            style: TextStyle(
              color: subtitleColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          // Icons Row
          DashboardStatsRow(
            isQuizDone: widget.isQuizDone,
            isVocabDone: widget.isVocabDone,
            isVerbsDone: widget.isVerbsDone,
            isSpeakingDone: widget.isSpeakingDone,
          ),
        ],
      ),
    );
  }
}
