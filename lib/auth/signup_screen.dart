import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gravity_app/services/auth_service.dart';
import 'package:gravity_app/screens/asset_download_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/teacher_notification_service.dart';
import 'package:lottie/lottie.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
    // Validate name
    if (_nameController.text.trim().isEmpty) {
      _showError("Please enter your name");
      return;
    }

    // Validate email
    if (_emailController.text.trim().isEmpty) {
      _showError("Please enter your email");
      return;
    }

    if (!_emailController.text.trim().contains('@')) {
      _showError("Please enter a valid email address");
      return;
    }

    // Validate password
    if (_passwordController.text.isEmpty) {
      _showError("Please enter a password");
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError("Password must be at least 6 characters long");
      return;
    }

    // Validate password match
    if (_passwordController.text != _confirmController.text) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await AuthService().signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_name', _nameController.text.trim());

      final userRole = AuthService().getUserRole(user?.email);
      await prefs.setString('user_role', userRole);
      await prefs.setString('user_email', user?.email ?? '');

      // Notify Teacher of New Sign Up
      if (user != null) {
        TeacherNotificationService().sendStudentActivityNotification(
          studentId: user.uid,
          studentName: _nameController.text.trim(),
          activityType: 'new_student_signup',
          details: 'New student joined: ${_nameController.text.trim()}',
        );
      }

      // Navigate to asset download screen for initial setup
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => AssetDownloadScreen(userRole: userRole),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final cardFill = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.8);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    final gradientColors = isDark
        ? const [Color(0xFF2C3E50), Color(0xFF000000)]
        : const [Color(0xFFF1F6FF), Color(0xFFDDEBFF)];

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomRight,
                end: Alignment.topLeft,
                colors: gradientColors,
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: onSurface.withValues(alpha: 0.9),
              ),
            ),
          ),

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
                        Text(
                          "Create Account",
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),

                        const SizedBox(height: 30),

                        _buildGlassTextField(
                          "Name",
                          Icons.person_outline,
                          false,
                          _nameController,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          "Email",
                          Icons.email_outlined,
                          false,
                          _emailController,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          "Password",
                          Icons.lock_outline,
                          true,
                          _passwordController,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          "Confirm Password",
                          Icons.lock_outline,
                          true,
                          _confirmController,
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _handleSignUp,
                            style: FilledButton.styleFrom(
                              backgroundColor: primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Lottie.asset(
                                      'assets/lottie/loading.json',
                                      fit: BoxFit.contain,
                                      repeat: true,
                                    ),
                                  )
                                : const Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
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
    TextEditingController? controller,
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
