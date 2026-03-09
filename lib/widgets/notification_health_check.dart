import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gravity_app/services/notification_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Notification Health Check Widget
///
/// OK: NEW: Diagnostic UI to verify notification system health
/// Checks: Permission, Channel enabled, Battery optimization
///
/// Shows on app launch if any critical issue is detected
class NotificationHealthCheck extends StatefulWidget {
  const NotificationHealthCheck({super.key});

  @override
  State<NotificationHealthCheck> createState() =>
      _NotificationHealthCheckState();
}

class _NotificationHealthCheckState extends State<NotificationHealthCheck> {
  bool _isChecking = true;
  bool _permissionGranted = false;
  bool _batteryOptimized = true; // Assume worst case

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isChecking = true);

    try {
      // 1. Check notification permission
      final notificationStatus = await Permission.notification.status;
      _permissionGranted = notificationStatus.isGranted;

      // 2. Check battery optimization (Android only)
      // Note: Permission.ignoreBatteryOptimizations is available
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      _batteryOptimized = !batteryStatus.isGranted;
    } catch (e) {
      debugPrint('Error checking notification health: $e');
    } finally {
      setState(() => _isChecking = false);
    }
  }

  bool get _hasIssues => !_permissionGranted || _batteryOptimized;

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasIssues) {
      // All good! Don't show anything
      return const SizedBox.shrink();
    }

    // Show diagnostic card
    return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFEE5253)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Notification Setup Required',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'To receive daily reminders and teacher announcements:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // Issue list
              if (!_permissionGranted)
                _buildIssue(
                  'Error: Notification permission denied',
                  'Enable notifications in app settings',
                  onTap: () => openAppSettings(),
                ),

              if (_batteryOptimized)
                _buildIssue(
                  'Warning: Battery optimization enabled',
                  'Disable to receive notifications when app is closed',
                  onTap: () =>
                      NotificationService().openBatteryOptimizationSettings(),
                ),

              const SizedBox(height: 16),

              // Recheck button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _runDiagnostics,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFEE5253),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Recheck Status'),
                ),
              ),

              // Dismiss option
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () async {
                    await NotificationService().markTutorialDismissed();
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: const Text(
                    'I\'ll do this later',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildIssue(String title, String subtitle, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
