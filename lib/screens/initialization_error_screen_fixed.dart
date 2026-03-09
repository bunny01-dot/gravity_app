import 'package:flutter/material.dart';

class InitializationErrorScreen extends StatelessWidget {
  const InitializationErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF030305)
          : theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF5252),
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                'Initialization Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We encountered a problem while starting the application. Please check your internet connection and restart the app.',
                style: TextStyle(
                  fontSize: 16,
                  color: onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
