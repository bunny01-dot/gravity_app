import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/analytics_service.dart';

class MasteryCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String animationType;
  final double progress; // 0.0 to 1.0
  final VoidCallback onTap;
  final bool showSafeBadge; // For Black Hole only

  const MasteryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.animationType = 'scale',
    this.progress = 0.0,
    this.showSafeBadge = false,
  });

  @override
  State<MasteryCard> createState() => _MasteryCardState();
}

class _MasteryCardState extends State<MasteryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    // Log analytics
    final cardType = widget.title.toLowerCase().replaceAll(' ', '_');
    AnalyticsService().logEvent('mastery_card_clicked_$cardType');

    await _tapController.forward();
    await _tapController.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.9).animate(
          CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
              // Outer Glow based on progress
              if (widget.progress > 0)
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.2 * widget.progress),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Progress Border (Custom Painter)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ProgressBorderPainter(
                          progress: widget.progress,
                          color: widget.color,
                          width: 3.0,
                        ),
                      ),
                    ),

                    // 2. Content
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated Icon Container
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: widget.color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.color.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    spreadRadius: -5,
                                  ),
                                ],
                              ),
                              child: _buildAnimatedIcon(
                                widget.icon,
                                widget.color,
                                widget.animationType,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.title,
                              textAlign:
                                  TextAlign.center, // Enable center alignment
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Safe Badge (Black Hole only)
                    if (widget.showSafeBadge)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: _buildSafeBadge(),
                      ),

                    // 4. Percentage Badge ("Small page like card")
                    if (widget.progress > 0)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _buildPercentageCard(
                          widget.progress,
                          widget.color,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  Widget _buildPercentageCard(double val, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C35), // Darker card background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 10,
            color: c.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            "${(val * 100).toInt()}%",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slide(begin: const Offset(0, 0.2));
  }

  Widget _buildSafeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, size: 14, color: Colors.greenAccent),
          const SizedBox(width: 6),
          const Flexible(
            child: Text(
              'Uses only learned words',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildAnimatedIcon(IconData icon, Color color, String type) {
    Widget animatedIcon = Icon(icon, color: color, size: 40);

    // Reuse/Adapt animations from Dashboard
    switch (type) {
      case 'float':
        return animatedIcon
            .animate(onPlay: (c) => c.repeat())
            .moveY(
              begin: 0,
              end: -5,
              duration: 2500.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .moveY(
              begin: -5,
              end: 0,
              duration: 2500.ms,
              curve: Curves.easeInOut,
            );
      case 'pulse':
        return animatedIcon
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.15, 1.15),
              duration: 1500.ms,
            )
            .then()
            .scale(
              begin: const Offset(1.15, 1.15),
              end: const Offset(1, 1),
              duration: 1500.ms,
            );
      case 'wave':
        return animatedIcon
            .animate(onPlay: (c) => c.repeat())
            .moveX(begin: -2, end: 2, duration: 1200.ms)
            .then()
            .moveX(begin: 2, end: -2, duration: 1200.ms);
      case 'bell':
        return animatedIcon
            .animate(onPlay: (c) => c.repeat())
            .rotate(begin: -0.05, end: 0.05, duration: 1.seconds)
            .then()
            .rotate(begin: 0.05, end: -0.05, duration: 1.seconds);
      case 'rotate':
        return animatedIcon
            .animate(onPlay: (c) => c.repeat())
            .rotate(duration: 5.seconds);
      default:
        return animatedIcon;
    }
  }
}

class _ProgressBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double width;

  _ProgressBorderPainter({
    required this.progress,
    required this.color,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    // Create Path
    final path = Path()..addRRect(rrect);

    // Get Metrics
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final pathLength = metric.length;
    final extractLength = pathLength * progress;

    // Extract Path
    final extractPath = metric.extractPath(0.0, extractLength);

    // Paint Glow
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width + 4
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(extractPath, glowPaint);

    // Paint Stroke
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = color;
    // ..shader = LinearGradient(colors: [color, Colors.white]).createShader(rect); // Optional Gradient

    canvas.drawPath(extractPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressBorderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
