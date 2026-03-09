import 'package:flutter/material.dart';
import 'package:gravity_app/core/services/leaderboard_service.dart';

class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  final LeaderboardService _leaderboardService = LeaderboardService();

  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    final data = await _leaderboardService.getGlobalLeaderboard();
    if (mounted) {
      setState(() {
        _leaderboard = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (_leaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 60,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "No champions yet.\nBe the first!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _fetchLeaderboard,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLeaderboard,
      color: colorScheme.primary,
      backgroundColor: isDark
          ? colorScheme.surfaceContainerHigh
          : colorScheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _leaderboard.length,
        itemBuilder: (context, index) {
          final entry = _leaderboard[index];
          final isMe = entry['isMe'] == true;

          final rank = index + 1;
          Color? rankColor;
          if (rank == 1) {
            rankColor = const Color(0xFFFFD700);
          } else if (rank == 2) {
            rankColor = const Color(0xFFC0C0C0);
          } else if (rank == 3) {
            rankColor = const Color(0xFFCD7F32);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe
                  ? colorScheme.primaryContainer.withValues(alpha: 0.32)
                  : (isDark
                        ? colorScheme.surfaceContainerHigh
                        : colorScheme.surface),
              borderRadius: BorderRadius.circular(12),
              border: isMe
                  ? Border.all(color: colorScheme.primary)
                  : Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
            ),
            child: Row(
              children: [
                if (rankColor != null)
                  Icon(Icons.emoji_events_rounded, color: rankColor, size: 28)
                else
                  SizedBox(
                    width: 28,
                    child: Text(
                      "#$rank",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                CircleAvatar(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  backgroundImage:
                      entry['photo_url'] != null &&
                          entry['photo_url'].isNotEmpty
                      ? NetworkImage(entry['photo_url'])
                      : null,
                  radius: 20,
                  child:
                      (entry['photo_url'] == null || entry['photo_url'].isEmpty)
                      ? Text(
                          entry['name'][0].toUpperCase(),
                          style: TextStyle(color: colorScheme.onSurface),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry['name'] ?? 'Learner',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: isMe
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FACFE).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${entry['xp']} XP",
                    style: const TextStyle(
                      color: Color(0xFF4FACFE),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
