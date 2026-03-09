import 'package:flutter/material.dart';

class TeacherPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const TeacherPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E2C)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: child,
    );
  }
}
