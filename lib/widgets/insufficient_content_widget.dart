import 'package:flutter/material.dart';

class InsufficientContentWidget extends StatelessWidget {
  final VoidCallback? onGoToDailyTasks;

  const InsufficientContentWidget({super.key, this.onGoToDailyTasks});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_clock_rounded,
              size: 80,
              color: Colors.white24,
            ),
            const SizedBox(height: 24),
            const Text(
              "Not enough learned words yet.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Complete todays learning to unlock this game.",
              style: TextStyle(color: Colors.white54, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                if (onGoToDailyTasks != null) {
                  onGoToDailyTasks!();
                } else {
                  // Default navigation if not provided, assuming typical app structure
                  // Popping back to home is usually safe
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text("Go to Daily Tasks"),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4FACFE),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
