part of 'main.dart';

const Duration _initialLaunchAnimationDuration = Duration(milliseconds: 2800);
const Duration _repeatLaunchAnimationDuration = Duration(milliseconds: 1600);

class _ResumePolicyDecision {
  const _ResumePolicyDecision({
    required this.snapshotIsFresh,
    required this.backgroundDuration,
    required this.resumeAlreadyAttempted,
  });

  final bool snapshotIsFresh;
  final Duration? backgroundDuration;
  final bool resumeAlreadyAttempted;

  bool get shouldAttemptResume {
    return snapshotIsFresh &&
        backgroundDuration != null &&
        backgroundDuration! <= kLongBackgroundThreshold &&
        !resumeAlreadyAttempted;
  }
}

class _AppLaunchState {
  final bool isLoggedIn;
  final String userRole;
  final bool firebaseInitialized;
  final bool hasCompletedPlacement;

  const _AppLaunchState({
    required this.isLoggedIn,
    required this.userRole,
    required this.firebaseInitialized,
    required this.hasCompletedPlacement,
  });
}

class _ResolvedSessionIdentity {
  const _ResolvedSessionIdentity({
    required this.isLoggedIn,
    required this.role,
  });

  final bool isLoggedIn;
  final String role;
}

class _AppSessionSnapshot {
  final bool isLoggedIn;
  final String role;
  final bool hasCompletedPlacement;
  final String homeRoute;
  final bool pendingRecovery;
  final int savedAtMillis;
  final int? backgroundAtMillis;

  const _AppSessionSnapshot({
    required this.isLoggedIn,
    required this.role,
    required this.hasCompletedPlacement,
    required this.homeRoute,
    required this.pendingRecovery,
    required this.savedAtMillis,
    required this.backgroundAtMillis,
  });

  Map<String, dynamic> toJson({required int version}) {
    return <String, dynamic>{
      'v': version,
      'is_logged_in': isLoggedIn,
      'role': role,
      'has_completed_placement': hasCompletedPlacement,
      'home_route': homeRoute,
      'pending_recovery': pendingRecovery,
      'saved_at': savedAtMillis,
      'background_at': backgroundAtMillis,
    };
  }

  static _AppSessionSnapshot? fromRaw(
    String? raw, {
    required int expectedVersion,
  }) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      final version = _toInt(map['v']);
      if (version != expectedVersion) {
        return null;
      }
      return _AppSessionSnapshot(
        isLoggedIn: _toBool(map['is_logged_in']),
        role: (map['role'] ?? 'student').toString(),
        hasCompletedPlacement: _toBool(map['has_completed_placement']),
        homeRoute: (map['home_route'] ?? '').toString(),
        pendingRecovery: _toBool(map['pending_recovery']),
        savedAtMillis: _toInt(map['saved_at']),
        backgroundAtMillis: _toNullableInt(map['background_at']),
      );
    } catch (_) {
      return null;
    }
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return false;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    final parsed = _toInt(value);
    return parsed == 0 ? null : parsed;
  }
}

enum _AppPhase { booting, recovering, ready }

class _NavigatorReadyObserver extends NavigatorObserver {
  _NavigatorReadyObserver({required this.onNavigatorReady});

  final VoidCallback onNavigatorReady;
  bool _reported = false;

  void reset() {
    _reported = false;
  }

  void _reportReady() {
    if (_reported) return;
    _reported = true;
    onNavigatorReady();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _reportReady();
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _reportReady();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class _NeverBlankRootShell extends StatelessWidget {
  const _NeverBlankRootShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}

class AppBootstrapShell extends StatefulWidget {
  const AppBootstrapShell({super.key});

  @override
  State<AppBootstrapShell> createState() => _AppBootstrapShellState();
}

bool _isInitialAppLaunch = true;

class _AppBootstrapShellState extends State<AppBootstrapShell> {
  late final Future<_AppLaunchState> _launchFuture = _prepareLaunchState();

  Future<_AppLaunchState> _prepareLaunchState() async {
    final launchStartedAt = DateTime.now();
    bool firebaseInitialized = false;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));
      firebaseInitialized = true;
      debugPrint("OK: Firebase initialized successfully");

      // Enable App Check on mobile platforms.
      // Web activation requires a reCAPTCHA key configured in Console + client.
      if (!kIsWeb) {
        try {
          await FirebaseAppCheck.instance
              .activate(
                providerAndroid: kDebugMode
                    ? const AndroidDebugProvider()
                    : const AndroidPlayIntegrityProvider(),
                providerApple: kDebugMode
                    ? const AppleDebugProvider()
                    : const AppleDeviceCheckProvider(),
              )
              .timeout(const Duration(seconds: 10));
          debugPrint("OK: Firebase App Check activated");
        } catch (e) {
          debugPrint("[WARN] Firebase App Check activation failed: $e");
        }
      } else {
        debugPrint(
          " Firebase App Check not enabled on web (missing reCAPTCHA key).",
        );
      }

      await SfxManager().init().timeout(const Duration(seconds: 5));
      AppLifecycleManager().initialize();
      debugPrint("OK: App Lifecycle Manager initialized");
    } catch (e, stackTrace) {
      debugPrint("Error: Firebase initialization failed: $e");
      debugPrint("Stack trace: $stackTrace");

      if (e.toString().contains('duplicate-app')) {
        debugPrint("[WARN] Firebase already initialized - continuing");
        firebaseInitialized = true;
      }
    }

    if (firebaseInitialized &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      try {
        fcm.FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      } catch (e) {
        debugPrint("Failed to register background handler: $e");
      }
    }

    final prefs = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 5),
    );

    final authUser = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = authUser != null;
    final prefLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (prefLoggedIn != isLoggedIn) {
      await prefs
          .setBool('is_logged_in', isLoggedIn)
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
    }
    final String userRole = isLoggedIn
        ? await _resolvePersistedUserRole(
            prefs: prefs,
            authEmail: authUser.email,
            fallbackRole: 'student',
          )
        : 'student';
    if (!isLoggedIn && prefs.getString('user_role') != 'student') {
      await prefs
          .setString('user_role', 'student')
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
    }

    bool hasCompletedPlacement = true;
    try {
      await PlacementStateService.ensureInitialized().timeout(
        const Duration(seconds: 10),
      );
      final String placementStatus =
          await PlacementStateService.getPlacementQuizStatus();
      hasCompletedPlacement =
          placementStatus == PlacementStateService.statusCompleted;
    } catch (e) {
      debugPrint('Placement init failed, using fallback: $e');
      hasCompletedPlacement = true;
    }

    final elapsed = DateTime.now().difference(launchStartedAt);

    final targetWaitDuration = _isInitialAppLaunch
        ? _initialLaunchAnimationDuration
        : _repeatLaunchAnimationDuration;
    final remaining = targetWaitDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    _isInitialAppLaunch = false;

    return _AppLaunchState(
      isLoggedIn: isLoggedIn,
      userRole: userRole,
      firebaseInitialized: firebaseInitialized,
      hasCompletedPlacement: hasCompletedPlacement,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppLaunchState>(
      future: _launchFuture,
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState != ConnectionState.done) {
          child = MaterialApp(
            key: const ValueKey('loading'),
            debugShowCheckedModeBanner: false,
            home: _NeverBlankRootShell(
              child: StartupLoadingScreen(
                isInitialLaunch: _isInitialAppLaunch,
                onSkip: () {
                  setState(() {
                    // Fallback state if init hangs
                  });
                },
              ),
            ),
          );
        } else {
          final data = snapshot.data;
          if (data == null) {
            child = const MaterialApp(
              key: ValueKey('error'),
              debugShowCheckedModeBanner: false,
              home: _NeverBlankRootShell(child: InitializationErrorScreen()),
            );
          } else {
            child = EnglishLearningApp(
              key: const ValueKey('app'),
              isLoggedIn: data.isLoggedIn,
              userRole: data.userRole,
              firebaseInitialized: data.firebaseInitialized,
              hasCompletedPlacement: data.hasCompletedPlacement,
            );
          }
        }

        // Lightweight handoff: fade in only the incoming tree.
        // We intentionally ignore outgoing children to avoid jank from
        // rendering two full roots at once.
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.linear,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          layoutBuilder: (currentChild, _) =>
              currentChild ?? const SizedBox.shrink(),
          child: child,
        );
      },
    );
  }
}

class StartupLoadingScreen extends StatefulWidget {
  final bool isInitialLaunch;
  final VoidCallback? onSkip;
  const StartupLoadingScreen({
    super.key,
    this.isInitialLaunch = true,
    this.onSkip,
  });

  @override
  State<StartupLoadingScreen> createState() => _StartupLoadingScreenState();
}

class _StartupLoadingScreenState extends State<StartupLoadingScreen>
    with TickerProviderStateMixin {
  bool _showSkip = false;
  Timer? _timer;
  late final AnimationController _revealController;
  late final AnimationController _progressShineController;
  late final Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressShineController = AnimationController(
      vsync: this,
      duration: widget.isInitialLaunch
          ? _initialLaunchAnimationDuration
          : _repeatLaunchAnimationDuration,
    )..forward();
    _logoOpacity = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutCubic,
    );
    _revealController.forward();
    _timer = Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => _showSkip = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _revealController.dispose();
    _progressShineController.dispose();
    super.dispose();
  }

  Widget _buildAmbientBackground() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        ),
      ),
    );
  }

  Widget _buildLogoHero() {
    return SizedBox(
      width: 320, // Expanded bound to prevent scaling clip
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Outer circle (Background shape gently expanding)
          AnimatedBuilder(
            animation: _progressShineController,
            builder: (context, child) {
              // Smoothly scale from 1.0 to 1.15 over 3.5 seconds
              final curvedValue = Curves.easeOutQuart.transform(
                _progressShineController.value,
              );
              return Transform.scale(
                scale: 1.0 + (0.15 * curvedValue),
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(64),
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              );
            },
          ),

          // Inner circle (Slightly faster inner expansion)
          AnimatedBuilder(
            animation: _progressShineController,
            builder: (context, child) {
              // Smoothly scale from 1.0 to 1.10 over 3.5 seconds
              final curvedValue = Curves.easeOutQuart.transform(
                _progressShineController.value,
              );
              return Transform.scale(
                scale: 1.0 + (0.10 * curvedValue),
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(52),
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              );
            },
          ),

          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 200,
              height: 200,
              child: Image.asset(
                'assets/images/app_logo_anim.webp',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const GravityLogo(size: 150);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRail() {
    return AnimatedBuilder(
      animation: _progressShineController,
      builder: (context, child) {
        final progress = _progressShineController.value;
        final travel = -1.35 + (progress * 2.7);
        return Container(
          width: 190,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(travel, 0),
                  child: Transform.rotate(
                    angle: -0.38,
                    child: Container(
                      width: 40,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.75),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildAmbientBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogoHero(),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: Text(
                      'Gravity App',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: _buildProgressRail(),
                  ),
                  if (_showSkip && widget.onSkip != null) ...[
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: widget.onSkip,
                      child: Text(
                        'Bypass Initialization',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
