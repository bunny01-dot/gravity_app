import 'package:flutter/material.dart';

class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simple placeholder logic for daily challenge
    // In real app, check date and load specific content
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final scaffoldBg = isDark
        ? const Color(0xFF030305)
        : theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Daily Challenge"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 100,
                color: Color(0xFFFFD700),
              ),
              const SizedBox(height: 24),
              Text(
                "Today's Challenge",
                style: TextStyle(
                  color: onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Complete a Quick Quiz to keep your streak alive!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.72),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),

              // Reuse Quiz Battle or similar logic here, or specialized widget
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to specific game or show inline quiz
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Mock Challenge Started!")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    "Start Now",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
