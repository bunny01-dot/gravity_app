// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'main.dart';

extension MainAppShellRuntimeSnapshot on _EnglishLearningAppState {
  Future<void> _persistHomeRoute(
    String route, {

    SharedPreferences? prefs,
  }) async {
    final storage = prefs ?? await SharedPreferences.getInstance();

    await storage.setString(_EnglishLearningAppState._lastHomeRouteKey, route);

    await storage.setInt(
      _EnglishLearningAppState._lastHomeRouteTsKey,

      DateTime.now().millisecondsSinceEpoch,
    );

    await _persistSessionSnapshot(
      pendingRecovery:
          storage.getBool(_EnglishLearningAppState._backgroundFlagKey) ?? false,

      routeOverride: route,

      prefs: storage,
    );
  }

  Future<void> _persistSessionSnapshot({
    required bool pendingRecovery,

    int? backgroundAtMillis,

    String? routeOverride,

    SharedPreferences? prefs,
  }) async {
    try {
      final storage = prefs ?? await SharedPreferences.getInstance();

      final route =
          routeOverride ??
          _deriveHomeRouteName(
            isLoggedIn: _effectiveIsLoggedIn,

            role: _effectiveUserRole,

            hasCompletedPlacement: _effectiveHasCompletedPlacement,
          );

      final snapshot = _AppSessionSnapshot(
        isLoggedIn: _effectiveIsLoggedIn,

        role: _effectiveUserRole,

        hasCompletedPlacement: _effectiveHasCompletedPlacement,

        homeRoute: route,

        pendingRecovery: pendingRecovery,

        savedAtMillis: DateTime.now().millisecondsSinceEpoch,

        backgroundAtMillis: backgroundAtMillis,
      );

      await storage.setString(
        _EnglishLearningAppState._sessionSnapshotKey,

        jsonEncode(
          snapshot.toJson(
            version: _EnglishLearningAppState._sessionSnapshotVersion,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Recovery: failed to persist session snapshot: $e');
    }
  }

  _AppSessionSnapshot? _loadSessionSnapshot(SharedPreferences prefs) {
    final raw = prefs.getString(_EnglishLearningAppState._sessionSnapshotKey);

    final parsed = _AppSessionSnapshot.fromRaw(
      raw,

      expectedVersion: _EnglishLearningAppState._sessionSnapshotVersion,
    );

    if (parsed != null) return parsed;

    if (raw != null && raw.isNotEmpty) {
      _logDiagnostic(
        'snapshot_discarded expected_version=${_EnglishLearningAppState._sessionSnapshotVersion} reason=invalid_or_mismatch',
      );

      unawaited(prefs.remove(_EnglishLearningAppState._sessionSnapshotKey));
    }

    return null;
  }
}
