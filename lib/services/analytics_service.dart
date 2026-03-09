import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  Future<void> logEvent(String name, [Map<String, dynamic>? parameters]) async {
    // In a real app, integrate FirebaseAnalytics here.
    // For now, we log to console as requested/implied for development/validation.
    debugPrint("[DATA] ANALYTICS EVENT: $name ${parameters ?? ''}");

    // Example integration if package was available:
    // await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
  }

  Future<void> logDailyTasksCompleted() async {
    await logEvent('daily_tasks_completed');
  }

  Future<void> logDailyTasksToGamesClicked() async {
    await logEvent('daily_tasks_to_games_clicked');
  }

  Future<void> logGameBlockedInsufficientContent(String gameName) async {
    await logEvent('game_blocked_insufficient_content', {'game': gameName});
  }

  Future<void> logErrorHuntErrorType(String errorType) async {
    await logEvent('error_hunt_error_type_used', {'type': errorType});
  }
}
