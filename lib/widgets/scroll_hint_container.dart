import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ScrollHintContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ScrollHintContainer({super.key, required this.child, this.padding});

  @override
  State<ScrollHintContainer> createState() => _ScrollHintContainerState();
}

class _ScrollHintContainerState extends State<ScrollHintContainer> {
  final ScrollController _scrollController = ScrollController();
  bool _canScroll = false;
  bool _atBottom = false;

  @override
  void initState() {
    super.initState();
    // Initial check post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Check if scrollable
    final canScroll = maxScroll > 0;

    // Check if at bottom (with threshold)
    final atBottom = currentScroll >= (maxScroll - 20);

    if (canScroll != _canScroll || atBottom != _atBottom) {
      if (mounted) {
        setState(() {
          _canScroll = canScroll;
          _atBottom = atBottom;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        _checkScroll();
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _checkScroll();
          return false; // Allow bubble up
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: widget.padding,
              physics: const BouncingScrollPhysics(),
              child: widget.child,
            ),

            // Subtle Gradient Fade
            if (_canScroll && !_atBottom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 40,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 
                            0.0,
                          ), // Ideally transparent
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Scroll Hint Pill
            if (_canScroll && !_atBottom)
              Positioned(
                bottom: 12,
                right: 12,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "More",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                              Icons.arrow_downward_rounded,
                              size: 12,
                              color: Colors.cyanAccent,
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .moveY(begin: -2, end: 2, duration: 800.ms),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
