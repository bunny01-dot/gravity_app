import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityRepository {
  static const String activityKey = 'recent_activity_log';
  static const int maxEntries = 20;

  Future<List<String>> logActivity({
    required String title,
    required String subtitle,
    required String iconName,
    required String colorName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(activityKey) ?? [];

    final newLog = {
      'title': title,
      'subtitle': subtitle,
      'icon': iconName,
      'color': colorName,
      'timestamp': DateTime.now().toIso8601String(),
    };

    logs.insert(0, jsonEncode(newLog));
    if (logs.length > maxEntries) logs = logs.sublist(0, maxEntries);

    await prefs.setStringList(activityKey, logs);
    return logs;
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList(activityKey) ?? [];

    return logs
        .map((e) {
          try {
            return jsonDecode(e) as Map<String, dynamic>;
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
