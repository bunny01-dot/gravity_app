import 'package:flutter/material.dart';

class DailyTaskProgressIndicator extends StatefulWidget {
  final double progress;
  final double height;
  final Color color;
  final Color backgroundColor;
  final TextStyle? textStyle;
  final bool showPercent;

  const DailyTaskProgressIndicator({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.color = Colors.cyanAccent,
    this.backgroundColor = Colors.white10,
    this.textStyle,
    this.showPercent = true,
  });

  @override
  State<DailyTaskProgressIndicator> createState() =>
      _DailyTaskProgressIndicatorState();
}

class _DailyTaskProgressIndicatorState extends State<DailyTaskProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Initial animation from 0 -> target
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void didUpdateWidget(DailyTaskProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      final double oldProgress = _animation.value;
      final double newProgress = widget.progress.clamp(0.0, 1.0);

      _animation = Tween<double>(begin: oldProgress, end: newProgress).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double currentProgress = _animation.value;
        final int percent = (currentProgress * 100).toInt();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showPercent)
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(
                  "$percent%",
                  style:
                      widget.textStyle ??
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(widget.height / 2),
              child: LinearProgressIndicator(
                value: currentProgress,
                backgroundColor: widget.backgroundColor,
                color: widget.color,
                minHeight: widget.height,
              ),
            ),
          ],
        );
      },
    );
  }
}
