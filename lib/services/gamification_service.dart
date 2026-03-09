import 'package:flutter/material.dart';
import 'package:gravity_app/services/data_service.dart';

// Simple model for a Badge
class GameBadge {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  GameBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class GamificationService {
  final DataService _dataService = DataService();

  // Defined Badges
  static final List<GameBadge> allBadges = [
    GameBadge(
      id: 'newbie',
      name: 'Newcomer',
      description: 'Complete your first lesson or game.',
      icon: Icons.star_border,
      color: Colors.blue,
    ),
    GameBadge(
      id: 'streak_3',
      name: 'On Fire',
      description: 'Reach a 3-step streak.',
      icon: Icons.local_fire_department,
      color: Colors.orange,
    ),
    GameBadge(
      id: 'streak_7',
      name: 'Week Warrior',
      description: 'Reach a 7-step streak.',
      icon: Icons.calendar_today,
      color: Colors.redAccent,
    ),
    GameBadge(
      id: 'level_5',
      name: 'High Five',
      description: 'Reach Level 5.',
      icon: Icons.looks_5,
      color: Colors.purple,
    ),
    GameBadge(
      id: 'level_10',
      name: 'Big 10',
      description: 'Reach Level 10.',
      icon: Icons.looks_one,
      color: Colors.amber,
    ),
    GameBadge(
      id: 'vocab_master',
      name: 'Vocab Pro',
      description: 'Score 100 in Word Race.',
      icon: Icons.text_fields,
      color: Colors.green,
    ),
  ];

  // --- XP & Leveling ---

  Future<void> addXp(int amount, BuildContext context) async {
    bool leveledUp = await _dataService.addXp(amount);
    if (!context.mounted) return;
    if (leveledUp) {
      _showLevelUpDialog(context);
    }
    _checkMilestones(context);
  }

  Future<void> _showLevelUpDialog(BuildContext context) async {
    final progress = await _dataService.getUserLevelData();
    if (!context.mounted) return;
    int level = progress['level']!;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_circle_up_rounded,
              size: 80,
              color: Color(0xFFFFD700),
            ),
            const SizedBox(height: 16),
            Text(
              "LEVEL UP!",
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You are now Level $level",
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Awesome!",
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  // --- Level streak management ---

  // Call this whenever a stage-level milestone is completed.
  Future<void> updateStageStreak(BuildContext context) async {
    await _dataService.updateStreak();

    // Check streak badges.
    int streak = await _dataService.getStreak();
    if (!context.mounted) return;
    if (streak == 3) {
      await unlockBadge('streak_3', context);
      if (!context.mounted) return;
    }
    if (streak == 7) await unlockBadge('streak_7', context);
  }

  // Backward compatibility for older call sites.
  Future<void> updateDailyStreak(BuildContext context) =>
      updateStageStreak(context);

  // --- Badges ---

  Future<void> unlockBadge(String badgeId, BuildContext context) async {
    bool isNew = await _dataService.unlockBadge(badgeId);
    if (!context.mounted) return;
    if (isNew) {
      GameBadge? badge = allBadges.firstWhere(
        (b) => b.id == badgeId,
        orElse: () => allBadges[0],
      ); // safety
      if (badge.id == badgeId) {
        _showBadgeSnackBar(context, badge);
      }
    }
  }

  void _showBadgeSnackBar(BuildContext context, GameBadge badge) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colorScheme.surfaceContainerHigh,
        content: Row(
          children: [
            Icon(badge.icon, color: badge.color),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Badge Unlocked!",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  badge.name,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<List<GameBadge>> getMyBadges() async {
    List<String> unlockedIds = await _dataService.getUnlockedBadges();
    return allBadges.where((b) => unlockedIds.contains(b.id)).toList();
  }

  Future<void> _checkMilestones(BuildContext context) async {
    final progress = await _dataService.getUserLevelData();
    if (!context.mounted) return;
    int level = progress['level']!;

    if (level >= 5) {
      await unlockBadge('level_5', context);
      if (!context.mounted) return;
    }
    if (level >= 10) await unlockBadge('level_10', context);
  }
}
