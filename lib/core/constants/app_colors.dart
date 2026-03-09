import 'package:flutter/material.dart';

/// Centralized color constants for the entire app
/// Use these instead of hardcoded Color values
class AppColors {
  // Prevent instantiation
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF4FACFE);
  static const Color secondary = Color(0xFF00F2FE);
  static const Color accent = Color(0xFFFFD700);
  static const Color purple = Color(0xFF6C63FF);

  // Background Colors
  static const Color backgroundDark = Color(0xFF030305);
  static const Color cardDark = Color(0xFF1E1E2C);
  static const Color cardLight = Color(0xFF2A2A3E);

  // Status Colors
  static const Color success = Colors.greenAccent;
  static const Color error = Colors.redAccent;
  static const Color warning = Colors.orange;
  static const Color info = Color(0xFF6C63FF);

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textTertiary = Colors.white54;
  static const Color textDisabled = Colors.white38;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Helper method to get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
}
