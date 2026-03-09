import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DailyChecklist extends StatelessWidget {
  final GlobalKey? tutorialKey;
  final bool isVocabDone;
  final bool isVerbsDone;
  final bool isSpeakingDone; // Fix lint: was unused or implicitly used
  final bool isQuizDone;
  final String? dayLabel;

  const DailyChecklist({
    super.key,
    this.tutorialKey,
    required this.isVocabDone,
    required this.isVerbsDone,
    required this.isSpeakingDone,
    required this.isQuizDone,
    this.dayLabel,
    this.onVocabTap,
    this.onVerbsTap,
    this.onSpeakingTap,
    this.onQuizTap,
  });

  final VoidCallback? onVocabTap;
  final VoidCallback? onVerbsTap;
  final VoidCallback? onSpeakingTap;
  final VoidCallback? onQuizTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Calculate progress
    int total = 4;
    int done = 0;
    if (isQuizDone) done++;
    if (isVocabDone) done++;
    if (isVerbsDone) done++;
    if (isSpeakingDone) done++;

    double progress = done / total;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          key: tutorialKey,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.88)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: isDark ? 0.26 : 0.1,
                ),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
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
                          color: colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (dayLabel != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(
                              alpha: isDark ? 0.4 : 0.7,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primary.withValues(
                                alpha: isDark ? 0.5 : 0.35,
                              ),
                            ),
                          ),
                          child: Text(
                            dayLabel!,
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
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
              const SizedBox(height: 20),
              // Glowy Glassy Progress Bar
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        )
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: progress == 0 ? 0.01 : progress,
                      child:
                          Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFFFA500),
                                    ],
                                  ),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .shimmer(
                                duration: 700.ms,
                                delay: 5.seconds,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Icons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ChecklistItem(
                    icon: Icons.history_edu_rounded,
                    isDone: isQuizDone,
                    label: "Quiz",
                    onTap: onQuizTap,
                  ),
                  _ChecklistItem(
                    icon: Icons.menu_book_rounded,
                    isDone: isVocabDone,
                    label: "Vocab",
                    onTap: onVocabTap,
                  ),
                  _ChecklistItem(
                    icon: Icons.change_circle_rounded,
                    isDone: isVerbsDone,
                    label: "Verbs",
                    onTap: onVerbsTap,
                  ),
                  _ChecklistItem(
                    icon: Icons.mic_rounded,
                    isDone: isSpeakingDone,
                    label: "Speak",
                    onTap: onSpeakingTap,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Golden Badge - Positioned Absolutely (Restored)
        Positioned(
          top: -10,
          right: -5,
          child:
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (progress >= 1.0)
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.black87,
                            size: 16,
                          ),
                        if (progress >= 1.0) const SizedBox(width: 4),
                        Text(
                          "${(progress * 100).toInt()}%",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(target: progress >= 1.0 ? 1 : 0)
                  .scale(curve: Curves.elasticOut, duration: 800.ms),
        ),
      ],
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final IconData icon;
  final bool isDone;
  final String label;

  const _ChecklistItem({
    required this.icon,
    required this.isDone,
    required this.label,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isDone
                  ? const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isDone
                  ? null
                  : (isDark
                        ? colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.6,
                          )
                        : colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.75,
                          )),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone
                    ? Colors.transparent
                    : colorScheme.outlineVariant.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            child: Icon(
              isDone ? Icons.check_rounded : icon,
              color: isDone ? Colors.black87 : colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDone
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
