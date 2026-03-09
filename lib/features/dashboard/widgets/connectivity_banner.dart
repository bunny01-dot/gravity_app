import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ConnectivityBanner extends StatelessWidget {
  final bool isConnected;
  final bool showSuccess;

  const ConnectivityBanner({
    super.key,
    required this.isConnected,
    this.showSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isConnected && !showSuccess) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    bool isOnline = isConnected;

    return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: isOnline
              ? colorScheme
                    .tertiary // online
              : colorScheme.error, // offline
          child: SafeArea(
            top: false,
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: isOnline
                      ? colorScheme.onTertiary
                      : colorScheme.onError,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isOnline ? "Connected" : "No Internet Connection",
                  style: TextStyle(
                    color: isOnline
                        ? colorScheme.onTertiary
                        : colorScheme.onError,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 1, end: 0, duration: 250.ms);
  }
}
