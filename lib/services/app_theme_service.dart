import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeService {
  static const String _themeModePreferenceKey = 'app_theme_mode';
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<void> loadThemeModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_themeModePreferenceKey);
      final resolvedMode = _themeModeFromRaw(raw);
      themeModeNotifier.value = resolvedMode;
      if (raw == null || raw.isEmpty) {
        await prefs.setString(
          _themeModePreferenceKey,
          _themeModeToRaw(ThemeMode.system),
        );
      }
    } catch (_) {
      themeModeNotifier.value = ThemeMode.system;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    if (themeModeNotifier.value != mode) {
      themeModeNotifier.value = mode;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModePreferenceKey, _themeModeToRaw(mode));
    } catch (_) {}
  }

  static ThemeMode _themeModeFromRaw(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToRaw(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
