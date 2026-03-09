import 'package:flutter/material.dart';

/// Centralized Black Hole icon widget to ensure consistency across the app.
///
/// Used in:
/// - Dashboard (top app bar)
/// - Mastery Page
/// - Daily Task cards
///
/// Ensures same icon, size, color, and glow effect everywhere.
class BlackholeIcon extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  final bool showGlow;
  final String? tooltip;
  final Color color;
  final Color? glowColor;

  const BlackholeIcon({
    super.key,
    this.size = 24,
    this.onTap,
    this.showGlow = true,
    this.tooltip,
    this.color = Colors.white,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.cyclone, color: color, size: size);

    final glowDecoration = showGlow
        ? BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (glowColor ?? const Color(0xFF9E86FF)).withValues(alpha: 0.6),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          )
        : null;

    if (onTap == null) {
      return showGlow
          ? Container(decoration: glowDecoration, child: icon)
          : icon;
    }

    return IconButton(
      onPressed: onTap,
      tooltip: tooltip ?? 'Black Hole (Difficult Words)',
      icon: showGlow
          ? Container(decoration: glowDecoration, child: icon)
          : icon,
    );
  }
}
