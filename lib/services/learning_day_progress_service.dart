import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/models/learning_day.dart';

@Deprecated('Legacy calendar-based learning day progress. Unused in stage system.')
class LearningDayProgressService {
  static Future<List<LearningDay>> getLearningDays() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest';

    final startDate = _resolveStartDate(prefs, user);
    final today = _normalizeDate(DateTime.now());
    final normalizedStart = _normalizeDate(startDate);

    if (normalizedStart.isAfter(today)) {
      return [
        LearningDay(
          dayNumber: 1,
          vocabCompleted: false,
          verbsCompleted: false,
          date: normalizedStart,
        ),
      ];
    }

    final days = <LearningDay>[];
    int dayNumber = 1;
    DateTime cursor = normalizedStart;
    while (!cursor.isAfter(today)) {
      final dateKey = _dateKey(cursor);
      final vocabDone = _getTaskStatus(
        prefs: prefs,
        userId: userId,
        prefix: 'task_vocab',
        dateKey: dateKey,
      );
      final verbsDone = _getTaskStatus(
        prefs: prefs,
        userId: userId,
        prefix: 'task_verbs',
        dateKey: dateKey,
      );

      days.add(
        LearningDay(
          dayNumber: dayNumber,
          vocabCompleted: vocabDone,
          verbsCompleted: verbsDone,
          date: cursor,
        ),
      );

      dayNumber++;
      cursor = cursor.add(const Duration(days: 1));
    }

    return days;
  }

  static Future<int> getCompletedLearningDays() async {
    final days = await getLearningDays();
    return days.where((day) => day.isCompleted).length;
  }

  static DateTime _resolveStartDate(
    SharedPreferences prefs,
    User? user,
  ) {
    final customStartStr = prefs.getString('progress_start_date');
    if (customStartStr != null) {
      final parsed = DateTime.tryParse(customStartStr);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }

    final fallbackStartStr = prefs.getString('learning_start_date');
    if (fallbackStartStr != null) {
      final parsed = DateTime.tryParse(fallbackStartStr);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }

    if (user?.metadata.creationTime != null) {
      final created = user!.metadata.creationTime!;
      final start = DateTime(created.year, created.month, created.day);
      prefs.setString('progress_start_date', start.toIso8601String());
      return start;
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    prefs.setString('progress_start_date', start.toIso8601String());
    return start;
  }

  static bool _getTaskStatus({
    required SharedPreferences prefs,
    required String userId,
    required String prefix,
    required String dateKey,
  }) {
    return prefs.getBool('${prefix}_${userId}_$dateKey') ??
        prefs.getBool('${prefix}_$dateKey') ??
        false;
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _dateKey(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }
}
