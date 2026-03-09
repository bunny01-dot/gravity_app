import 'package:flutter/material.dart';

class TeacherNotificationsSection extends StatelessWidget {
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onDebugTap;
  final VoidCallback onBugReportsTap;
  final VoidCallback onSystemSettingsTap;

  const TeacherNotificationsSection({
    super.key,
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
    required this.onDebugTap,
    required this.onBugReportsTap,
    required this.onSystemSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E2C)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFFFFD700);
              }
              return null;
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFFFFD700).withValues(alpha: 0.5);
              }
              return null;
            }),
          ),
        ),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Notifications", style: TextStyle(color: onSurface)),
              subtitle: Text(
                "Receive alerts and updates",
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.62),
                  fontSize: 12,
                ),
              ),
              value: notificationsEnabled,
              onChanged: onNotificationsChanged,
            ),
            Divider(
              color: isDark
                  ? Colors.white10
                  : onSurface.withValues(alpha: 0.12),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Technical Issues (Debug)",
                style: TextStyle(color: onSurface),
              ),
              subtitle: Text(
                "View detailed error logs",
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.62),
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(
                Icons.bug_report_rounded,
                color: Colors.orangeAccent,
              ),
              onTap: onDebugTap,
            ),
            Divider(
              color: isDark
                  ? Colors.white10
                  : onSurface.withValues(alpha: 0.12),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Manual Bug Reports",
                style: TextStyle(color: onSurface),
              ),
              subtitle: Text(
                "View user-submitted bug reports",
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.62),
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(
                Icons.report_problem_rounded,
                color: Colors.orangeAccent,
              ),
              onTap: onBugReportsTap,
            ),
            Divider(
              color: isDark
                  ? Colors.white10
                  : onSurface.withValues(alpha: 0.12),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "System Settings",
                style: TextStyle(color: onSurface),
              ),
              subtitle: Text(
                "Check phone permission settings",
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.62),
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                Icons.settings_applications_rounded,
                color: onSurface.withValues(alpha: 0.62),
              ),
              onTap: onSystemSettingsTap,
            ),
          ],
        ),
      ),
    );
  }
}
