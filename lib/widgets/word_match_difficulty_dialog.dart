import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/analytics_service.dart';

/// ISSUE #3 FIX: Difficulty Selection Dialog for Word Match
/// Shows before starting Word Match game with 3 difficulty options
class WordMatchDifficultyDialog extends StatefulWidget {
  final String masteryTitle;

  const WordMatchDifficultyDialog({
    super.key,
    this.masteryTitle = 'Word Match',
  });

  @override
  State<WordMatchDifficultyDialog> createState() =>
      _WordMatchDifficultyDialogState();
}

class _WordMatchDifficultyDialogState extends State<WordMatchDifficultyDialog> {
  String _selectedDifficulty = 'Easy'; // Default to Easy

  @override
  void initState() {
    super.initState();
    _loadLastDifficulty();
  }

  Future<void> _loadLastDifficulty() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('word_match_difficulty') ?? 'Easy';
    if (mounted) {
      setState(() {
        _selectedDifficulty = saved;
      });
    }
  }

  Future<void> _saveDifficulty(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('word_match_difficulty', difficulty);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E2C)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.masteryTitle,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select Difficulty',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // Easy
            _buildDifficultyOption(
              'Easy',
              '2  2 (4 tiles)',
              'Perfect for beginners',
              Colors.greenAccent,
              Icons.child_care_rounded,
            ),
            const SizedBox(height: 12),

            // Medium
            _buildDifficultyOption(
              'Medium',
              '3  3 (9 tiles)',
              'Balanced challenge',
              Colors.orangeAccent,
              Icons.emoji_events_rounded,
            ),
            const SizedBox(height: 12),

            // Hard
            _buildDifficultyOption(
              'Hard',
              '4  4 (16 tiles)',
              'Expert level',
              Colors.redAccent,
              Icons.whatshot_rounded,
            ),

            const SizedBox(height: 24),

            // Start button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await _saveDifficulty(_selectedDifficulty);
                  AnalyticsService().logEvent('word_match_difficulty_selected');
                  if (context.mounted) {
                    Navigator.pop(context, _selectedDifficulty);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Game',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(
    String difficulty,
    String gridInfo,
    String description,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bool isSelected = _selectedDifficulty == difficulty;

    return InkWell(
      onTap: () => setState(() => _selectedDifficulty = difficulty),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.45,
                      )),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : colorScheme.outlineVariant.withValues(alpha: 0.55),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        difficulty,
                        style: TextStyle(
                          color: isSelected ? color : colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        gridInfo,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24)
            else
              Icon(
                Icons.circle_outlined,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
