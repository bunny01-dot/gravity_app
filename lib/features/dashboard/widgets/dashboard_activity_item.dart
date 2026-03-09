import 'package:flutter/material.dart';

class DashboardActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLocked;
  final Widget? trailingBadge;

  const DashboardActivityItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.isLocked = false,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.88)
        : colorScheme.surface;
    final titleColor = colorScheme.onSurface;
    final subtitleColor = colorScheme.onSurfaceVariant;

    final safeTitle = _sanitizeCardText(title);
    final safeSubtitle = _sanitizeCardText(subtitle);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.16 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_rounded : icon,
                    color: color,
                    size: isLocked ? 26 : 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        safeTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        safeSubtitle,
                        style: TextStyle(color: subtitleColor, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (trailingBadge != null) ...[
                  trailingBadge!,
                  const SizedBox(width: 12),
                ],
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: subtitleColor.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _sanitizeCardText(String input) {
  if (input.isEmpty) return '';

  final ascii = input.replaceAll(RegExp(r'[^\x20-\x7E\n]'), '');
  final normalizedLines = ascii
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trimRight())
      .toList();
  return normalizedLines.join('\n').trim();
}
