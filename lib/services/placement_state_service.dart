import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlacementStateService {
  static const String statusKey = 'placement_quiz_status';
  static const String userLevelKey = 'placement_user_level';
  static const String _ownerUidKey = 'placement_state_owner_uid';

  static const String statusNotStarted = 'not_started';
  static const String statusSkipped = 'skipped';
  static const String statusCompleted = 'completed';

  static const String levelUnassigned = 'unassigned';
  static const String levelBeginner = 'beginner';
  static const String levelIntermediate = 'intermediate';
  static const String levelAdvanced = 'advanced';
  static const String _scoreBandFixAppliedKey = 'placement_score_band_fix_v1';

  static String _statusKeyForUid(String uid) => '${statusKey}_$uid';
  static String _userLevelKeyForUid(String uid) => '${userLevelKey}_$uid';
  static String _placementLevelKeyForUid(String uid) => 'placement_level_$uid';
  static String _assessmentCompletedKeyForUid(String uid) =>
      'assessment_completed_$uid';
  static String _assessmentSkippedKeyForUid(String uid) =>
      'assessment_skipped_$uid';
  static String _placementCompletedKeyForUid(String uid) =>
      'placement_completed_$uid';
  static String _placementSkippedKeyForUid(String uid) =>
      'placement_skipped_$uid';

  static const Set<String> _validStatuses = {
    statusNotStarted,
    statusSkipped,
    statusCompleted,
  };

  static const Set<String> _validLevels = {
    levelUnassigned,
    levelBeginner,
    levelIntermediate,
    levelAdvanced,
  };

  static Future<void> ensureInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final previousOwnerUid = prefs.getString(_ownerUidKey);
    final canUseGlobalFallback =
        previousOwnerUid == null || previousOwnerUid == uid;
    if (previousOwnerUid != null && previousOwnerUid != uid) {
      await _clearGlobalAliases(prefs);
    }
    await prefs.setString(_ownerUidKey, uid);

    final scopedStatusKey = _statusKeyForUid(uid);
    final scopedUserLevelKey = _userLevelKeyForUid(uid);
    final scopedPlacementLevelKey = _placementLevelKeyForUid(uid);

    String? status = prefs.getString(scopedStatusKey);
    if (status == null || !_validStatuses.contains(status)) {
      if (canUseGlobalFallback) {
        final globalStatus = prefs.getString(statusKey);
        if (globalStatus != null && _validStatuses.contains(globalStatus)) {
          status = globalStatus;
        }
      }
      status ??= _deriveStatusFromLegacy(
        prefs,
        uid: uid,
        allowGlobalFallback: canUseGlobalFallback,
      );
      await prefs.setString(scopedStatusKey, status);
    }

    String? level = prefs.getString(scopedUserLevelKey);
    if (level == null || !_validLevels.contains(level)) {
      if (canUseGlobalFallback) {
        final globalLevel = prefs.getString(userLevelKey);
        if (globalLevel != null && _validLevels.contains(globalLevel)) {
          level = globalLevel;
        }
      }
      level ??= _deriveUserLevelFromLegacy(
        prefs,
        uid: uid,
        allowGlobalFallback: canUseGlobalFallback,
      );
      await prefs.setString(scopedUserLevelKey, level);
    }

    final cloudPlacement = await _loadPlacementFromCloudIfNeeded(
      status: status,
      level: level,
    );
    if (cloudPlacement != null) {
      status = cloudPlacement['status'] ?? status;
      level = cloudPlacement['level'] ?? level;
      final placementCode = cloudPlacement['placement_code'];
      await prefs.setString(scopedStatusKey, status);
      await prefs.setString(scopedUserLevelKey, level);
      if (placementCode != null && placementCode.isNotEmpty) {
        await prefs.setString(scopedPlacementLevelKey, placementCode);
      }
    }

    if (status != statusCompleted && level != levelUnassigned) {
      level = levelUnassigned;
      await prefs.setString(scopedUserLevelKey, level);
    }

    level = await _applyScoreBandFixIfNeeded(
      prefs,
      status: status,
      level: level,
      uid: uid,
    );
    await prefs.setString(scopedUserLevelKey, level);
    if (level != levelUnassigned) {
      await prefs.setString(scopedPlacementLevelKey, mapUserLevelToPlacementCode(level));
    }

    await _syncLegacyFlags(prefs, status, level, uid: uid);
    await _syncGlobalAliases(
      prefs,
      uid: uid,
      status: status,
      level: level,
    );
  }

  static Future<String> getPlacementQuizStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final status = prefs.getString(_statusKeyForUid(uid)) ?? prefs.getString(statusKey);
    if (status == null || !_validStatuses.contains(status)) {
      await ensureInitialized();
      return prefs.getString(_statusKeyForUid(uid)) ?? statusNotStarted;
    }
    return status;
  }

  static Future<String> getUserLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final level =
        prefs.getString(_userLevelKeyForUid(uid)) ?? prefs.getString(userLevelKey);
    if (level == null || !_validLevels.contains(level)) {
      await ensureInitialized();
      return prefs.getString(_userLevelKeyForUid(uid)) ?? levelUnassigned;
    }
    return level;
  }

  static Future<void> markSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    await prefs.setString(_ownerUidKey, uid);
    await prefs.setString(_statusKeyForUid(uid), statusSkipped);
    await prefs.setString(_userLevelKeyForUid(uid), levelUnassigned);
    await prefs.setString(_placementLevelKeyForUid(uid), 'unclassified');
    await _syncLegacyFlags(prefs, statusSkipped, levelUnassigned, uid: uid);
    await _syncGlobalAliases(
      prefs,
      uid: uid,
      status: statusSkipped,
      level: levelUnassigned,
    );
    await _syncPlacementStateToCloudProgress(
      status: statusSkipped,
      userLevel: levelUnassigned,
      placementCode: 'unclassified',
    );
  }

  static Future<void> markCompleted({
    required String userLevel,
    String? placementCode,
  }) async {
    final normalizedLevel = _validLevels.contains(userLevel)
        ? userLevel
        : mapPlacementCodeToUserLevel(userLevel);

    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    await prefs.setString(_ownerUidKey, uid);
    await prefs.setString(_statusKeyForUid(uid), statusCompleted);
    await prefs.setString(_userLevelKeyForUid(uid), normalizedLevel);

    final legacyCode =
        placementCode ?? mapUserLevelToPlacementCode(normalizedLevel);
    await _syncLegacyFlags(
      prefs,
      statusCompleted,
      normalizedLevel,
      uid: uid,
    );
    await prefs.setString(_placementLevelKeyForUid(uid), legacyCode);
    await _syncGlobalAliases(
      prefs,
      uid: uid,
      status: statusCompleted,
      level: normalizedLevel,
    );
    await _syncPlacementStateToCloudProgress(
      status: statusCompleted,
      userLevel: normalizedLevel,
      placementCode: legacyCode,
    );
  }

  static String mapPlacementCodeToUserLevel(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized == 'A' || normalized.contains('ADVANCED')) {
      return levelAdvanced;
    }
    if (normalized == 'B' || normalized.contains('INTERMEDIATE')) {
      return levelIntermediate;
    }
    if (normalized == 'C' || normalized.contains('BEGINNER')) {
      return levelBeginner;
    }
    if (normalized.contains('UNCLASSIFIED') ||
        normalized.contains('UNASSIGNED')) {
      return levelUnassigned;
    }
    return levelUnassigned;
  }

  static String mapUserLevelToPlacementCode(String level) {
    switch (level) {
      case levelAdvanced:
        return 'A';
      case levelIntermediate:
        return 'B';
      case levelBeginner:
        return 'C';
      default:
        return 'unclassified';
    }
  }

  static String mapUserLevelToCsvSuffix(String level) {
    switch (level) {
      case levelAdvanced:
        return 'Advanced';
      case levelIntermediate:
        return 'Intermediate';
      case levelBeginner:
        return 'Beginner';
      default:
        return 'Beginner';
    }
  }

  /// Source-of-truth for course CSV selection.
  /// Only completed placement determines non-beginner content.
  static Future<String> getCourseLevelSuffix() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    try {
      await ensureInitialized();
    } catch (_) {
      // Best effort; continue with current persisted state.
    }

    final status =
        prefs.getString(_statusKeyForUid(uid)) ??
        prefs.getString(statusKey) ??
        statusNotStarted;
    if (status != statusCompleted) {
      return 'Beginner';
    }

    final userLevel =
        prefs.getString(_userLevelKeyForUid(uid)) ??
        prefs.getString(userLevelKey) ??
        levelUnassigned;
    return mapUserLevelToCsvSuffix(userLevel);
  }

  static String mapProficiencyLabelToUserLevel(String? label) {
    if (label == null || label.trim().isEmpty) {
      return levelUnassigned;
    }
    final normalized = label.toLowerCase();
    if (normalized.contains('advanced') ||
        normalized.contains('c1') ||
        normalized.contains('c2')) {
      return levelAdvanced;
    }
    if (normalized.contains('intermediate') ||
        normalized.contains('b1') ||
        normalized.contains('b2')) {
      return levelIntermediate;
    }
    if (normalized.contains('beginner') ||
        normalized.contains('a1') ||
        normalized.contains('a2')) {
      return levelBeginner;
    }
    return levelUnassigned;
  }

  static String _deriveStatusFromLegacy(
    SharedPreferences prefs, {
    required String uid,
    required bool allowGlobalFallback,
  }) {
    final legacyStatus = prefs.getString('assessment_status_$uid');
    if (legacyStatus == 'completed') return statusCompleted;
    if (legacyStatus == 'skipped') return statusSkipped;

    final assessmentCompleted =
        prefs.getBool(_assessmentCompletedKeyForUid(uid)) ?? false;
    final assessmentSkipped =
        prefs.getBool(_assessmentSkippedKeyForUid(uid)) ?? false;
    if (assessmentCompleted) return statusCompleted;
    if (assessmentSkipped) return statusSkipped;

    final placementCompleted =
        prefs.getBool(_placementCompletedKeyForUid(uid)) ?? false;
    final placementSkipped =
        prefs.getBool(_placementSkippedKeyForUid(uid)) ?? false;
    if (placementCompleted) return statusCompleted;
    if (placementSkipped) return statusSkipped;

    if (allowGlobalFallback) {
      final globalAssessmentCompleted =
          prefs.getBool('assessment_completed') ?? false;
      final globalAssessmentSkipped = prefs.getBool('assessment_skipped') ?? false;
      if (globalAssessmentCompleted) return statusCompleted;
      if (globalAssessmentSkipped) return statusSkipped;

      final globalPlacementCompleted = prefs.getBool('placement_completed') ?? false;
      final globalPlacementSkipped = prefs.getBool('placement_skipped') ?? false;
      if (globalPlacementCompleted) return statusCompleted;
      if (globalPlacementSkipped) return statusSkipped;
    }

    return statusNotStarted;
  }

  static String _deriveUserLevelFromLegacy(
    SharedPreferences prefs, {
    required String uid,
    required bool allowGlobalFallback,
  }) {
    final placementLevel = prefs.getString(_placementLevelKeyForUid(uid));
    if (placementLevel != null && placementLevel.isNotEmpty) {
      final mapped = mapPlacementCodeToUserLevel(placementLevel);
      if (mapped != levelUnassigned) return mapped;
    }

    if (allowGlobalFallback) {
      final globalPlacementLevel = prefs.getString('placement_level');
      if (globalPlacementLevel != null && globalPlacementLevel.isNotEmpty) {
        final mapped = mapPlacementCodeToUserLevel(globalPlacementLevel);
        if (mapped != levelUnassigned) return mapped;
      }
    }

    final scopedProficiency = prefs.getString('english_proficiency_level_$uid');
    if (scopedProficiency != null && scopedProficiency.isNotEmpty) {
      return mapProficiencyLabelToUserLevel(scopedProficiency);
    }

    if (allowGlobalFallback) {
      final globalProficiency = prefs.getString('english_proficiency_level');
      return mapProficiencyLabelToUserLevel(globalProficiency);
    }

    return levelUnassigned;
  }

  static Future<void> _syncLegacyFlags(
    SharedPreferences prefs,
    String status,
    String userLevel, {
    required String uid,
  }) async {
    final placementCompleted = status == statusCompleted;
    final placementSkipped = status == statusSkipped;
    final assessmentCompleted = status == statusCompleted;
    final assessmentSkipped = status == statusSkipped;

    await prefs.setBool(_placementCompletedKeyForUid(uid), placementCompleted);
    await prefs.setBool(_placementSkippedKeyForUid(uid), placementSkipped);
    await prefs.setBool(_assessmentCompletedKeyForUid(uid), assessmentCompleted);
    await prefs.setBool(_assessmentSkippedKeyForUid(uid), assessmentSkipped);

    // Global aliases for legacy call-sites.
    await prefs.setBool('placement_completed', placementCompleted);
    await prefs.setBool('placement_skipped', placementSkipped);
    await prefs.setBool('assessment_completed', assessmentCompleted);
    await prefs.setBool('assessment_skipped', assessmentSkipped);

    if (status != statusCompleted && userLevel != levelUnassigned) {
      await prefs.setString(_userLevelKeyForUid(uid), levelUnassigned);
    }
  }

  static Future<void> _syncGlobalAliases(
    SharedPreferences prefs, {
    required String uid,
    required String status,
    required String level,
  }) async {
    await prefs.setString(statusKey, status);
    await prefs.setString(userLevelKey, level);

    final scopedPlacement = prefs.getString(_placementLevelKeyForUid(uid));
    if (scopedPlacement != null && scopedPlacement.isNotEmpty) {
      await prefs.setString('placement_level', scopedPlacement);
      return;
    }

    if (level == levelUnassigned) {
      await prefs.setString('placement_level', 'unclassified');
    } else {
      await prefs.setString('placement_level', mapUserLevelToPlacementCode(level));
    }
  }

  static Future<void> _clearGlobalAliases(SharedPreferences prefs) async {
    const aliases = <String>[
      statusKey,
      userLevelKey,
      'placement_level',
      'placement_completed',
      'placement_skipped',
      'assessment_completed',
      'assessment_skipped',
    ];
    for (final key in aliases) {
      await prefs.remove(key);
    }
  }

  static Future<String> _applyScoreBandFixIfNeeded(
    SharedPreferences prefs, {
    required String status,
    required String level,
    required String uid,
  }) async {
    final alreadyApplied = prefs.getBool(_scoreBandFixAppliedKey) ?? false;
    if (alreadyApplied) return level;

    var resolvedLevel = level;
    if (status == statusCompleted && level == levelBeginner) {
      final score = prefs.getInt('placement_score');
      if (score != null && score >= 11 && score <= 18) {
        resolvedLevel = levelIntermediate;

        final user = FirebaseAuth.instance.currentUser;
        const upgradedLabel = 'Intermediate (B1)';

        await prefs.setString(
          'english_proficiency_level_$uid',
          upgradedLabel,
        );
        await prefs.setString('english_proficiency_level', upgradedLabel);
        await prefs.setString('effective_difficulty_level', upgradedLabel);

        if (user != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
                  'english_proficiency_level': upgradedLabel,
                  'effective_difficulty_level': upgradedLabel,
                  'placement_level_code': 'B',
                }, SetOptions(merge: true));
          } catch (_) {
            // Best effort: local migration is still applied even if cloud sync fails.
          }
        }
      }
    }

    await prefs.setBool(_scoreBandFixAppliedKey, true);
    return resolvedLevel;
  }

  static Future<Map<String, String>?> _loadPlacementFromCloudIfNeeded({
    required String status,
    required String level,
  }) async {
    if (status == statusCompleted && level != levelUnassigned) {
      return null;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;

      String resolvedStatus = statusNotStarted;
      final rawAssessmentStatus = data['assessment_status']
          ?.toString()
          .toLowerCase()
          .trim();
      if (rawAssessmentStatus == 'completed' ||
          data['assessment_completed'] == true) {
        resolvedStatus = statusCompleted;
      } else if (rawAssessmentStatus == 'skipped' ||
          data['assessment_skipped'] == true) {
        resolvedStatus = statusSkipped;
      }

      final rawPlacementCode = data['placement_level_code']?.toString().trim();
      String resolvedLevel = levelUnassigned;
      if (rawPlacementCode != null && rawPlacementCode.isNotEmpty) {
        resolvedLevel = mapPlacementCodeToUserLevel(rawPlacementCode);
      }

      if (resolvedLevel == levelUnassigned) {
        resolvedLevel = mapProficiencyLabelToUserLevel(
          data['effective_difficulty_level']?.toString() ??
              data['english_proficiency_level']?.toString(),
        );
      }

      if (resolvedStatus != statusCompleted) {
        resolvedLevel = levelUnassigned;
      }

      if (resolvedStatus == statusNotStarted &&
          resolvedLevel == levelUnassigned) {
        return null;
      }

      return {
        'status': resolvedStatus,
        'level': resolvedLevel,
        'placement_code': resolvedLevel == levelUnassigned
            ? 'unclassified'
            : (rawPlacementCode != null && rawPlacementCode.isNotEmpty
                  ? rawPlacementCode
                  : mapUserLevelToPlacementCode(resolvedLevel)),
      };
    } catch (_) {
      return null;
    }
  }

  static Future<void> _syncPlacementStateToCloudProgress({
    required String status,
    required String userLevel,
    required String placementCode,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String assessmentStatus = statusNotStarted;
    if (status == statusCompleted) {
      assessmentStatus = 'completed';
    } else if (status == statusSkipped) {
      assessmentStatus = 'skipped';
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc('all_data')
          .set({
            statusKey: status,
            userLevelKey: userLevel,
            'placement_level': placementCode,
            'placement_completed': status == statusCompleted,
            'placement_skipped': status == statusSkipped,
            'assessment_completed': status == statusCompleted,
            'assessment_skipped': status == statusSkipped,
            'assessment_status_${user.uid}': assessmentStatus,
          }, SetOptions(merge: true));
    } catch (_) {
      // Best effort: local placement state remains the source of truth.
    }
  }
}
