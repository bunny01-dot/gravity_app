import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final bool isConnected;

  const OfflineBanner({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    // Only show if NOT connected
    if (isConnected) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.redAccent,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            "No Connection - You are offline",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
