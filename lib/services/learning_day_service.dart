import 'package:shared_preferences/shared_preferences.dart';

@Deprecated('Legacy calendar-based learning day service. Unused in stage system.')
class LearningDayService {
  // Singleton pattern
  static final LearningDayService _instance = LearningDayService._internal();

  factory LearningDayService() {
    return _instance;
  }

  LearningDayService._internal();

  static const String _startDateKey = 'learning_start_date';
  static const String _currentDayKey = 'learning_current_day';

  /// Get the current learning day number (1-90)
  /// This is based on 24-hour periods since the learning started
  Future<int> getCurrentLearningDay() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we have a manually set current day (for admin override or testing)
    int? manualDay = prefs.getInt(_currentDayKey);
    if (manualDay != null && manualDay >= 1 && manualDay <= 90) {
      return manualDay;
    }

    // Otherwise, calculate based on start date
    String? startDateStr = prefs.getString(_startDateKey);
    if (startDateStr == null) {
      // First time user - set start date to now
      DateTime now = DateTime.now();
      await prefs.setString(_startDateKey, now.toIso8601String());
      return 1; // Day 1 for new users
    }

    DateTime startDate = DateTime.parse(startDateStr);
    DateTime now = DateTime.now();

    // Calculate difference in full 24-hour days
    // "After 24 hours day 2" means:
    // 0-24h = Day 1
    // 24.1-48h = Day 2, etc.
    int currentDay = now.difference(startDate).inDays + 1;

    // Track active dates for analytics/streaks (Legacy support)
    String todayStr = _dateToString(now);
    Set<String> activeDates = _getActiveDates(prefs);
    if (!activeDates.contains(todayStr)) {
      activeDates.add(todayStr);
      _saveActiveDates(prefs, activeDates);
    }

    // Cap at 90 days
    if (currentDay > 90) {
      currentDay = 90;
    }

    return currentDay;
  }

  /// Get the learning day for a specific date
  Future<int> getLearningDayForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();

    String dateStr = _dateToString(date);
    Set<String> activeDates = _getActiveDates(prefs);

    if (!activeDates.contains(dateStr)) {
      return 0; // Not an active learning day
    }

    // Find the position of this date in sorted active dates
    List<String> sortedDates = activeDates.toList()..sort();
    int index = sortedDates.indexOf(dateStr);

    if (index == -1) return 0;

    return index + 1; // Day number (1-indexed)
  }

  /// Mark today as an active learning day
  Future<void> markTodayAsActive() async {
    final prefs = await SharedPreferences.getInstance();
    DateTime today = DateTime.now();
    String todayStr = _dateToString(today);

    Set<String> activeDates = _getActiveDates(prefs);
    activeDates.add(todayStr);
    _saveActiveDates(prefs, activeDates);
  }

  /// Reset learning progress (for testing or admin)
  Future<void> resetLearningProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_startDateKey);
    await prefs.remove(_currentDayKey);
    await prefs.remove('active_dates');
  }

  /// Manually set the current learning day (for testing or admin override)
  Future<void> setCurrentLearningDay(int day) async {
    if (day < 1 || day > 90) {
      throw ArgumentError('Day must be between 1 and 90');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentDayKey, day);
  }

  /// Get all active learning dates
  Set<String> _getActiveDates(SharedPreferences prefs) {
    String? activeDatesStr = prefs.getString('active_dates');
    if (activeDatesStr == null || activeDatesStr.isEmpty) {
      return {};
    }
    return activeDatesStr.split(',').toSet();
  }

  /// Save active learning dates
  Future<void> _saveActiveDates(
    SharedPreferences prefs,
    Set<String> activeDates,
  ) async {
    await prefs.setString('active_dates', activeDates.join(','));
  }

  /// Convert DateTime to string (YYYY-MM-DD)
  String _dateToString(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  /// Get the total number of active learning days
  Future<int> getTotalActiveDays() async {
    final prefs = await SharedPreferences.getInstance();
    Set<String> activeDates = _getActiveDates(prefs);
    return activeDates.length;
  }

  /// Check if a specific date was an active learning day
  Future<bool> wasDateActive(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    String dateStr = _dateToString(date);
    Set<String> activeDates = _getActiveDates(prefs);
    return activeDates.contains(dateStr);
  }
}
