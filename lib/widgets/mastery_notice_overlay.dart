import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/widgets/glass_ui.dart';

/// Mastery Page Notice Overlay with Background Focus Control
///
/// Features:
/// - Background blur/blackout for focus (Isolated Target)
/// - Highlight animation (Ripple + Border) for specific UI elements
/// - Blocks background interaction but allows target interaction
/// - Professional animations
class MasteryNoticeOverlay extends StatefulWidget {
  final String title;
  final String message;
  final Widget? customContent;
  final VoidCallback? onDismiss;
  final String? buttonText;
  final String? secondaryButtonText;
  final IconData? icon;
  final Widget? iconWidget;
  final Color? accentColor;
  final VoidCallback? onSecondaryPressed;

  /// Optional: Global key of the widget to highlight
  final GlobalKey? highlightTargetKey;

  /// Background effect type
  final BackgroundEffect backgroundEffect;

  const MasteryNoticeOverlay({
    super.key,
    required this.title,
    required this.message,
    this.customContent,
    this.onDismiss,
    this.buttonText,
    this.secondaryButtonText,
    this.icon,
    this.iconWidget,
    this.accentColor,
    this.onSecondaryPressed,
    this.highlightTargetKey,
    this.backgroundEffect = BackgroundEffect.blur,
  });

  @override
  State<MasteryNoticeOverlay> createState() => _MasteryNoticeOverlayState();
}

class _MasteryNoticeOverlayState extends State<MasteryNoticeOverlay>
    with TickerProviderStateMixin {
  late AnimationController _highlightController;
  Rect? _highlightRect;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    if (widget.highlightTargetKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateHighlightPosition();
      });
    }
  }

  void _calculateHighlightPosition() {
    if (widget.highlightTargetKey?.currentContext == null) return;
    final RenderBox? renderBox =
        widget.highlightTargetKey!.currentContext!.findRenderObject()
            as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    setState(() {
      _highlightRect = Rect.fromLTWH(
        position.dx,
        position.dy,
        size.width,
        size.height,
      );
    });
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? const Color(0xFFFE5196);
    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Stack(
          children: [
            // 1. Full Screen Blur Background
            Positioned.fill(child: _buildBackgroundOverlay()),

            // 2. Optional Highlight Cutout (if targeting something)
            if (_highlightRect != null)
              Positioned.fill(
                child: ClipPath(
                  clipper: _InvertedRectClipper(_highlightRect),
                  child: Container(color: Colors.transparent),
                ),
              ),

            // 3. Highlight Animation
            if (_highlightRect != null) _buildHighlightAnimation(color),

            // 4. Centered Notice Content
            Align(
              alignment: Alignment.center,
              child: SafeArea(
                minimum: const EdgeInsets.all(24),
                child: _buildNoticeCard(color),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildBackgroundOverlay() {
    final shouldBlur = widget.backgroundEffect == BackgroundEffect.blur;
    final sigma = shouldBlur ? 20.0 : 8.0;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: shouldBlur ? 0.58 : 0.72),
              const Color(
                0xFF020617,
              ).withValues(alpha: shouldBlur ? 0.78 : 0.88),
            ],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildHighlightAnimation(Color color) {
    if (_highlightRect == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _highlightController,
      builder: (context, child) {
        final value = _highlightController.value;
        final rippleScale = 1.0 + (value * 0.3);
        final rippleOpacity = (1.0 - value) * 0.6;
        return Stack(
          children: [
            Positioned(
              left: _highlightRect!.left - 4,
              top: _highlightRect!.top - 4,
              width: _highlightRect!.width + 8,
              height: _highlightRect!.height + 8,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.8), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 12 + (value * 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: _highlightRect!.left - 20,
              top: _highlightRect!.top - 20,
              width: _highlightRect!.width + 40,
              height: _highlightRect!.height + 40,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: _highlightRect!.width * rippleScale,
                    height: _highlightRect!.height * rippleScale,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withValues(alpha: rippleOpacity),
                        width: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: _highlightRect!.center.dx - 24,
              top: _highlightRect!.bottom + 10 + (value * 10),
              child: IgnorePointer(
                child: Icon(Icons.touch_app, size: 40, color: Colors.white)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 500.ms),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoticeCard(Color color) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final endColor = Color.lerp(color, scheme.secondary, 0.55)!;
    const darkBaseTop = Color(0xFF0A1222);
    const darkBaseBottom = Color(0xFF141E31);
    final cardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(
          color.withValues(alpha: 0.2),
          darkBaseTop.withValues(alpha: 0.96),
        ),
        Color.alphaBlend(
          endColor.withValues(alpha: 0.1),
          darkBaseBottom.withValues(alpha: 0.94),
        ),
      ],
    );

    return SizedBox(
      width: double.infinity,
      child: GlassPanel(
        borderRadius: BorderRadius.circular(28),
        borderColor: color.withValues(alpha: 0.55),
        gradient: cardGradient,
        padding: const EdgeInsets.all(28.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 46,
            spreadRadius: 1,
            offset: const Offset(0, 18),
          ),
          BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 28),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.iconWidget != null) ...[
              widget.iconWidget!,
              const SizedBox(height: 24),
            ] else if (widget.icon != null) ...[
              Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.35),
                          endColor.withValues(alpha: 0.25),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Icon(widget.icon, size: 48, color: color),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(
                    duration: 2000.ms,
                    color: color.withValues(alpha: 0.3),
                  )
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1.0, 1.0),
                    duration: 1500.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 24),
            ],
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            if (widget.customContent != null) ...[
              const SizedBox(height: 20),
              widget.customContent!,
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                if (widget.secondaryButtonText != null) ...[
                  Expanded(
                    child: GlassGhostButton(
                      onPressed: () {
                        widget.onSecondaryPressed?.call();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        widget.secondaryButtonText!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: GradientActionButton(
                    onPressed: () {
                      widget.onDismiss?.call();
                      Navigator.of(context).pop();
                    },
                    colors: [color, endColor],
                    child: Text(
                      widget.buttonText ?? 'Got It',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvertedRectClipper extends CustomClipper<Path> {
  final Rect? targetRect;
  _InvertedRectClipper(this.targetRect);

  @override
  Path getClip(Size size) {
    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    if (targetRect != null) {
      final Path holePath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(targetRect!, const Radius.circular(12)),
        );
      return Path.combine(PathOperation.difference, path, holePath);
    }
    return path;
  }

  @override
  bool shouldReclip(_InvertedRectClipper oldClipper) =>
      oldClipper.targetRect != targetRect;
}

enum BackgroundEffect { blur, darken }

/// Helper function to show a mastery notice overlay
Future<T?> showMasteryNotice<T>(
  BuildContext context, {
  required String title,
  required String message,
  Widget? customContent,
  VoidCallback? onDismiss,
  String? buttonText,
  String? secondaryButtonText,
  IconData? icon,
  Widget? iconWidget,
  Color? accentColor,
  VoidCallback? onSecondaryPressed,
  GlobalKey? highlightTargetKey,
  BackgroundEffect backgroundEffect = BackgroundEffect.blur,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent, // We handle our own overlay
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return MasteryNoticeOverlay(
        title: title,
        message: message,
        customContent: customContent,
        onDismiss: onDismiss,
        buttonText: buttonText,
        secondaryButtonText: secondaryButtonText,
        icon: icon,
        iconWidget: iconWidget,
        accentColor: accentColor,
        onSecondaryPressed: onSecondaryPressed,
        highlightTargetKey: highlightTargetKey,
        backgroundEffect: backgroundEffect,
      );
    },
  );
}
