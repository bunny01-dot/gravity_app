import 'package:flutter/material.dart';
import '../models/lesson_config.dart';

/// Reusable widget for displaying a tense sub-menu (e.g., Present Tense varieties)
class TenseSubMenu extends StatelessWidget {
  final LessonGroup lessonGroup;
  final Future<void> Function(String lessonId) onLessonCompleted;

  const TenseSubMenu({
    super.key,
    required this.lessonGroup,
    required this.onLessonCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              '${lessonGroup.title.split(' - ').last} Master Class',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lessonGroup.subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Lesson Options
            ...lessonGroup.lessons.map(
              (lesson) =>
                  _buildLessonOption(context, lesson, lessonGroup.themeColor),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonOption(
    BuildContext context,
    LessonConfig lesson,
    Color themeColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () async {
          // FORCE UNLOCK (Removed null check)
          // Navigator.pop(context); // Don't close bottom sheet to preserve context
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => lesson.screenBuilder()),
          );
          await onLessonCompleted(lesson.id);
        },
        leading: CircleAvatar(
          backgroundColor: themeColor.withValues(alpha: 0.2),
          child: Icon(
            lesson.icon,
            color: themeColor,
            size: 20,
          ),
        ),
        title: Text(
          lesson.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          lesson.subtitle,
          style: TextStyle(
            color: Colors.white70,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: themeColor, size: 16),
      ),
    );
  }
}
