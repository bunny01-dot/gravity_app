import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart' as sensors;

/// Universal space-dust background used across the app.
/// Feather-like fall, consistent speed on every screen.
class SpaceDustBackground extends StatefulWidget {
  const SpaceDustBackground({super.key});

  @override
  State<SpaceDustBackground> createState() => _SpaceDustBackgroundState();
}

class _SpaceDustBackgroundState extends State<SpaceDustBackground>
    with SingleTickerProviderStateMixin {
  static const int _particleCount = 50;

  late final AnimationController _controller;
  final List<_DustParticle> _particles =
      List.generate(_particleCount, (_) => _DustParticle());
  StreamSubscription? _accelerometerSubscription;
  double _gravityX = 0;
  double _gravityY = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _accelerometerSubscription = sensors.accelerometerEventStream().listen((
      event,
    ) {
      if (!mounted) return;
      _gravityX = -event.x * 0.2;
      _gravityY = event.y * 0.2;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (final p in _particles) {
          p.update(_gravityX, _gravityY);
        }
        return CustomPaint(
          painter: _DustPainter(_particles),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _DustParticle {
  static final Random _rng = Random();

  double x = 0;
  double y = 0;
  double baseSpeed = 0;
  double driftAngle = 0;
  double size = 0;
  double opacity = 0;
  double _lastVx = 0;
  double _lastVy = 0;

  _DustParticle() {
    _reset(true);
  }

  void _reset(
    bool initial, {
    double? directionX,
    double? directionY,
  }) {
    if (initial) {
      x = _rng.nextDouble();
      y = _rng.nextDouble();
    } else {
      final dx = directionX ?? _lastVx;
      final dy = directionY ?? _lastVy;
      if (dy > 0.00001) {
        y = -0.2 - (_rng.nextDouble() * 0.3);
      } else if (dy < -0.00001) {
        y = 1.1 + (_rng.nextDouble() * 0.3);
      } else {
        y = _rng.nextDouble();
      }

      if (dx > 0.00001) {
        x = -0.2 - (_rng.nextDouble() * 0.3);
      } else if (dx < -0.00001) {
        x = 1.1 + (_rng.nextDouble() * 0.3);
      } else {
        x = _rng.nextDouble();
      }
    }

    baseSpeed = 0.00050 + (_rng.nextDouble() * 0.00030);
    driftAngle = _rng.nextDouble() * 2 * pi;
    size = 2.0 + (_rng.nextDouble() * 1.8);
    opacity = 0.18 + (_rng.nextDouble() * 0.32);
  }

  void update(double gx, double gy) {
    final double magnitude = sqrt((gx * gx) + (gy * gy));
    final double dirX = magnitude < 0.0001 ? 0 : gx / magnitude;
    final double dirY = magnitude < 0.0001 ? 1 : gy / magnitude;

    // Slight random drift around the gravity direction.
    driftAngle += (_rng.nextDouble() - 0.5) * 0.04;
    final double driftX = cos(driftAngle);
    final double driftY = sin(driftAngle);

    _lastVx = (dirX * baseSpeed) + (driftX * baseSpeed * 0.35);
    _lastVy = (dirY * baseSpeed) + (driftY * baseSpeed * 0.35);

    x += _lastVx;
    y += _lastVy;

    if (y < -0.2 || y > 1.2 || x < -0.2 || x > 1.2) {
      _reset(false, directionX: _lastVx, directionY: _lastVy);
    }
  }
}

class _DustPainter extends CustomPainter {
  final List<_DustParticle> particles;
  _DustPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      paint.color = Colors.white.withValues(alpha: p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
