import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardConnectivityCard extends StatelessWidget {
  final bool isOnline;

  const DashboardConnectivityCard({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: Center(
        child:
            Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isOnline
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444))
                            .withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isOnline ? "Back Online" : "No Internet Connection",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                  delay: 5.seconds,
                  duration: 700.ms,
                  color: Colors.white12,
                ),
      ),
    );
  }
}

class DashboardStatsRow extends StatelessWidget {
  final bool isQuizDone;
  final bool isVocabDone;
  final bool isVerbsDone;
  final bool isSpeakingDone;

  const DashboardStatsRow({
    super.key,
    required this.isQuizDone,
    required this.isVocabDone,
    required this.isVerbsDone,
    required this.isSpeakingDone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ChecklistItem(
          icon: Icons.history_edu_rounded,
          isDone: isQuizDone,
          label: "Quiz",
        ),
        _ChecklistItem(
          icon: Icons.menu_book_rounded,
          isDone: isVocabDone,
          label: "Vocab",
        ),
        _ChecklistItem(
          icon: Icons.change_circle_rounded,
          isDone: isVerbsDone,
          label: "Verbs",
        ),
        _ChecklistItem(
          icon: Icons.mic_rounded,
          isDone: isSpeakingDone,
          label: "Speak",
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
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: isDone
                ? const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFA500),
                    ], // Teacher Welcome Gradient (Yellow/Orange)
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isDone
                ? null
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone
                  ? Colors.transparent
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 2,
            ),
            // Removed glow shadow
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
    );
  }
}
