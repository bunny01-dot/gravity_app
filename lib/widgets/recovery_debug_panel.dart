import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecoveryDebugPanel {
  static const String _sessionSnapshotKey = 'app_session_snapshot_v1';
  static const String _backgroundFlagKey = 'app_in_background';
  static const String _lastRecoveryExitReasonKey = 'last_recovery_exit_reason';
  static const String _lastRecoveryDurationMsKey = 'last_recovery_duration_ms';
  static const String _lastLifecyclePathKey = 'last_lifecycle_path';
  static const String _lastLifecyclePathTsKey = 'last_lifecycle_path_ts';

  static String _formatMillis(dynamic millis) {
    final value = millis is int ? millis : int.tryParse(millis.toString());
    if (value == null || value <= 0) return 'n/a';
    return DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
  }

  static Widget _debugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> show(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final reason = prefs.getString(_lastRecoveryExitReasonKey) ?? 'n/a';
    final duration = prefs.getInt(_lastRecoveryDurationMsKey);
    final snapshotRaw = prefs.getString(_sessionSnapshotKey);
    Map<String, dynamic> snapshot = {};
    if (snapshotRaw != null && snapshotRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(snapshotRaw);
        if (decoded is Map) {
          snapshot = Map<String, dynamic>.from(
            decoded.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      } catch (_) {}
    }

    final pendingRecovery = snapshot['pending_recovery']?.toString() ?? 'n/a';
    final homeRoute = snapshot['home_route']?.toString() ?? 'n/a';
    final savedAt = _formatMillis(snapshot['saved_at']);
    final backgroundAt = _formatMillis(snapshot['background_at']);
    final inBackground = prefs.getBool(_backgroundFlagKey) ?? false;
    final lifecyclePath = prefs.getString(_lastLifecyclePathKey) ?? 'n/a';
    final lifecycleAt = _formatMillis(prefs.getInt(_lastLifecyclePathTsKey));

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: const Text(
            'Recovery Debug',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _debugRow('Exit reason', reason),
                _debugRow(
                  'Exit duration',
                  duration == null ? 'n/a' : '$duration ms',
                ),
                _debugRow('Pending recovery', pendingRecovery),
                _debugRow('Background flag', inBackground.toString()),
                _debugRow('Lifecycle path', lifecyclePath),
                _debugRow('Lifecycle at', lifecycleAt),
                _debugRow('Home route', homeRoute),
                _debugRow('Snapshot saved', savedAt),
                _debugRow('Background at', backgroundAt),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
