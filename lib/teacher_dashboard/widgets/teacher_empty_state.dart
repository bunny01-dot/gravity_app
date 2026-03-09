import 'package:flutter/material.dart';

class TeacherEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onRefresh;
  final VoidCallback onFindMissing;

  const TeacherEmptyState({
    super.key,
    required this.icon,
    required this.message,
    required this.onRefresh,
    required this.onFindMissing,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: onSurface.withValues(alpha: 0.34)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh List"),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onFindMissing,
            icon: const Icon(Icons.search_off_rounded, size: 18),
            label: const Text("Find Missing Student (Debug)"),
            style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
          ),
        ],
      ),
    );
  }
}
