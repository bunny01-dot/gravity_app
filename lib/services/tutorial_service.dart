import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/analytics_service.dart';

class TutorialService {
  static final TutorialService _instance = TutorialService._internal();
  factory TutorialService() => _instance;
  TutorialService._internal();

  static const String _onboardingSeenKey = 'onboarding_seen';
  static const String _dashboardSeenKey = 'tutorial_dashboard_seen';
  static const String _dailyTasksSeenKey = 'tutorial_daily_tasks_seen';
  static const String _gamesLockedSeenKey = 'tutorial_games_locked_seen';
  static const String _masterySeenKey = 'tutorial_mastery_seen';
  static const String _gamesUnlockedOnceKey = 'games_unlocked_once';
  static const String _dashboardHintKey = 'dashboard_hint_seen';
  static const String _dailyTasksHintKey = 'daily_tasks_hint_seen';
  static const String _gamesCtaHintKey = 'games_cta_hint_seen';
  static const String _gamesHubHintKey = 'games_hub_hint_seen';
  static const String _masteryHintKey = 'mastery_hint_seen';
  static const String _settingsHintKey = 'settings_hint_seen';

  static const Set<String> _cloudBackedFlags = {
    _onboardingSeenKey,
    _dashboardSeenKey,
    _dailyTasksSeenKey,
    _gamesLockedSeenKey,
    _masterySeenKey,
    _gamesUnlockedOnceKey,
    _dashboardHintKey,
    _dailyTasksHintKey,
    _gamesCtaHintKey,
    _gamesHubHintKey,
    _masteryHintKey,
    _settingsHintKey,
  };

  // Track tutorial state to suppress notifications and prevent stacking.
  bool _tutorialInProgress = false;
  bool get isTutorialInProgress => _tutorialInProgress;

  String? _cachedUid;
  bool _remoteFlagsLoaded = false;
  Map<String, dynamic>? _remoteFlagCache;

  void startTutorial() {
    _tutorialInProgress = true;
  }

  void endTutorial() {
    _tutorialInProgress = false;
  }

  Future<bool> _readFlag(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getBool(key);
    if (local != null) return local;

    if (!_cloudBackedFlags.contains(key)) {
      return false;
    }

    final remote = await _readRemoteFlag(key);
    if (remote != null) {
      await prefs.setBool(key, remote);
      return remote;
    }

    return false;
  }

  Future<void> _writeFlag(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    if (_cloudBackedFlags.contains(key)) {
      await _writeRemoteFlags({key: value});
    }
  }

  Future<Map<String, dynamic>> _loadRemoteFlagCache() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      _cachedUid = null;
      _remoteFlagsLoaded = false;
      _remoteFlagCache = null;
      return <String, dynamic>{};
    }

    if (_cachedUid != uid) {
      _cachedUid = uid;
      _remoteFlagsLoaded = false;
      _remoteFlagCache = null;
    }

    if (_remoteFlagsLoaded) {
      return _remoteFlagCache ?? <String, dynamic>{};
    }

    _remoteFlagsLoaded = true;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc('all_data')
          .get();
      _remoteFlagCache = doc.data() ?? <String, dynamic>{};
    } catch (e) {
      debugPrint('TutorialService: failed to load remote tutorial flags: $e');
      _remoteFlagCache = <String, dynamic>{};
    }

    return _remoteFlagCache ?? <String, dynamic>{};
  }

  Future<bool?> _readRemoteFlag(String key) async {
    final remoteData = await _loadRemoteFlagCache();
    final raw = remoteData[key];
    if (raw is bool) {
      return raw;
    }
    return null;
  }

  Future<void> _writeRemoteFlags(Map<String, bool> flags) async {
    if (flags.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_cachedUid != user.uid) {
      _cachedUid = user.uid;
      _remoteFlagsLoaded = true;
      _remoteFlagCache = <String, dynamic>{};
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc('all_data')
          .set(flags, SetOptions(merge: true));

      _remoteFlagCache ??= <String, dynamic>{};
      _remoteFlagCache!.addAll(flags);
      _remoteFlagsLoaded = true;
    } catch (e) {
      debugPrint('TutorialService: failed to save tutorial flags: $e');
    }
  }

  // Onboarding
  Future<bool> shouldShowOnboarding() async {
    final seen = await _readFlag(_onboardingSeenKey);
    return !seen;
  }

  Future<void> markOnboardingSeen() async {
    await _writeFlag(_onboardingSeenKey, true);
    AnalyticsService().logEvent('onboarding_completed');
  }

  // Contextual tutorials

  // 1) Dashboard tutorial - "What matters daily"
  Future<bool> shouldShowDashboardTutorial(int streakCount) async {
    final seen = await _readFlag(_dashboardSeenKey);

    // Don't show if already seen or if user has a streak.
    if (seen || streakCount > 0) return false;

    // Don't show if onboarding not completed.
    final onboardingDone = await _readFlag(_onboardingSeenKey);
    if (!onboardingDone) return false;

    return true;
  }

  Future<void> markDashboardTutorialSeen() async {
    await _writeFlag(_dashboardSeenKey, true);
    AnalyticsService().logEvent('tutorial_dashboard_shown');
  }

  // 2) Daily tasks tutorial - "What must be done today"
  Future<bool> shouldShowDailyTasksTutorial(bool tasksCompletedToday) async {
    final seen = await _readFlag(_dailyTasksSeenKey);

    // Don't show if already seen or tasks already completed.
    if (seen || tasksCompletedToday) return false;

    return true;
  }

  Future<void> markDailyTasksTutorialSeen() async {
    await _writeFlag(_dailyTasksSeenKey, true);
    AnalyticsService().logEvent('tutorial_daily_tasks_shown');
  }

  // 3) Games locked tutorial - "Why games are locked"
  Future<bool> shouldShowGamesLockedTutorial() async {
    final seen = await _readFlag(_gamesLockedSeenKey);

    // Don't show if already seen.
    if (seen) return false;

    // Don't show if games were unlocked at least once before.
    final everUnlockedGames = await _readFlag(_gamesUnlockedOnceKey);
    if (everUnlockedGames) return false;

    return true;
  }

  Future<void> markGamesLockedTutorialSeen() async {
    await _writeFlag(_gamesLockedSeenKey, true);
    AnalyticsService().logEvent('tutorial_games_locked_shown');
  }

  Future<void> markGamesUnlockedOnce() async {
    await _writeFlag(_gamesUnlockedOnceKey, true);
  }

  // 4) Mastery tutorial - "Optional, not daily work"
  Future<bool> shouldShowMasteryTutorial() async {
    final seen = await _readFlag(_masterySeenKey);
    return !seen;
  }

  Future<void> markMasteryTutorialSeen() async {
    await _writeFlag(_masterySeenKey, true);
    AnalyticsService().logEvent('tutorial_mastery_shown');
  }

  // Legacy hint methods (kept for backward compatibility)

  Future<bool> shouldShowDashboardHint() async {
    final seen = await _readFlag(_dashboardHintKey);
    return !seen;
  }

  Future<void> markDashboardHintSeen() async {
    await _writeFlag(_dashboardHintKey, true);
  }

  Future<bool> shouldShowDailyTasksHint() async {
    final seen = await _readFlag(_dailyTasksHintKey);
    return !seen;
  }

  Future<void> markDailyTasksHintSeen() async {
    await _writeFlag(_dailyTasksHintKey, true);
  }

  Future<bool> shouldShowGamesCTAHint() async {
    final seen = await _readFlag(_gamesCtaHintKey);
    return !seen;
  }

  Future<void> markGamesCTAHintSeen() async {
    await _writeFlag(_gamesCtaHintKey, true);
  }

  Future<bool> shouldShowGamesHubHint() async {
    final seen = await _readFlag(_gamesHubHintKey);
    return !seen;
  }

  Future<void> markGamesHubHintSeen() async {
    await _writeFlag(_gamesHubHintKey, true);
  }

  Future<bool> shouldShowMasteryHint() async {
    final seen = await _readFlag(_masteryHintKey);
    return !seen;
  }

  Future<void> markMasteryHintSeen() async {
    await _writeFlag(_masteryHintKey, true);
  }

  Future<bool> shouldShowSettingsHint() async {
    final seen = await _readFlag(_settingsHintKey);
    return !seen;
  }

  Future<void> markSettingsHintSeen() async {
    await _writeFlag(_settingsHintKey, true);
  }

  // Reset tutorial (for testing / replay)
  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    const resetKeys = <String>[
      _onboardingSeenKey,
      _dashboardSeenKey,
      _dailyTasksSeenKey,
      _gamesLockedSeenKey,
      _masterySeenKey,
      _gamesUnlockedOnceKey,
      _dashboardHintKey,
      _dailyTasksHintKey,
      _gamesCtaHintKey,
      _gamesHubHintKey,
      _masteryHintKey,
      _settingsHintKey,
    ];

    for (final key in resetKeys) {
      await prefs.setBool(key, false);
    }

    final cloudReset = <String, bool>{};
    for (final key in resetKeys) {
      if (_cloudBackedFlags.contains(key)) {
        cloudReset[key] = false;
      }
    }
    await _writeRemoteFlags(cloudReset);
  }
}
