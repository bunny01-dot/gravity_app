import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/stage_progress_service.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/xp_reward_policy.dart';

class TaskCompletionXpConfig {
  static const int vocabulary = XpRewardPolicy.standardTaskReward;
  static const int verbs = XpRewardPolicy.standardTaskReward;
  static const int pronunciation = XpRewardPolicy.standardTaskReward;
}

class TaskCompletionResult {
  final bool wasAlreadyComplete;
  final int xpAwarded;
  final bool leveledUp;

  const TaskCompletionResult({
    required this.wasAlreadyComplete,
    required this.xpAwarded,
    required this.leveledUp,
  });
}

class _XpAwardResult {
  final int xpAwarded;
  final bool leveledUp;

  const _XpAwardResult({this.xpAwarded = 0, this.leveledUp = false});
}

/// Atomic daily task completion manager
/// Ensures vocab + verbs complete together before advancing day
class DailyTaskCompletionService {
  static final DailyTaskCompletionService _instance =
      DailyTaskCompletionService._internal();

  factory DailyTaskCompletionService() => _instance;
  DailyTaskCompletionService._internal();

  final StageProgressService _stageService = StageProgressService();
  final DataService _dataService = DataService();

  // Task completion flags (per day)
  static const String _reinforcementIntroSeenKey = 'reinforcement_intro_seen';

  /// Mark vocabulary task as complete for current day
  Future<TaskCompletionResult> markVocabularyComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = await _stageService.getCurrentStage(prefs: prefs);
    final taskKey = _stageService.vocabTaskKey(stage);
    return _markTaskComplete(
      prefs: prefs,
      taskKey: taskKey,
      taskLabel: 'Vocabulary',
      xpAmount: TaskCompletionXpConfig.vocabulary,
    );
  }

  /// Mark verbs task as complete for current day
  Future<TaskCompletionResult> markVerbsComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = await _stageService.getCurrentStage(prefs: prefs);
    final taskKey = _stageService.verbsTaskKey(stage);
    return _markTaskComplete(
      prefs: prefs,
      taskKey: taskKey,
      taskLabel: 'Verbs',
      xpAmount: TaskCompletionXpConfig.verbs,
    );
  }

  /// Shared flow for full daily vocabulary list completion.
  Future<TaskCompletionResult> completeVocabularyListTask({
    required Iterable<String> learnedWords,
  }) async {
    return _completeListTaskAndMark(
      learnedStorageKey: 'learned_vocab_ids',
      learnedItems: learnedWords,
      scoreKeyForStage: _stageService.vocabScoreKey,
      markTaskComplete: markVocabularyComplete,
    );
  }

  /// Shared flow for full daily verbs list completion.
  Future<TaskCompletionResult> completeVerbsListTask({
    required Iterable<String> learnedVerbs,
  }) async {
    return _completeListTaskAndMark(
      learnedStorageKey: 'learned_verbs_ids',
      learnedItems: learnedVerbs,
      scoreKeyForStage: _stageService.verbsScoreKey,
      markTaskComplete: markVerbsComplete,
    );
  }

  static Map<String, dynamic> completionResultPayload(
    TaskCompletionResult result,
  ) {
    return {
      'completed': true,
      'xpAwarded': result.xpAwarded,
      'leveledUp': result.leveledUp,
    };
  }

  /// Mark pronunciation task as complete for current day
  Future<TaskCompletionResult> markPronunciationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = await _stageService.getCurrentStage(prefs: prefs);
    final taskKey = _stageService.speakingTaskKey(stage);
    return _markTaskComplete(
      prefs: prefs,
      taskKey: taskKey,
      taskLabel: 'Pronunciation',
      xpAmount: TaskCompletionXpConfig.pronunciation,
    );
  }

  Future<TaskCompletionResult> awardPronunciationXpIfNeeded({
    required int stage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final taskKey = _stageService.speakingTaskKey(stage);
    return _awardXpOnlyForTask(prefs: prefs, taskKey: taskKey);
  }

  Future<TaskCompletionResult> _markTaskComplete({
    required SharedPreferences prefs,
    required String taskKey,
    required String taskLabel,
    required int xpAmount,
  }) async {
    final alreadyComplete = prefs.getBool(taskKey) ?? false;
    if (!alreadyComplete) {
      await prefs.setBool(taskKey, true);
      await _dataService.saveProgressToCloud(taskKey, true);
    }

    final xpResult = await _awardXpForTaskIfNeeded(
      prefs: prefs,
      taskKey: taskKey,
      xpAmount: xpAmount,
    );
    debugPrint(
      '$taskLabel marked complete. alreadyComplete=$alreadyComplete, xpAwarded=${xpResult.xpAwarded}',
    );

    // Check if all tasks are now complete
    await _checkAndCompleteDay();

    return TaskCompletionResult(
      wasAlreadyComplete: alreadyComplete,
      xpAwarded: xpResult.xpAwarded,
      leveledUp: xpResult.leveledUp,
    );
  }

  Future<TaskCompletionResult> _completeListTaskAndMark({
    required String learnedStorageKey,
    required Iterable<String> learnedItems,
    required String Function(int stage) scoreKeyForStage,
    required Future<TaskCompletionResult> Function() markTaskComplete,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final stage = await _stageService.getCurrentStage(prefs: prefs);

    final mergedLearnedItems = _mergeLearnedItems(
      existing: prefs.getStringList(learnedStorageKey) ?? const <String>[],
      incoming: learnedItems,
    );

    await prefs.setStringList(learnedStorageKey, mergedLearnedItems);
    await _dataService.saveProgressToCloud(
      learnedStorageKey,
      mergedLearnedItems,
    );

    final scoreKey = scoreKeyForStage(stage);
    await prefs.setInt(scoreKey, 100);
    await _dataService.saveProgressToCloud(scoreKey, 100);

    return markTaskComplete();
  }

  List<String> _mergeLearnedItems({
    required Iterable<String> existing,
    required Iterable<String> incoming,
  }) {
    final seen = <String>{};
    final merged = <String>[];

    void addAll(Iterable<String> source) {
      for (final raw in source) {
        final value = raw.trim();
        if (value.isEmpty || seen.contains(value)) continue;
        seen.add(value);
        merged.add(value);
      }
    }

    addAll(existing);
    addAll(incoming);
    return merged;
  }

  Future<TaskCompletionResult> _awardXpOnlyForTask({
    required SharedPreferences prefs,
    required String taskKey,
  }) async {
    final xpResult = await _awardXpForTaskIfNeeded(
      prefs: prefs,
      taskKey: taskKey,
      xpAmount: TaskCompletionXpConfig.pronunciation,
    );
    return TaskCompletionResult(
      wasAlreadyComplete: prefs.getBool(taskKey) ?? false,
      xpAwarded: xpResult.xpAwarded,
      leveledUp: xpResult.leveledUp,
    );
  }

  Future<_XpAwardResult> _awardXpForTaskIfNeeded({
    required SharedPreferences prefs,
    required String taskKey,
    required int xpAmount,
  }) async {
    final awardedXp = XpRewardPolicy.normalize(xpAmount);
    if (awardedXp <= 0) return const _XpAwardResult();

    final xpAwardedKey = 'xp_awarded_$taskKey';
    final alreadyAwarded = prefs.getBool(xpAwardedKey) ?? false;
    if (alreadyAwarded) {
      return const _XpAwardResult();
    }

    try {
      final leveledUp = await _dataService.addXp(awardedXp);
      await prefs.setBool(xpAwardedKey, true);
      await _dataService.saveProgressToCloud(xpAwardedKey, true);
      return _XpAwardResult(xpAwarded: awardedXp, leveledUp: leveledUp);
    } catch (e) {
      debugPrint('Failed to award XP for $taskKey: $e');
      return const _XpAwardResult();
    }
  }

  /// ATOMIC: Check if vocab + verbs complete, then advance day
  /// Assessment should control stage advancement (>=70%).
  /// This method now only reports readiness for assessment.
  Future<bool> _checkAndCompleteDay() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = await _stageService.getCurrentStage(prefs: prefs);

    final bool vocabComplete =
        prefs.getBool(_stageService.vocabTaskKey(stage)) ?? false;
    final bool verbsComplete =
        prefs.getBool(_stageService.verbsTaskKey(stage)) ?? false;
    final bool pronunciationComplete =
        prefs.getBool(_stageService.speakingTaskKey(stage)) ?? false;

    debugPrint(
      'Level $stage completion status: Vocab=$vocabComplete, Verbs=$verbsComplete, Pronunciation=$pronunciationComplete',
    );

    if (vocabComplete && verbsComplete && pronunciationComplete) {
      debugPrint(
        'Level $stage tasks complete. Ready for assessment (no auto-advance).',
      );
      return true;
    }

    debugPrint(
      'Level $stage not yet complete (waiting for vocab + verbs + pronunciation)',
    );
    return false;
  }

  Future<Map<String, bool>> getCurrentDayStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = await _stageService.getCurrentStage(prefs: prefs);

    return {
      'vocab': prefs.getBool(_stageService.vocabTaskKey(stage)) ?? false,
      'verbs': prefs.getBool(_stageService.verbsTaskKey(stage)) ?? false,
      'pronunciation':
          prefs.getBool(_stageService.speakingTaskKey(stage)) ?? false,
    };
  }

  /// Check if vocab + verbs are complete for current day
  Future<bool> isCurrentDayComplete() async {
    Map<String, bool> status = await getCurrentDayStatus();
    return status['vocab']! && status['verbs']! && status['pronunciation']!;
  }

  /// Get overall progress percentage for current day (0-100)
  Future<int> getCurrentDayProgress() async {
    Map<String, bool> status = await getCurrentDayStatus();
    int completedCount = 0;
    if (status['vocab']!) completedCount++;
    if (status['verbs']!) completedCount++;
    if (status['pronunciation']!) completedCount++;
    return (completedCount / 3 * 100).round();
  }

  /// Check if reinforcement intro should be shown
  Future<bool> shouldShowReinforcementIntro() async {
    final prefs = await SharedPreferences.getInstance();
    bool alreadySeen = prefs.getBool(_reinforcementIntroSeenKey) ?? false;
    return !alreadySeen;
  }

  /// Mark reinforcement intro as shown (for manual triggering)
  Future<void> markReinforcementIntroShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reinforcementIntroSeenKey, true);
  }

  /// Reset all completion flags (for testing)
  Future<void> resetCompletionFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = await _stageService.getCurrentStage(prefs: prefs);

    await prefs.remove(_stageService.vocabTaskKey(stage));
    await prefs.remove(_stageService.verbsTaskKey(stage));
    await prefs.remove(_stageService.speakingTaskKey(stage));

    debugPrint('Reset completion flags for stage $stage');
  }

  /// Manual completion (use ONLY for admin/testing)
  /// This bypasses individual task checks
  Future<void> forceCompleteCurrentDay() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = await _stageService.getCurrentStage(prefs: prefs);

    debugPrint('FORCE COMPLETING stage $stage (admin/testing only)');

    await _stageService.incrementStage(prefs: prefs);
    await DataService().saveProgressToCloud(
      'current_learning_stage',
      stage + 1,
    );
  }
}
