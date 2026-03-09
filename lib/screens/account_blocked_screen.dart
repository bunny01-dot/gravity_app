import 'package:flutter/material.dart';

import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/dashboard.dart';
import 'package:gravity_app/teacher_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountBlockedScreen extends StatefulWidget {
  const AccountBlockedScreen({super.key});

  @override
  State<AccountBlockedScreen> createState() => _AccountBlockedScreenState();
}

class _AccountBlockedScreenState extends State<AccountBlockedScreen> {
  bool _isLoading = false;

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);

    // Simulate delay for "checking"
    await Future.delayed(const Duration(seconds: 1));

    final status = await DataService().getUserStatus();
    if (!mounted) return;

    if (status['isBlocked'] == false) {
      // Unblocked! Go to Home.
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final role = prefs.getString('user_role') ?? 'student';
      final target = role == 'teacher'
          ? const TeacherDashboard()
          : const DashboardScreen();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => target),
        (route) => false,
      );
    } else {
      // Still blocked
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Account is still on hold. Please contact your teacher.",
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withValues(alpha: 0.1),
              ),
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_person_rounded,
                    size: 80,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "Account On Hold",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Your learning progress has been paused by your teacher.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHigh.withValues(
                              alpha: 0.6,
                            )
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Approval Required",
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Please write to your teacher to approve your account resuming.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.orangeAccent)
                  else
                    ElevatedButton.icon(
                      onPressed: _checkStatus,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text("Check Status"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
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
