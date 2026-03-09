// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api

part of 'main.dart';

extension MainAppShellRuntimeSession on _EnglishLearningAppState {
  void _logDiagnostic(String message) {
    debugPrint('RecoveryDiag: $message');
  }

  void _logDiagnosticOnce(String key, String message) {
    if (!_processDiagnosticKeys.add(key)) return;
    _logDiagnostic(message);
  }

  Future<_ResolvedSessionIdentity> _resolveAuthoritativeSessionIdentity({
    SharedPreferences? prefs,
  }) async {
    final storage =
        prefs ??
        await SharedPreferences.getInstance().timeout(
          _EnglishLearningAppState._resumeIoTimeout,
        );
    final authUser = FirebaseAuth.instance.currentUser;
    final authHasUser = authUser != null;
    final prefLoggedIn = storage.getBool('is_logged_in') ?? false;
    if (prefLoggedIn != authHasUser) {
      await storage
          .setBool('is_logged_in', authHasUser)
          .timeout(
            _EnglishLearningAppState._resumeIoTimeout,
            onTimeout: () => false,
          );
    }

    if (!authHasUser) {
      if (storage.getString('user_role') != 'student') {
        await storage
            .setString('user_role', 'student')
            .timeout(
              _EnglishLearningAppState._resumeIoTimeout,
              onTimeout: () => false,
            );
      }
      return const _ResolvedSessionIdentity(isLoggedIn: false, role: 'student');
    }

    final role =
        await _resolvePersistedUserRole(
          prefs: storage,
          authEmail: authUser.email,
          fallbackRole: _effectiveUserRole,
        ).timeout(
          _EnglishLearningAppState._resumeIoTimeout,
          onTimeout: () => storage.getString('user_role') ?? _effectiveUserRole,
        );

    return _ResolvedSessionIdentity(isLoggedIn: true, role: role);
  }

  Future<void> _syncEffectiveSessionFromAuth({required String reason}) async {
    try {
      final resolved = await _resolveAuthoritativeSessionIdentity();
      if (!mounted) return;
      if (_effectiveIsLoggedIn == resolved.isLoggedIn &&
          _effectiveUserRole == resolved.role) {
        return;
      }
      setState(() {
        _effectiveIsLoggedIn = resolved.isLoggedIn;
        _effectiveUserRole = resolved.role;
        _homeOverride = null;
      });
      _logDiagnostic(
        'auth_session_synced instance=$_instanceId logged_in=${resolved.isLoggedIn} role=${resolved.role} reason=$reason',
      );
    } catch (e) {
      _logDiagnostic('auth_session_sync_failed reason=$reason error=$e');
    }
  }
}
