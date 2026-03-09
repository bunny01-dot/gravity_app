import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gravity_app/services/notification_service.dart';
import 'package:gravity_app/models/notification_permission_status.dart';

/// ISSUE #2: Student Notification Permission Tutorial
/// Shows when notifications are disabled to guide users to enable them
class NotificationPermissionTutorial extends StatefulWidget {
  final VoidCallback? onComplete;
  final bool isStudent;

  const NotificationPermissionTutorial({
    super.key,
    this.onComplete,
    this.isStudent = true,
  });

  @override
  State<NotificationPermissionTutorial> createState() =>
      _NotificationPermissionTutorialState();
}

class _NotificationPermissionTutorialState
    extends State<NotificationPermissionTutorial> {
  final NotificationService _notificationService = NotificationService();
  NotificationPermissionStatus _currentStatus =
      NotificationPermissionStatus.unknown;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await _notificationService.checkPermissionStatus();
    if (mounted) {
      setState(() {
        _currentStatus = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleEnableNotifications() async {
    setState(() => _isLoading = true);

    if (_currentStatus.requiresSettings) {
      // User must go to settings
      await openAppSettings();

      // Wait for user to return, then re-check
      await Future.delayed(const Duration(seconds: 2));
      await _checkPermissionStatus();
    } else {
      // Try to request permission
      final granted = await _notificationService.requestPermission();

      if (granted) {
        // Success!
        await _notificationService.markTutorialDismissed();
        if (mounted) {
          Navigator.of(context).pop();
          widget.onComplete?.call();
        }
      } else {
        // Permission denied, check if permanently
        await _checkPermissionStatus();
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDismiss() async {
    await _notificationService.markTutorialDismissed();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1E2C), Color(0xFF2A2A35)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF4FACFE).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4FACFE).withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4FACFE)),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          size: 48,
                          color: Color(0xFFFFD700),
                        ),
                      )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut)
                      .shimmer(
                        duration: 1500.ms,
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      ),

                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Enable Notifications',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    widget.isStudent
                        ? 'Stay updated with important announcements and reminders from your teacher!'
                        : 'Enable notifications to receive important updates and reminders.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Benefits List
                  _buildBenefitItem(
                    Icons.campaign_rounded,
                    'Teacher Announcements',
                    'Get notified about important class updates',
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem(
                    Icons.task_alt_rounded,
                    'Task Reminders',
                    'Never miss your daily vocabulary practice',
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem(
                    Icons.celebration_rounded,
                    'Achievement Alerts',
                    'Celebrate your learning milestones',
                  ),

                  const SizedBox(height: 32),

                  // Status-specific instructions
                  if (_currentStatus.requiresSettings) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4757).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF4757).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFFF4757),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Notifications are blocked. Please enable them in your phone settings.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: _handleEnableNotifications,
                        icon: Icon(
                          _currentStatus.requiresSettings
                              ? Icons.settings_rounded
                              : Icons.notifications_active_rounded,
                        ),
                        label: Text(
                          _currentStatus.requiresSettings
                              ? 'Open Settings'
                              : 'Enable Notifications',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4FACFE),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _handleDismiss,
                        child: const Text(
                          'Maybe Later',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4FACFE).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF4FACFE)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Helper function to show the tutorial
Future<void> showNotificationPermissionTutorial(
  BuildContext context, {
  bool isStudent = true,
  VoidCallback? onComplete,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => NotificationPermissionTutorial(
      isStudent: isStudent,
      onComplete: onComplete,
    ),
  );
}
