import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Refresh loader that always shows only Lottie animation.
class RefreshLottieLoader extends StatelessWidget {
  const RefreshLottieLoader({
    super.key,
    required this.message,
    this.subtitle,
    this.animationAsset = 'assets/lottie/loading.json',
    this.lottieDelay = const Duration(seconds: 5),
  });

  final String message;
  final String? subtitle;
  final String animationAsset;
  final Duration lottieDelay;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 160,
        height: 160,
        child: Lottie.asset(
          animationAsset,
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
        ),
      ),
    );
  }
}
