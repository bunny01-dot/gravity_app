import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DailyTaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String animationType;
  final bool isDone;
  final int scorePercentage;
  final VoidCallback onTap;
  final bool showArrow;
  final bool showCompletedLabel;
  final bool showScoreBadge;
  final bool showTickBadgeWhenDone;

  const DailyTaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.animationType,
    required this.isDone,
    required this.scorePercentage,
    required this.onTap,
    this.showArrow = true,
    this.showCompletedLabel = true,
    this.showScoreBadge = true,
    this.showTickBadgeWhenDone = false,
    this.dayLabel,
  });

  final String? dayLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.9)
        : colorScheme.surface;
    final defaultBorderColor = colorScheme.outlineVariant.withValues(
      alpha: 0.45,
    );
    final titleColor = colorScheme.onSurface;
    final subtitleColor = colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDone ? color.withValues(alpha: 0.5) : defaultBorderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDone
                ? color.withValues(alpha: 0.2)
                : colorScheme.shadow.withValues(alpha: isDark ? 0.16 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 28),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(
                          duration: 700.ms,
                          delay: 5.seconds,
                          color: color.withValues(alpha: 0.3),
                        ),
                    const SizedBox(width: 20),
                    // Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 14,
                            ),
                          ),
                          if (isDone && showCompletedLabel) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: color,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Completed",
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Trailing (Score or Arrow)
                    if (isDone && showScoreBadge && scorePercentage > 0)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                            width: 3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "$scorePercentage%",
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (isDone && showTickBadgeWhenDone)
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.18),
                          border: Border.all(
                            color: color.withValues(alpha: 0.55),
                            width: 1.4,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.check_rounded,
                          color: color,
                          size: 20,
                        ),
                      )
                    else if (showArrow)
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: subtitleColor.withValues(alpha: 0.8),
                        size: 16,
                      ),
                  ],
                ),
              ),

              // Day Badge
              if (dayLabel != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      dayLabel!,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }
}
