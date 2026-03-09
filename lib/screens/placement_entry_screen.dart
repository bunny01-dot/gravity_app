import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:gravity_app/screens/placement_quiz_screen.dart';
import 'package:gravity_app/dashboard.dart';
import 'package:gravity_app/widgets/space_dust_background.dart';
import 'package:gravity_app/services/placement_state_service.dart';

///  PLACEMENT ENTRY SCREEN
///
/// Shown on app launch until the placement quiz is completed.
/// Skip only lasts for the current session.
class PlacementEntryScreen extends StatelessWidget {
  const PlacementEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(
                  alpha: isDark ? 0.15 : 0.1,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondary.withValues(
                  alpha: isDark ? 0.1 : 0.08,
                ),
              ),
            ),
          ),

          // Space Dust Particles
          const Positioned.fill(
            child: IgnorePointer(child: SpaceDustBackground()),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset('assets/lottie/Thinking.json', height: 200),
                    const SizedBox(height: 32),
                    Text(
                      'Ready to take a quick evaluation quiz?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This helps us personalize your learning path.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _handleTakeQuiz(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Take Quiz',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _handleSkip(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Skip for Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle "Take Quiz" Action
  void _handleTakeQuiz(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlacementQuizScreen(
          isFirstTime: true, // Flag to indicate this is from entry screen
        ),
      ),
    );
  }

  /// Handle "Skip for Now" Action
  void _handleSkip(BuildContext context) async {
    await PlacementStateService.markSkipped();

    if (context.mounted) {
      // Navigate to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }
}
