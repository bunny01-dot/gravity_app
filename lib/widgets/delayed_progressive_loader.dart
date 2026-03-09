import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gravity_app/widgets/progressive_loader.dart';

/// Intelligent loader wrapper that only shows progress UI if loading takes > 500ms.
/// Prevents unnecessary visual noise for fast operations.
///
/// Usage:
/// ```dart
/// DelayedProgressiveLoader(
///   isLoading: _isLoading,
///   loadingText: "Preparing lesson...",
///   child: YourContentWidget(),
/// )
/// ```
class DelayedProgressiveLoader extends StatefulWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingText;
  final Color? color;
  final Duration delay;

  const DelayedProgressiveLoader({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingText,
    this.color,
    this.delay = const Duration(milliseconds: 500),
  });

  @override
  State<DelayedProgressiveLoader> createState() =>
      _DelayedProgressiveLoaderState();
}

class _DelayedProgressiveLoaderState extends State<DelayedProgressiveLoader> {
  bool _showLoader = false;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _updateLoaderVisibility();
  }

  @override
  void didUpdateWidget(DelayedProgressiveLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      _updateLoaderVisibility();
    }
  }

  void _updateLoaderVisibility() {
    if (widget.isLoading) {
      // Start loading -> set timer to show loader after delay
      _delayTimer?.cancel();
      _delayTimer = Timer(widget.delay, () {
        if (mounted && widget.isLoading) {
          setState(() => _showLoader = true);
        }
      });
    } else {
      // Loading complete -> cancel timer and hide loader immediately
      _delayTimer?.cancel();
      if (_showLoader) {
        setState(() => _showLoader = false);
      }
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RULES:
    // 1. If loading completes within delay -> show child immediately (no loader)
    // 2. If loading exceeds delay -> show loader
    // 3. Never flash loader briefly

    if (!widget.isLoading) {
      return widget.child;
    }

    if (_showLoader) {
      return ProgressiveLoader(
        loadingText: widget.loadingText,
        color: widget.color,
      );
    }

    // Still loading but within delay window -> show nothing (prevents flash)
    return const SizedBox.shrink();
  }
}
