import 'package:flutter/material.dart';
import 'package:gravity_app/widgets/glass_ui.dart';

/// One-time congratulations dialog shown when user completes 90 days.
class ReinforcementModeDialog extends StatelessWidget {
  const ReinforcementModeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const darkBaseTop = Color(0xFF0C1323);
    const darkBaseBottom = Color(0xFF172033);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: GlassPanel(
        borderRadius: BorderRadius.circular(28),
        borderColor: scheme.primary.withValues(alpha: 0.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.16),
              darkBaseTop.withValues(alpha: 0.96),
            ),
            Color.alphaBlend(
              scheme.secondary.withValues(alpha: 0.1),
              darkBaseBottom.withValues(alpha: 0.94),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scheme.primary, scheme.secondary],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.celebration,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Congratulations!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You\'ve completed all 90 days of new learning!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GlassPanel(
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.all(16),
              blurSigma: 14,
              borderColor: Colors.white.withValues(alpha: 0.24),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A2438).withValues(alpha: 0.84),
                  const Color(0xFF111A2B).withValues(alpha: 0.76),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.auto_awesome, color: scheme.primary, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Reinforcement Mode',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'From now on, you\'ll practice and strengthen what you\'ve learned through spaced repetition and review.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlassPanel(
              borderRadius: BorderRadius.circular(14),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              blurSigma: 14,
              borderColor: scheme.primary.withValues(alpha: 0.3),
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.18),
                  scheme.secondary.withValues(alpha: 0.12),
                ],
              ),
              boxShadow: const [],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat(
                    context,
                    '450',
                    'Vocabulary',
                    divider: true,
                    dividerColor: scheme.primary.withValues(alpha: 0.3),
                  ),
                  _buildStat(
                    context,
                    '450',
                    'Verbs',
                    divider: true,
                    dividerColor: scheme.primary.withValues(alpha: 0.3),
                  ),
                  _buildStat(context, '90', 'Days'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GradientActionButton(
                onPressed: () => Navigator.of(context).pop(),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                colors: [scheme.primary, scheme.secondary],
                child: const Text(
                  'Continue Learning',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String value,
    String label, {
    bool divider = false,
    Color? dividerColor,
  }) {
    const primaryText = Colors.white;
    const secondaryText = Colors.white70;

    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
              ],
            ),
          ),
          if (divider)
            Container(
              width: 1,
              height: 30,
              color: dividerColor ?? Colors.white24,
            ),
        ],
      ),
    );
  }

  /// Show the dialog (call this when isReinforcementModeEligible becomes true)
  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ReinforcementModeDialog(),
    );
  }
}
