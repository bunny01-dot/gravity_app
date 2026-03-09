import 'package:flutter/material.dart';

class LanguageToggleIcon extends StatelessWidget {
  final String language;
  final bool isActive;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const LanguageToggleIcon({
    super.key,
    required this.language,
    required this.isActive,
    this.size = 16,
    this.activeColor,
    this.inactiveColor,
  });

  String _glyphFor(String _) => '\u0B85';

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (activeColor ?? Theme.of(context).colorScheme.secondary)
        : (inactiveColor ?? Colors.white54);

    return Text(
      _glyphFor(language),
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: size,
      ),
    );
  }
}
