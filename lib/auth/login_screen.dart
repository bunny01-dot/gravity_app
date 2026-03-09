import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gravity_app/widgets/gravity_logo.dart';
import 'package:gravity_app/auth/signup_screen.dart';
import 'package:gravity_app/dashboard.dart';
import 'package:gravity_app/teacher_dashboard.dart';
import 'package:gravity_app/services/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/placement_state_service.dart';
import 'package:gravity_app/screens/placement_entry_screen.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginLoading = false;
  bool _showTapFlash = false;
  int _loginButtonAnimationNonce = 0;
  static const Duration _minimumLoginAnimationTime = Duration(
    milliseconds: 900,
  );

  Future<void> _ensureLoginAnimationVisible(DateTime startedAt) async {
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _minimumLoginAnimationTime) {
      await Future<void>.delayed(_minimumLoginAnimationTime - elapsed);
    }
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _isLoginLoading = true;
      _showTapFlash = true;
      _loginButtonAnimationNonce++;
    });
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || !_isLoginLoading || !_showTapFlash) return;
      setState(() {
        _showTapFlash = false;
      });
    });
    final loaderStartTime = DateTime.now();
    bool didNavigate = false;
    // Give the button one frame to render the loading animation.
    await Future<void>.delayed(const Duration(milliseconds: 16));
    try {
      final user = await AuthService().signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Persist Login and User Role
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);

      // Store user role (teacher or student)
      final userRole = AuthService().getUserRole(user?.email);
      await prefs.setString('user_role', userRole);
      await prefs.setString('user_email', user?.email ?? '');

      // Try to sync data from cloud, but allow login to proceed if offline
      try {
        await DataService().syncProgressFromCloud().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('[WARN] Cloud sync timed out - will retry later');
            throw TimeoutException('Cloud sync timeout');
          },
        );
        debugPrint('OK: Progress synced from cloud');
      } catch (e) {
        debugPrint('[WARN] Cloud sync failed (offline mode): $e');
        // Show info snackbar but don't block login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Logged in offline. Progress will sync when online.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      // Navigate to appropriate dashboard based on role
      if (!mounted) return;
      await _ensureLoginAnimationVisible(loaderStartTime);
      if (!mounted) return;
      if (userRole == 'teacher') {
        didNavigate = true;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TeacherDashboard()),
          (route) => false,
        );
      } else {
        await PlacementStateService.ensureInitialized();
        if (!mounted) return;
        final status = await PlacementStateService.getPlacementQuizStatus();
        if (!mounted) return;
        final hasCompleted = status == PlacementStateService.statusCompleted;
        didNavigate = true;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => hasCompleted
                ? const DashboardScreen()
                : const PlacementEntryScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      await _ensureLoginAnimationVisible(loaderStartTime);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (!didNavigate) {
        await _ensureLoginAnimationVisible(loaderStartTime);
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoginLoading = false;
          _showTapFlash = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _isLoginLoading = false;
    });
    try {
      final user = await AuthService().signInWithGoogle();

      if (user == null) {
        // User canceled the sign-in
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLoginLoading = false;
          });
        }
        return;
      }

      // Persist Login and User Role
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);

      // Store user role (teacher or student)
      final userRole = AuthService().getUserRole(user.email);
      await prefs.setString('user_role', userRole);
      await prefs.setString('user_email', user.email ?? '');

      // Try to sync data from cloud
      try {
        await DataService().syncProgressFromCloud().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('[WARN] Cloud sync timed out - will retry later');
            throw TimeoutException('Cloud sync timeout');
          },
        );
        debugPrint('OK: Progress synced from cloud');
      } catch (e) {
        debugPrint('[WARN] Cloud sync failed (offline mode): $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Logged in offline. Progress will sync when online.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      // Navigate to appropriate dashboard based on role
      if (!mounted) return;
      if (userRole == 'teacher') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TeacherDashboard()),
          (route) => false,
        );
      } else {
        await PlacementStateService.ensureInitialized();
        if (!mounted) return;
        final status = await PlacementStateService.getPlacementQuizStatus();
        if (!mounted) return;
        final hasCompleted = status == PlacementStateService.statusCompleted;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => hasCompleted
                ? const DashboardScreen()
                : const PlacementEntryScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoginLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final cardFill = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.78);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    final gradientColors = isDark
        ? const [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]
        : const [Color(0xFFEFF5FF), Color(0xFFE3EEFF), Color(0xFFD5E6FF)];

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background (Space Theme)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
          ),

          // 2. Stars/Nebula decoration (Circles)
          Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark
                            ? Colors.purple
                            : const Color(0xFF4FACFE))
                        .withValues(alpha: isDark ? 0.3 : 0.22),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark
                                ? Colors.purple
                                : const Color(0xFF4FACFE))
                            .withValues(alpha: isDark ? 0.5 : 0.28),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                duration: 4.seconds,
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
              ),

          Positioned(
                bottom: 100,
                left: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark
                            ? Colors.blueAccent
                            : const Color(0xFF00D3FF))
                        .withValues(alpha: isDark ? 0.3 : 0.22),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark
                                ? Colors.blueAccent
                                : const Color(0xFF00D3FF))
                            .withValues(alpha: isDark ? 0.5 : 0.28),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(duration: 5.seconds, begin: 0, end: 30),

          // 3. Glassmorphism Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cardFill,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        const GravityLogo(size: 80),
                        const SizedBox(height: 16),
                        Text(
                              "Welcome Back",
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .moveY(begin: 10, end: 0),

                        const SizedBox(height: 40),

                        // Inputs
                        _buildGlassTextField(
                          "Email",
                          Icons.email_outlined,
                          false,
                          _emailController,
                        ),
                        const SizedBox(height: 20),
                        _buildGlassTextField(
                          "Password",
                          Icons.lock_outline,
                          true,
                          _passwordController,
                        ),

                        const SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: FilledButton(
                            onPressed: _handleLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: _isLoginLoading
                                  ? (isDark
                                        ? const Color(0xFF2A1D12)
                                        : const Color(0xFFE5ECF6))
                                  : primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoginLoading
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox.expand(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: _showTapFlash
                                            ? Lottie.asset(
                                                'assets/lottie/button_tap_feedback.json',
                                                key: ValueKey(
                                                  'login_tap_fx_$_loginButtonAnimationNonce',
                                                ),
                                                fit: BoxFit.cover,
                                                repeat: false,
                                              )
                                            : ColorFiltered(
                                                key: ValueKey(
                                                  'login_loading_$_loginButtonAnimationNonce',
                                                ),
                                                colorFilter:
                                                    ColorFilter.mode(
                                                      isDark
                                                          ? const Color(
                                                              0xFFFFA726,
                                                            )
                                                          : primary,
                                                      BlendMode.srcATop,
                                                    ),
                                                child: Lottie.asset(
                                                  'assets/lottie/loading.json',
                                                  fit: BoxFit.cover,
                                                  repeat: true,
                                                ),
                                              ),
                                      ),
                                    ),
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider with "OR"
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: onSurface.withValues(alpha: 0.24),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                "OR",
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.55),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: onSurface.withValues(alpha: 0.24),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Google Sign-In Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: onSurface.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: onSurface.withValues(alpha: 0.05),
                            ),
                            icon: Image.network(
                              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                              height: 24,
                              width: 24,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.g_mobiledata,
                                    color: onSurface,
                                  ),
                            ),
                            label: Text(
                              "Continue with Google",
                              style: TextStyle(
                                color: onSurface,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sign Up Link
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: onSurface.withValues(alpha: 0.7),
                              ),
                              children: [
                                TextSpan(text: "Don't have an account? "),
                                TextSpan(
                                  text: "Sign Up",
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField(
    String hint,
    IconData icon,
    bool isPassword,
    TextEditingController controller,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: onSurface),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: onSurface.withValues(alpha: 0.6)),
          hintText: hint,
          hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.45)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
