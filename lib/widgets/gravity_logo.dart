import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GravityLogo extends StatelessWidget {
  final double size;

  const GravityLogo({super.key, this.size = 200.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset('assets/images/app_logo.png', fit: BoxFit.contain)
          .animate()
          .fade(duration: 800.ms)
          .scale(
            duration: 800.ms,
            curve: Curves.easeOutBack,
            begin: const Offset(0.5, 0.5),
          )
          .then()
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          ) // Continuous subtle breathing
          .scaleXY(
            begin: 1.0,
            end: 1.05,
            duration: 2.5.seconds,
            curve: Curves.easeInOut,
          ),
    );
  }
}
