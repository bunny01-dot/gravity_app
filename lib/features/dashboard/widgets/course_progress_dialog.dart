import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/widgets/modern_glass_dialog.dart';

Future<void> showCourseProgressDialog({
  required BuildContext context,
  required double overallProgress,
  required int completedLessons,
  required int totalLessons,
  required int quizPassed,
  required int quizTotal,
}) async {
  final colorScheme = Theme.of(context).colorScheme;

  showModernDialog(
    context,
    title: "Your Growth",
    content: Column(
      children: [
        Text(
          "This score reflects your mastery of the curriculum.",
          style: TextStyle(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: overallProgress),
          duration: 1.5.seconds,
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => Column(
            children: [
              LinearProgressIndicator(
                value: value,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 8),
              Text(
                "${(value * 100).toInt()}% Complete",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStatRow(
          Icons.check_circle_outline,
          "Lessons Completed",
          "$completedLessons/$totalLessons",
          colorScheme: colorScheme,
        ),
        _buildStatRow(
          Icons.star_outline,
          "Quizzes Passed",
          "$quizPassed/$quizTotal",
          colorScheme: colorScheme,
        ),
      ],
    ),
    primaryButtonText: "Keep Going",
    onPrimaryPressed: () => Navigator.pop(context),
    icon: Icons.auto_graph_rounded,
    accentColor: colorScheme.primary,
  );
}

Widget _buildStatRow(
  IconData icon,
  String label,
  String value, {
  required ColorScheme colorScheme,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
