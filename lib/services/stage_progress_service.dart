import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Level-based progression service for Daily Tasks.
/// Single source of truth for current learning level.
class StageProgressService {
  static final StageProgressService _instance =
      StageProgressService._internal();

  factory StageProgressService() => _instance;
  StageProgressService._internal();

  static const String _currentStageKey = 'current_learning_stage';
  static const String _ownerUidKey = 'stage_progress_owner_uid';
  // Daily assessment pass threshold must stay aligned with quiz UX.
  static const int assessmentPassPercent = 70;

  static String _currentStageKeyForUid(String uid) =>
      '${_currentStageKey}_$uid';

  int _sanitizeStage(int stage) => stage < 1 ? 1 : stage;

  String _activeUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    } catch (_) {
      return 'guest';
    }
  }

  Future<int> getCurrentStage({SharedPreferences? prefs}) async {
    final storage = prefs ?? await SharedPreferences.getInstance();
    final uid = _activeUid();
    final previousOwnerUid = storage.getString(_ownerUidKey);
    final canUseGlobalFallback =
        previousOwnerUid == null || previousOwnerUid == uid;

    if (previousOwnerUid != null && previousOwnerUid != uid) {
      await storage.remove(_currentStageKey);
    }
    await storage.setString(_ownerUidKey, uid);

    final scopedKey = _currentStageKeyForUid(uid);
    int? scopedStage = storage.getInt(scopedKey);
    if (scopedStage == null && canUseGlobalFallback) {
      scopedStage = storage.getInt(_currentStageKey);
    }

    final resolvedStage = _sanitizeStage(scopedStage ?? 1);
    await storage.setInt(scopedKey, resolvedStage);
    await storage.setInt(_currentStageKey, resolvedStage);
    return resolvedStage;
  }

  Future<void> setCurrentStage(int stage, {SharedPreferences? prefs}) async {
    final storage = prefs ?? await SharedPreferences.getInstance();
    final uid = _activeUid();
    final next = _sanitizeStage(stage);
    await storage.setString(_ownerUidKey, uid);
    await storage.setInt(_currentStageKeyForUid(uid), next);
    await storage.setInt(_currentStageKey, next);
  }

  Future<int> incrementStage({SharedPreferences? prefs}) async {
    final storage = prefs ?? await SharedPreferences.getInstance();
    final current = await getCurrentStage(prefs: storage);
    final next = current + 1;
    await setCurrentStage(next, prefs: storage);
    return next;
  }

  String stageLabel(int stage) => 'Level $stage';

  int previousStage(int stage) => stage > 1 ? stage - 1 : 0;

  String vocabTaskKey(int stage) => 'task_vocab_stage_$stage';
  String verbsTaskKey(int stage) => 'task_verbs_stage_$stage';
  String speakingTaskKey(int stage) => 'task_speaking_stage_$stage';

  String vocabScoreKey(int stage) => 'task_vocab_stage_${stage}_score';
  String verbsScoreKey(int stage) => 'task_verbs_stage_${stage}_score';
  String speakingScoreKey(int stage) => 'task_speaking_stage_${stage}_score';

  String quizScoreKey(int stage) => 'quiz_score_stage_$stage';
  String quizTotalKey(int stage) => 'quiz_total_stage_$stage';
  String quizPassedKey(int stage) => 'quiz_passed_stage_$stage';
  String assessmentCompletedKey(int stage) =>
      'assessment_completed_stage_$stage';

  bool isAssessmentPassed(int score, int total) {
    if (total <= 0) return false;
    return score * 100 >= total * assessmentPassPercent;
  }

  int requiredAssessmentScore(int total) {
    if (total <= 0) return 0;
    return ((total * assessmentPassPercent) + 99) ~/ 100;
  }

  Future<Map<String, bool>> getStageTaskStatus(int stage) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'vocab': prefs.getBool(vocabTaskKey(stage)) ?? false,
      'verbs': prefs.getBool(verbsTaskKey(stage)) ?? false,
      'speaking': prefs.getBool(speakingTaskKey(stage)) ?? false,
    };
  }

  Future<bool> isStageComplete(int stage) async {
    final status = await getStageTaskStatus(stage);
    return status['vocab'] == true &&
        status['verbs'] == true &&
        status['speaking'] == true;
  }
}
