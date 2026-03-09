import 'package:shared_preferences/shared_preferences.dart';

class FeatureHighlightService {
  FeatureHighlightService._internal();
  static final FeatureHighlightService _instance =
      FeatureHighlightService._internal();
  factory FeatureHighlightService() => _instance;

  static const String _seenPrefix = 'feature_highlight_seen_';
  static const int _maxHighlightsPerSession = 2;
  int _shownThisSession = 0;

  String _storageKey(String featureId, int version) {
    return '$_seenPrefix${featureId}_v$version';
  }

  Future<bool> shouldShow({required String featureId, int version = 1}) async {
    if (_shownThisSession >= _maxHighlightsPerSession) return false;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_storageKey(featureId, version)) ?? false);
  }

  Future<void> markSeen({required String featureId, int version = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey(featureId, version), true);
  }

  void markShownThisSession() {
    _shownThisSession++;
  }
}
