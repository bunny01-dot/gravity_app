import 'package:flutter/material.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/xp_reward_policy.dart';

import 'package:gravity_app/screens/gamification_dashboard_screen.dart';

class GamificationHeader extends StatefulWidget {
  const GamificationHeader({super.key});

  @override
  State<GamificationHeader> createState() => _GamificationHeaderState();
}

class _GamificationHeaderState extends State<GamificationHeader> {
  int _level = 1;
  int _currentXp = 0;
  int _requiredXp = XpRewardPolicy.requiredXpForLevel(1);
  int _streak = 0;
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final levelData = await _dataService.getUserLevelData();
    final streak = await _dataService.getStreak();
    if (mounted) {
      setState(() {
        _level = levelData['level']!;
        _currentXp = levelData['currentXp']!;
        _requiredXp = levelData['requiredXp']!;
        _streak = streak;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_currentXp / _requiredXp).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const GamificationDashboardScreen(),
          ),
        ).then((_) => _loadData()); // Refresh on return
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Level Badge
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.purpleAccent, Colors.blueAccent],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                "$_level",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // XP Bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Level $_level",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "$_currentXp / $_requiredXp XP",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF4FACFE),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Streak
            Column(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
                Text(
                  "$_streak",
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}
