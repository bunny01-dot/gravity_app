import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A reusable widget that displays a centered progressive loading bar with percentage.
/// Replaces all circular/indeterminate spinners.
class ProgressiveLoader extends StatefulWidget {
  final double?
  progress; // 0.0 to 1.0. If null, internal simulated progress is used.
  final String? loadingText;
  final Color? color;
  final bool isCompleted;

  const ProgressiveLoader({
    super.key,
    this.progress,
    this.loadingText,
    this.color,
    this.isCompleted = false,
  });

  @override
  State<ProgressiveLoader> createState() => _ProgressiveLoaderState();
}

class _ProgressiveLoaderState extends State<ProgressiveLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _simulatedController;
  late Animation<double> _simulatedAnimation;

  @override
  void initState() {
    super.initState();
    // Simulate progress from 0.0 to 0.9 if no explicit progress is provided
    _simulatedController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _simulatedAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(
        parent: _simulatedController,
        curve: Curves.fastOutSlowIn,
      ),
    );

    if (widget.progress == null) {
      _simulatedController.forward();
    }
  }

  @override
  void didUpdateWidget(ProgressiveLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress == null && oldWidget.progress != null) {
      _simulatedController.forward();
    } else if (widget.progress != null) {
      _simulatedController.stop();
    }
  }

  @override
  void dispose() {
    _simulatedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If completed is true, we force show 1.0 briefly (logic handled by parent usually,
    // but here we ensure visual completeness)

    return AnimatedBuilder(
      animation: _simulatedAnimation,
      builder: (context, child) {
        final double currentProgress = widget.isCompleted
            ? 1.0
            : (widget.progress ?? _simulatedAnimation.value);

        final int percentage = (currentProgress * 100).toInt().clamp(0, 100);
        final Color activeColor = widget.color ?? const Color(0xFF4FACFE);

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Loading Text
              Text(
                widget.isCompleted
                    ? "Complete!"
                    : (widget.loadingText ?? "Loading..."),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),

              // Progress Bar Container
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        // Background Track
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Fill
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: constraints.maxWidth * currentProgress,
                              height: 8,
                              decoration: BoxDecoration(
                                color: activeColor,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: activeColor.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Percentage Text
                    Text(
                      "$percentage%",
                      style: TextStyle(
                        color: activeColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms);
      },
    );
  }
}
