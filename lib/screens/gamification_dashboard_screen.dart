import 'package:flutter/material.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/gamification_service.dart';
import 'package:gravity_app/services/xp_reward_policy.dart';
import 'package:gravity_app/features/gamification/widgets/leaderboard_tab.dart';

class GamificationDashboardScreen extends StatefulWidget {
  const GamificationDashboardScreen({super.key});

  @override
  State<GamificationDashboardScreen> createState() =>
      _GamificationDashboardScreenState();
}

class _GamificationDashboardScreenState
    extends State<GamificationDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DataService _dataService = DataService();
  final GamificationService _gamificationService = GamificationService();

  Map<String, int> _userLevelData = {
    'level': 1,
    'currentXp': 0,
    'requiredXp': XpRewardPolicy.requiredXpForLevel(1),
  };
  int _streak = 0;
  List<GameBadge> _myBadges = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final levelData = await _dataService.getUserLevelData();
    final streak = await _dataService.getStreak();
    final badges = await _gamificationService.getMyBadges();

    if (mounted) {
      setState(() {
        _userLevelData = levelData;
        _streak = streak;
        _myBadges = badges;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("My Achievements"),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.onSurface,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: "Progress"),
            Tab(text: "Badges"),
            Tab(text: "Leaderboard"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProgressTab(),
          _buildBadgesTab(),
          const LeaderboardTab(),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    int level = _userLevelData['level']!;
    int xp = _userLevelData['currentXp']!;
    int nextXp = _userLevelData['requiredXp']!;
    double progress = (xp / nextXp).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Level Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text(
                  "CURRENT LEVEL",
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  level.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(
                      Colors.yellowAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "$xp / $nextXp XP",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const SizedBox(height: 24),

          // Streak Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.orange,
                  size: 48,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Learning Streak",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      "$_streak Steps",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: GamificationService.allBadges.length,
      itemBuilder: (context, index) {
        final badge = GamificationService.allBadges[index];
        final isUnlocked = _myBadges.any((b) => b.id == badge.id);

        return Container(
          decoration: BoxDecoration(
            color: isUnlocked
                ? badge.color.withValues(alpha: 0.1)
                : (isDark
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surface),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnlocked
                  ? badge.color
                  : colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                badge.icon,
                size: 40,
                color: isUnlocked ? badge.color : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                badge.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isUnlocked
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (!isUnlocked)
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Icon(Icons.lock, size: 12, color: Colors.grey),
                ),
            ],
          ),
        );
      },
    );
  }
}
