import 'package:flutter/material.dart';

class MasteryDifficultyDialog extends StatefulWidget {
  final String title;
  final String initialLevel;
  final String userProficiencyLevel;

  const MasteryDifficultyDialog({
    super.key,
    required this.title,
    this.initialLevel = 'Beginner',
    this.userProficiencyLevel = 'Advanced',
  });

  @override
  State<MasteryDifficultyDialog> createState() =>
      _MasteryDifficultyDialogState();
}

class _MasteryDifficultyDialogState extends State<MasteryDifficultyDialog> {
  late String _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.initialLevel;
  }

  int _getLevelRank(String level) {
    if (level.startsWith('Beginner')) return 0;
    if (level.startsWith('Intermediate')) return 1;
    if (level.startsWith('Advanced')) return 2;
    return 0;
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
              widget.title,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select Proficiency Level',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            _buildOption("Beginner", Colors.greenAccent, Icons.school_rounded),
            const SizedBox(height: 12),
            _buildOption(
              "Intermediate",
              Colors.orangeAccent,
              Icons.trending_up_rounded,
            ),
            const SizedBox(height: 12),
            _buildOption(
              "Advanced",
              Colors.redAccent,
              Icons.rocket_launch_rounded,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context, _selectedLevel);
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
                  'Confirm',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String level, Color color, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // Determine if locked
    final int optionRank = _getLevelRank(level);
    final int userRank = _getLevelRank(widget.userProficiencyLevel);
    final bool isLocked = optionRank > userRank;

    final isSelected = _selectedLevel == level;

    // Grey out if locked
    final Color displayColor = isLocked ? Colors.grey : color;
    final Color textColor = isLocked
        ? Colors.grey
        : (isSelected ? displayColor : colorScheme.onSurface);

    return IgnorePointer(
      ignoring: isLocked,
      child: InkWell(
        onTap: () => setState(() => _selectedLevel = level),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected && !isLocked
                ? displayColor.withValues(alpha: 0.15)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.45,
                        )),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected && !isLocked
                  ? displayColor
                  : colorScheme.outlineVariant.withValues(alpha: 0.55),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isLocked ? Icons.lock_rounded : icon,
                color: isLocked
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                    : displayColor.withValues(alpha: isSelected ? 1.0 : 0.5),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isLocked)
                      Text(
                        "Complete previous levels to unlock",
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected && !isLocked)
                Icon(Icons.check_circle, color: displayColor),
            ],
          ),
        ),
      ),
    );
  }
}
