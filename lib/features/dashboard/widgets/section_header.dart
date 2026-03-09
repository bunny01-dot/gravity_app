import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;

  const SectionHeader({super.key, required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color ?? colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
