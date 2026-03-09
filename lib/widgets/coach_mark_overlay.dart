import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

enum CoachMarkHighlightShape { roundedRect, pill, circle }

class CoachMarkOverlay extends StatelessWidget {
  final Rect? targetRect;
  final String title;
  final String message;
  final VoidCallback onDismiss;
  final Alignment targetAlignment;
  final Color accentColor;
  final bool allowTargetInteraction;
  final CoachMarkHighlightShape highlightShape;
  final EdgeInsets highlightPadding;

  const CoachMarkOverlay({
    super.key,
    this.targetRect,
    required this.title,
    required this.message,
    required this.onDismiss,
    this.targetAlignment = Alignment.center,
    this.accentColor = const Color(0xFF4FACFE),
    this.allowTargetInteraction = false,
    this.highlightShape = CoachMarkHighlightShape.roundedRect,
    this.highlightPadding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final highlightedRect = _buildHighlightRect(targetRect);

    return Stack(
      children: [
        // 1. Visual Layer (Passive)
        // We use IgnorePointer so this layer doesn't affect hit testing at all.
        // It provides the unified dark look with the "cut out".
        IgnorePointer(
          child: ClipPath(
            clipper: _InvertedRectClipper(
              highlightedRect,
              highlightShape: highlightShape,
            ),
            child: Container(
              color: Colors.black.withValues(alpha: 0.85), // Strong dark focus
            ),
          ),
        ),

        // 2. Interaction Layer
        // Default behavior: block all background interaction and scrolling.
        if (!allowTargetInteraction)
          Positioned.fill(
            child: ModalBarrier(
              color: Colors.transparent,
              dismissible: true,
              onDismiss: onDismiss,
            ),
          )
        else if (highlightedRect != null) ...[
          // Optional behavior: keep a hole around target for direct interaction.
          Positioned(
            top: 0,
            left: 0,
            width: screenSize.width,
            height: highlightedRect.top,
            child: _buildBlocker(),
          ),
          Positioned(
            top: highlightedRect.bottom,
            left: 0,
            width: screenSize.width,
            height: screenSize.height - highlightedRect.bottom,
            child: _buildBlocker(),
          ),
          Positioned(
            top: highlightedRect.top,
            left: 0,
            width: highlightedRect.left,
            height: highlightedRect.height,
            child: _buildBlocker(),
          ),
          Positioned(
            top: highlightedRect.top,
            left: highlightedRect.right,
            width: screenSize.width - highlightedRect.right,
            height: highlightedRect.height,
            child: _buildBlocker(),
          ),
        ] else
          Positioned.fill(child: _buildBlocker()),

        // 3. Highlight Animation (Visual Only)
        if (highlightedRect != null)
          Positioned(
            left: highlightedRect.left - 12,
            top: highlightedRect.top - 12,
            width: highlightedRect.width + 24,
            height: highlightedRect.height + 24,
            child: IgnorePointer(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Ripple (Subtle)
                  Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            _cornerRadiusForRect(
                              Rect.fromLTWH(
                                0,
                                0,
                                highlightedRect.width + 24,
                                highlightedRect.height + 24,
                              ),
                            ),
                          ),
                          border: Border.all(
                            color: accentColor.withValues(
                              alpha: 0.3,
                            ), // Lower opacity
                            width: 2,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.15, 1.15), // Gentle expansion
                        duration: 2.seconds, // Slower
                        curve: Curves.easeInOut,
                      )
                      .fadeOut(duration: 2.seconds, curve: Curves.easeOut),

                  // Orbiting shimmer ring for a modern spotlight feel.
                  Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            _cornerRadiusForRect(
                              Rect.fromLTWH(
                                0,
                                0,
                                highlightedRect.width + 14,
                                highlightedRect.height + 14,
                              ),
                            ),
                          ),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.22),
                            width: 1.6,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(
                        duration: 1800.ms,
                        color: accentColor.withValues(alpha: 0.46),
                      ),

                  // Inner Glow (Breathing)
                  Container(
                        width: highlightedRect.width + 8, // Match padded hole
                        height: highlightedRect.height + 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            _cornerRadiusForRect(
                              Rect.fromLTWH(
                                0,
                                0,
                                highlightedRect.width + 8,
                                highlightedRect.height + 8,
                              ),
                            ),
                          ),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.05, 1.05), // Very subtle breathing
                        duration: 2.seconds, // Slow breath
                        curve: Curves.easeInOutSine,
                      ),
                ],
              ),
            ),
          ),

        // 4. Message Card (Above Everything)
        _buildMessageCard(context),
      ],
    );
  }

  Rect? _buildHighlightRect(Rect? sourceRect) {
    if (sourceRect == null) return null;

    final paddedRect = Rect.fromLTRB(
      sourceRect.left - highlightPadding.left,
      sourceRect.top - highlightPadding.top,
      sourceRect.right + highlightPadding.right,
      sourceRect.bottom + highlightPadding.bottom,
    );

    if (highlightShape != CoachMarkHighlightShape.circle) {
      return paddedRect;
    }

    final side = math.max(paddedRect.width, paddedRect.height);
    return Rect.fromCenter(
      center: paddedRect.center,
      width: side,
      height: side,
    );
  }

  double _cornerRadiusForRect(Rect rect) {
    switch (highlightShape) {
      case CoachMarkHighlightShape.roundedRect:
        return 14;
      case CoachMarkHighlightShape.pill:
        return rect.height / 2;
      case CoachMarkHighlightShape.circle:
        return math.max(rect.width, rect.height) / 2;
    }
  }

  Widget _buildBlocker() {
    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: const SizedBox.expand(),
    );
  }

  Widget _buildMessageCard(BuildContext context) {
    bool showAtTop = false;
    if (targetRect != null) {
      final screenHeight = MediaQuery.of(context).size.height;
      if (targetRect!.top > screenHeight / 2) {
        showAtTop = true;
      }
    }

    return Positioned(
      bottom: showAtTop ? null : 100,
      top: showAtTop ? 100 : null,
      left: 24,
      right: 24,
      child: Center(
        child:
            Container(
                  constraints: const BoxConstraints(maxWidth: 350),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0E1624).withValues(alpha: 0.96),
                        const Color(0xFF1A2540).withValues(alpha: 0.94),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.1),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.tips_and_updates_rounded,
                              color: accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          height: 1.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: onDismiss,
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Got it',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 260.ms)
                .scale(
                  begin: const Offset(0.94, 0.94),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                  duration: 340.ms,
                )
                .slideY(
                  begin: showAtTop ? -0.08 : 0.08,
                  end: 0,
                  duration: 340.ms,
                  curve: Curves.easeOutCubic,
                ),
      ),
    );
  }
}

class _InvertedRectClipper extends CustomClipper<Path> {
  final Rect? highlightRect;
  final CoachMarkHighlightShape highlightShape;

  _InvertedRectClipper(this.highlightRect, {required this.highlightShape});

  @override
  Path getClip(Size size) {
    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (highlightRect != null) {
      final Path holePath = Path();
      switch (highlightShape) {
        case CoachMarkHighlightShape.roundedRect:
          holePath.addRRect(
            RRect.fromRectAndRadius(highlightRect!, const Radius.circular(12)),
          );
          break;
        case CoachMarkHighlightShape.pill:
          holePath.addRRect(
            RRect.fromRectAndRadius(
              highlightRect!,
              Radius.circular(highlightRect!.height / 2),
            ),
          );
          break;
        case CoachMarkHighlightShape.circle:
          holePath.addOval(highlightRect!);
          break;
      }
      return Path.combine(PathOperation.difference, path, holePath);
    }
    return path;
  }

  @override
  bool shouldReclip(_InvertedRectClipper oldClipper) =>
      oldClipper.highlightRect != highlightRect ||
      oldClipper.highlightShape != highlightShape;
}
