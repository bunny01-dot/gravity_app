part of 'main.dart';

class RecoveryLoadingScreen extends StatelessWidget {
  const RecoveryLoadingScreen({
    super.key,
    required this.phaseName,
    required this.instanceId,
    required this.recoverySerial,
    this.onSkip,
  });

  final String phaseName;
  final int instanceId;
  final int recoverySerial;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return _RecoveryLoadingScreenContent(
      phaseName: phaseName,
      instanceId: instanceId,
      recoverySerial: recoverySerial,
      onSkip: onSkip,
    );
  }
}

class _RefreshingLottieIndicator extends StatefulWidget {
  const _RefreshingLottieIndicator({
    super.key,
    this.size = 140,
    this.showImmediately = false,
  });

  final double size;
  final bool showImmediately;

  @override
  State<_RefreshingLottieIndicator> createState() =>
      _RefreshingLottieIndicatorState();
}

class _RefreshingLottieIndicatorState
    extends State<_RefreshingLottieIndicator> {
  Timer? _lottieTimer;
  bool _showLottie = false;

  @override
  void initState() {
    super.initState();
    _showLottie = widget.showImmediately;
    if (_showLottie) {
      return;
    }
    _lottieTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _showLottie = true);
    });
  }

  @override
  void dispose() {
    _lottieTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(
        child: _showLottie
            ? Lottie.asset(
                'assets/lottie/loading.json',
                fit: BoxFit.contain,
                repeat: true,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFF4FACFE),
                    ),
                  );
                },
              )
            : const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF4FACFE),
                ),
              ),
      ),
    );
  }
}

class _RecoveryLoadingScreenContent extends StatefulWidget {
  const _RecoveryLoadingScreenContent({
    required this.phaseName,
    required this.instanceId,
    required this.recoverySerial,
    this.onSkip,
  });

  final String phaseName;
  final int instanceId;
  final int recoverySerial;
  final VoidCallback? onSkip;

  @override
  State<_RecoveryLoadingScreenContent> createState() =>
      _RecoveryLoadingScreenContentState();
}

class _RecoveryLoadingScreenContentState
    extends State<_RecoveryLoadingScreenContent> {
  bool _showSkipButton = false;
  Timer? _skipTimer;

  @override
  void initState() {
    super.initState();
    _skipTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showSkipButton = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _skipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _RefreshingLottieIndicator(size: 156),
                if (_showSkipButton && widget.onSkip != null) ...[
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: widget.onSkip,
                    child: Text(
                      'Taking too long? Skip',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BlockingRecoveryOverlay extends StatelessWidget {
  const BlockingRecoveryOverlay({
    super.key,
    required this.phaseName,
    required this.instanceId,
    required this.recoverySerial,
  });

  final String phaseName;
  final int instanceId;
  final int recoverySerial;

  @override
  Widget build(BuildContext context) {
    final scrimColor = Theme.of(
      context,
    ).colorScheme.scrim.withValues(alpha: 0.8);
    return Stack(
      children: [
        ModalBarrier(dismissible: false, color: scrimColor),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RefreshingLottieIndicator(
                key: ValueKey('recovery_lottie_$recoverySerial'),
                showImmediately: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  static const int _debugTapThreshold = 5;
  static const Duration _debugTapWindow = Duration(seconds: 2);
  static const String _appVersionLabel = 'v3.0.0+17';
  int _versionTapCount = 0;
  DateTime? _lastVersionTapAt;

  void _onVersionTapped() {
    final now = DateTime.now();
    if (_lastVersionTapAt == null ||
        now.difference(_lastVersionTapAt!) > _debugTapWindow) {
      _versionTapCount = 1;
    } else {
      _versionTapCount += 1;
    }
    _lastVersionTapAt = now;

    if (_versionTapCount >= _debugTapThreshold) {
      _versionTapCount = 0;
      unawaited(RecoveryDebugPanel.show(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6A11CB).withValues(alpha: 0.3),
                backgroundBlendMode: BlendMode.screen,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2575FC).withValues(alpha: 0.3),
                backgroundBlendMode: BlendMode.screen,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'welcome to',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onLongPress: () =>
                        unawaited(RecoveryDebugPanel.show(context)),
                    behavior: HitTestBehavior.opaque,
                    child: const GravityLogo(size: 180),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'English Learning App',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Anything is possible',
                    style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 64),
                  FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'get started',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: _onVersionTapped,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        _appVersionLabel,
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.6,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
