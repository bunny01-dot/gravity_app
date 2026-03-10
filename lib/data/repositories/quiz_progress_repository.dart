import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/stage_progress_service.dart';

class QuizProgressRepository {
  String legacyDateKey(DateTime date) => date.toIso8601String().split('T')[0];

  Future<bool> hasPassedQuiz(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'quiz_passed_${legacyDateKey(date)}';
    return prefs.getBool(key) ?? false;
  }

  Future<QuizResult> saveQuizResult(
    DateTime date,
    int score,
    int total,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = legacyDateKey(date);
    final passed = total > 0 && (score * 100) >= (total * 70);

    await prefs.setInt('quiz_score_$dateKey', score);
    await prefs.setInt('quiz_total_$dateKey', total);
    await prefs.setBool('quiz_passed_$dateKey', passed);

    return QuizResult(
      dateKey: dateKey,
      score: score,
      total: total,
      passed: passed,
    );
  }

  Future<List<DateTime>> getMissedDates() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final missed = <DateTime>{};

    for (final key in prefs.getKeys()) {
      if (!key.startsWith('quiz_passed_')) continue;
      final passed = prefs.getBool(key) ?? false;
      if (passed) continue;

      final raw = key.substring('quiz_passed_'.length);
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) continue;

      final normalized = DateTime(parsed.year, parsed.month, parsed.day);
      if (normalized.isBefore(today)) {
        missed.add(normalized);
      }
    }

    final list = missed.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  Future<bool> hasPassedQuizForStage(int stage) async {
    final prefs = await SharedPreferences.getInstance();
    final stageService = StageProgressService();
    return prefs.getBool(stageService.quizPassedKey(stage)) ?? false;
  }

  Future<bool> hasAttemptedQuizForStage(int stage) async {
    final prefs = await SharedPreferences.getInstance();
    final stageService = StageProgressService();
    return prefs.containsKey(stageService.quizScoreKey(stage));
  }

  Future<List<int>> getMissedStages() async {
    final prefs = await SharedPreferences.getInstance();
    final stageService = StageProgressService();
    final currentStage = await stageService.getCurrentStage(prefs: prefs);

    final missed = <int>[];
    for (int stage = 1; stage < currentStage; stage++) {
      final assessmentCompleted =
          prefs.getBool(stageService.assessmentCompletedKey(stage)) ?? false;
      bool quizPassed =
          prefs.getBool(stageService.quizPassedKey(stage)) ?? false;

      if (!quizPassed) {
        final score = prefs.getInt(stageService.quizScoreKey(stage));
        final total = prefs.getInt(stageService.quizTotalKey(stage));
        if (score != null && total != null && total > 0) {
          quizPassed = stageService.isAssessmentPassed(score, total);
        }
      }

      // Assessment completion (perfect score) clears recovery for this stage.
      if (!assessmentCompleted && !quizPassed) {
        missed.add(stage);
      }
    }

    return missed;
  }
}

class QuizResult {
  final String dateKey;
  final int score;
  final int total;
  final bool passed;

  const QuizResult({
    required this.dateKey,
    required this.score,
    required this.total,
    required this.passed,
  });
}
