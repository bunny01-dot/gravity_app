import 'package:flutter/material.dart';

/// Configuration for a single lesson
class LessonConfig {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isUnlocked;
  final Widget Function() screenBuilder;
  final String? progressKey; // For tracking completion

  const LessonConfig({
    required this.id,
    required this.title,
    required this.subtitle,
    this.icon = Icons.check_circle_outline,
    this.isUnlocked = true,
    required this.screenBuilder,
    this.progressKey,
  });

  /// Create a locked lesson placeholder
  factory LessonConfig.locked({
    required String id,
    required String title,
    String subtitle = "Coming Soon",
  }) {
    return LessonConfig(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: Icons.lock_outline,
      isUnlocked: false,
      screenBuilder: () => const Scaffold(body: Center(child: Text('Locked'))),
    );
  }
}

/// Group of related lessons (e.g., all Present Tense variations)
class LessonGroup {
  final String id;
  final String title;
  final String subtitle;
  final Color themeColor;
  final List<LessonConfig> lessons;

  const LessonGroup({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.themeColor,
    required this.lessons,
  });
}
