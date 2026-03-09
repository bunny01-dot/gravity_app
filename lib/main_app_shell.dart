part of 'main.dart';

class EnglishLearningApp extends StatefulWidget {
  final bool isLoggedIn;
  final String userRole;
  final bool firebaseInitialized;
  final bool hasCompletedPlacement;

  const EnglishLearningApp({
    super.key,
    this.isLoggedIn = false,
    this.userRole = 'student',
    this.firebaseInitialized = false,
    this.hasCompletedPlacement =
        true, // Default to true for backwards compatibility
  });

  @override
  State<EnglishLearningApp> createState() => _EnglishLearningAppState();
}

class _EnglishLearningAppState extends State<EnglishLearningApp>
    with WidgetsBindingObserver {
  final int _instanceId = DateTime.now().microsecondsSinceEpoch;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final _NavigatorReadyObserver _navigatorReadyObserver =
      _NavigatorReadyObserver(onNavigatorReady: _onNavigatorReady);
  Completer<void> _navigatorReadyCompleter = Completer<void>();
  final Set<String> _processDiagnosticKeys = <String>{};
  bool _isHandlingResume = false;
  // One-shot guard: never retry resume in the same process instance.
  bool _resumeAttempted = false;
  bool _isRestarting = false;
  int _appRestartToken = 0;
  Widget? _homeOverride;
  ActiveRouteState? _pendingResumeState;
  bool _isResumingDeepLink = false;
  int _activeRecoveryRunId = 0;
  int _resumeEventId = 0;
  bool _isCheckingMissedResumeRecovery = false;
  Timer? _recoveryWatchdog;
  Timer? _resumeAttemptDeadline;
  Timer? _inactiveBackgroundTimer;
  Timer? _blackScreenWatchdog;
  Timer? _startupEscapeTimer;
  bool _isBackgrounded = false;
  bool _firstFrameCommitted = false;
  int? _firstFrameCommittedAtMs;
  bool _nonRecoveryUiRendered = false;
  bool _blackScreenWatchdogResolved = false;
  bool _coldRecoveryRanForProcess = false;
  _AppPhase _appPhase = _AppPhase.booting;
  int? _activeRecoveryStartedAtMs;
  late bool _effectiveIsLoggedIn;
  late String _effectiveUserRole;
  late bool _effectiveHasCompletedPlacement;
  bool _firebaseReady = false;
  DateTime? _lastRecoveryAt;
  DateTime? _lastResumeHandledAt;
  static const Duration _blackScreenWatchdogTimeout = Duration(seconds: 12);
  static const Duration _inactiveBackgroundGrace = Duration(seconds: 8);
  static const Duration _recoveryCooldown = Duration(seconds: 3);
  static const Duration _resumeDebounce = Duration(milliseconds: 900);
  static const Duration _resumeIoTimeout = Duration(seconds: 3);
  static const Duration _recoveryHardTimeout = Duration(seconds: 8);
  static const Duration _coldStartRecoveryTimeout = Duration(seconds: 10);
  static const Duration _startupEscapeTimeout = Duration(seconds: 18);
  static const Duration _recoveryStateMaxAge = Duration(hours: 6);
  static const String _lastHomeRouteKey = 'last_home_route';
  static const String _lastHomeRouteTsKey = 'last_home_route_ts';
  static const String _backgroundFlagKey = 'app_in_background';
  static const String _backgroundAtKey = 'app_backgrounded_at';
  static const String _sessionSnapshotKey = 'app_session_snapshot_v1';
  static const String _lastRecoveryExitReasonKey = 'last_recovery_exit_reason';
  static const String _lastRecoveryDurationMsKey = 'last_recovery_duration_ms';
  static const String _lastForcedSafeRestartReasonKey =
      'last_forced_safe_restart_reason';
  static const String _lastWatchdogFailureReasonKey =
      'last_black_screen_watchdog_reason';
  static const String _lastLifecyclePathKey = 'last_lifecycle_path';
  static const String _lastLifecyclePathTsKey = 'last_lifecycle_path_ts';
  static const int _sessionSnapshotVersion = 1;
  static const Duration _backgroundSaveDebounce = Duration(seconds: 1);
  static const String _routeLanding = 'landing';
  static const String _routeDashboard = 'dashboard';
  static const String _routeTeacherDashboard = 'teacher_dashboard';
  static const String _routePlacement = 'placement_entry';
  String? _lastRecordedHomeRoute;
  bool _isColdStartRecovering = false;
  DateTime? _lastBackgroundSavedAt;
  StreamSubscription<User?>? _authStateSubscription;
  int _recoveryOverlaySerial = 0;

  /// Cached DailyQuizScreen built during resume validation to avoid a second
  /// async build (which caused a visible blank frame / black screen).
  DailyQuizScreen? _cachedDailyQuizResumeScreen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _logDiagnostic('app_instance_created id=$_instanceId');
    _effectiveIsLoggedIn = widget.isLoggedIn;
    _effectiveUserRole = widget.userRole;
    _effectiveHasCompletedPlacement = widget.hasCompletedPlacement;
    _firebaseReady = widget.firebaseInitialized || Firebase.apps.isNotEmpty;
    _logDiagnosticOnce(
      'process_start',
      'process_start_epoch_ms=$_processStartEpochMs',
    );
    _startBlackScreenWatchdog();
    _startStartupEscapeTimer(reason: 'init_state');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markFirstFrameCommitted();
    });
    if (widget.firebaseInitialized) {
      _initFCM();
    }
    if (Firebase.apps.isNotEmpty) {
      _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((
        _,
      ) {
        unawaited(_syncEffectiveSessionFromAuth(reason: 'auth_state_changed'));
      });
      unawaited(_syncEffectiveSessionFromAuth(reason: 'init_state_sync'));
    }
    unawaited(_runColdStartRecoveryOnce());
    unawaited(_persistSessionSnapshot(pendingRecovery: false));
  }

  @override
  void dispose() {
    _recoveryWatchdog?.cancel();
    _cancelResumeAttemptDeadline();
    _inactiveBackgroundTimer?.cancel();
    _blackScreenWatchdog?.cancel();
    _startupEscapeTimer?.cancel();
    unawaited(_authStateSubscription?.cancel());
    _authStateSubscription = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isHardBackgroundState =
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached;

    if (state == AppLifecycleState.inactive) {
      _recordLifecyclePath('inactive->schedule_fallback');
      _scheduleInactiveBackgroundFallback();
      return;
    }

    if (isHardBackgroundState) {
      _cancelInactiveBackgroundFallback();
      _recordLifecyclePath('${state.name}->mark_backgrounded');
      _markAppBackgrounded(source: state.name);
      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        setState(
          () {},
        ); // Force repaint to fix black screen bug on Android resume
        // If we are NOT in an active recovery, proactively mark UI ready so
        // the stale 12-second watchdog is disarmed immediately.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _isBackgrounded) return;
          if (_appPhase != _AppPhase.recovering) {
            _markReadyUiRendered();
          }
        });
      }
      _cancelInactiveBackgroundFallback();
      final now = DateTime.now();
      final wasBackgrounded = _isBackgrounded;
      _isBackgrounded = false;
      // _armResumeUiWatchdog is intentionally NOT called here for every resume.
      // It is called inside _startResumeAttempt, which only runs when a real
      // lesson-recovery is needed. This prevents the 12-second watchdog from
      // firing on simple minimize/resume from the dashboard.
      _recordLifecyclePath('resumed->was_backgrounded=$wasBackgrounded');
      if (!wasBackgrounded) {
        debugPrint(
          'Recovery: resume arrived without in-memory background flag; checking persisted flags',
        );
        _recordLifecyclePath('resumed->check_persisted_background');
        unawaited(_attemptMissedBackgroundRecoveryOnResume(now));
        return;
      }
      if (_lastResumeHandledAt != null &&
          now.difference(_lastResumeHandledAt!) < _resumeDebounce) {
        debugPrint('Recovery: resume ignored (debounced)');
        _recordLifecyclePath('resumed->debounced_ignore');
        return;
      }
      _lastResumeHandledAt = now;
      _recordLifecyclePath('resumed->handle_app_resumed');
      unawaited(_handleAppResumed());
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(
      !_isRestarting || _activeRecoveryRunId > 0,
      'Recovery invariant violated: restart active without a valid run id.',
    );

    final homeRoute = _deriveHomeRouteName(
      isLoggedIn: _effectiveIsLoggedIn,
      role: _effectiveUserRole,
      hasCompletedPlacement: _effectiveHasCompletedPlacement,
    );

    if (_homeOverride == null &&
        !_isRestarting &&
        !_isColdStartRecovering &&
        homeRoute != _lastRecordedHomeRoute) {
      _lastRecordedHomeRoute = homeRoute;
      _persistHomeRoute(homeRoute);
    }

    final Widget readyHomeScreen = _homeOverride ?? _buildGuaranteedSafeHome();
    final bool isBootingPhase = _appPhase == _AppPhase.booting;
    final bool isRecoveringPhase = _appPhase == _AppPhase.recovering;
    final bool isRecoveryPhase = isBootingPhase || isRecoveringPhase;
    assert(() {
      if (isRecoveryPhase) {
        _logDiagnostic(
          'phase_render instance=$_instanceId phase=${_appPhase.name} mounted=$mounted',
        );
      }
      return true;
    }());
    // Recovery overlay strategy:
    // - BOOTING: full-screen loading surface (no ready UI exists yet)
    // - RECOVERING: keep last known good ready UI mounted; block interaction with overlay
    final Widget phaseBase = isBootingPhase
        ? RecoveryLoadingScreen(
            phaseName: _appPhase.name,
            instanceId: _instanceId,
            recoverySerial: _recoveryOverlaySerial,
          )
        : readyHomeScreen;
    final Widget phaseSurface = Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final scale = Tween<double>(
              begin: 0.985,
              end: 1.0,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: scale, child: child),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<String>(
              isBootingPhase
                  ? 'phase_booting'
                  : 'phase_ready_${homeRoute}_${_appRestartToken}_$_recoveryOverlaySerial',
            ),
            child: phaseBase,
          ),
        ),
        if (isRecoveringPhase)
          BlockingRecoveryOverlay(
            phaseName: _appPhase.name,
            instanceId: _instanceId,
            recoverySerial: _recoveryOverlaySerial,
          ),
      ],
    );

    final bool rendersReadyUi = !isBootingPhase;
    if (rendersReadyUi && !_nonRecoveryUiRendered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markReadyUiRendered();
      });
    } else if (!rendersReadyUi) {
      _nonRecoveryUiRendered = false;
    }

    return Listener(
      // Detect ANY user interaction to reset idle timer
      onPointerDown: (_) => StudentDataPreloader().onUserInteraction(),
      onPointerMove: (_) => StudentDataPreloader().onUserInteraction(),
      onPointerUp: (_) => StudentDataPreloader().onUserInteraction(),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppThemeService.themeModeNotifier,
        builder: (context, activeThemeMode, _) {
          return MaterialApp(
            key: ValueKey(_appRestartToken),
            title: 'English Learning App',
            debugShowCheckedModeBanner: false,
            navigatorKey: _navigatorKey,
            navigatorObservers: [
              _navigatorReadyObserver,
              SoundNavigationObserver(),
              routeObserver,
            ], // Issue 2: Nav Sounds
            builder: (context, child) {
              return Stack(
                children: [if (child != null) child, const GlobalXpOverlay()],
              );
            },
            themeMode: activeThemeMode,
            theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          fontFamily: 'Inter',
          fontFamilyFallback: const ['NotoSansTamil', 'NotoSansDevanagari'],
          scaffoldBackgroundColor: const Color(0xFFF4F8FF),
          colorScheme:
              ColorScheme.fromSeed(
                seedColor: const Color(0xFF4FACFE),
                brightness: Brightness.light,
              ).copyWith(
                primary: const Color(0xFF4FACFE),
                secondary: const Color(0xFF00D3FF),
                tertiary: const Color(0xFF6C63FF),
                surface: const Color(0xFFF9FBFF),
                surfaceContainerHighest: const Color(0xFFEFF4FF),
              ),
          cardTheme: CardThemeData(
            color: Colors.white.withValues(alpha: 0.68),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            surfaceTintColor: Colors.transparent,
            titleTextStyle: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            contentTextStyle: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 15,
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xEE0F172A),
            contentTextStyle: const TextStyle(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              elevation: 0,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
            darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          fontFamily: 'Inter',
          fontFamilyFallback: const ['NotoSansTamil', 'NotoSansDevanagari'],
          scaffoldBackgroundColor: const Color(0xFF030305),
          colorScheme:
              ColorScheme.fromSeed(
                seedColor: const Color(0xFF4FACFE),
                brightness: Brightness.dark,
              ).copyWith(
                primary: const Color(0xFF4FACFE),
                secondary: const Color(0xFF00F2FE),
                tertiary: const Color(0xFF6C63FF),
                surface: const Color(0xFF0F172A),
                surfaceContainerHighest: const Color(0xFF1A2332),
              ),
          cardTheme: CardThemeData(
            color: const Color(0xFF111827).withValues(alpha: 0.66),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            surfaceTintColor: Colors.transparent,
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            contentTextStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 15,
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xEE0B1220),
            contentTextStyle: const TextStyle(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              elevation: 0,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
            home: _NeverBlankRootShell(child: phaseSurface),
          );
        },
      ),
    );
  }

  void _handleThemeModeChanged(ThemeMode mode) {
    unawaited(AppThemeService.setThemeMode(mode));
  }
}
