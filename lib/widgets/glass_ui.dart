import 'dart:ui';

import 'package:flutter/material.dart';

/// Reusable glassmorphic surface with blur + soft gradient tint.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double blurSigma;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding = const EdgeInsets.all(24),
    this.blurSigma = 22,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1.1,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final panelGradient =
        gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface.withValues(alpha: isDark ? 0.42 : 0.82),
            scheme.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.28 : 0.64,
            ),
          ],
        );

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: panelGradient,
            borderRadius: borderRadius,
            border: Border.all(
              color:
                  borderColor ??
                  scheme.primary.withValues(alpha: isDark ? 0.45 : 0.32),
              width: borderWidth,
            ),
            boxShadow:
                boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class GradientActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final List<Color>? colors;
  final double minHeight;
  final Color? foregroundColor;

  const GradientActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.colors,
    this.minHeight = 52,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final gradientColors = colors ?? <Color>[scheme.primary, scheme.secondary];
    final textColor = foregroundColor ?? Colors.white;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: borderRadius,
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: borderRadius,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: padding,
                child: IconTheme(
                  data: IconThemeData(color: textColor),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    child: Center(child: child),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassGhostButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  const GlassGhostButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.minHeight = 52,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    const darkChip = Color(0xFF141D2E);

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: darkChip.withValues(alpha: 0.8),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: borderRadius,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: padding,
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  child: Center(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
