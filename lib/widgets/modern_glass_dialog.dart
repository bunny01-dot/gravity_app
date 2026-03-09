import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

class ModernGlassDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final String primaryButtonText;
  final VoidCallback onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final Color? accentColor;
  final IconData? icon;

  const ModernGlassDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    required this.primaryButtonText,
    required this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.accentColor,
    this.icon,
  }) : assert(
         message != null || content != null,
         'Either message or content must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final effectiveAccent = accentColor ?? colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E2C).withValues(alpha: 0.82)
              : colorScheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: effectiveAccent.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: effectiveAccent.withValues(alpha: isDark ? 0.12 : 0.08),
              blurRadius: 40,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: effectiveAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: effectiveAccent),
              ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
              const SizedBox(height: 24),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
            if (content != null) ...[const SizedBox(height: 16), content!],
            const SizedBox(height: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: onPrimaryPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: effectiveAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    primaryButtonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (secondaryButtonText != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onSecondaryPressed,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      secondaryButtonText!,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper to show the dialog conveniently
// ISSUE #4 FIX: Added smooth close animation
Future<T?> showModernDialog<T>(
  BuildContext context, {
  required String title,
  String? message,
  Widget? content,
  required String primaryButtonText,
  required VoidCallback onPrimaryPressed,
  String? secondaryButtonText,
  VoidCallback? onSecondaryPressed,
  Color? accentColor,
  IconData? icon,
  ConfettiController? confettiController,
  bool barrierDismissible = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showGeneralDialog<T>(
    context: context,
    barrierColor: isDark
        ? Colors.black54
        : Colors.black.withValues(alpha: 0.25),
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // ISSUE #4 FIX: Smooth scale + fade animation
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
          ),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      final dialog = ModernGlassDialog(
        title: title,
        message: message,
        content: content,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        secondaryButtonText: secondaryButtonText,
        onSecondaryPressed: onSecondaryPressed,
        accentColor: accentColor,
        icon: icon,
      );

      if (confettiController == null) return dialog;

      return Stack(
        fit: StackFit.expand,
        children: [
          dialog,
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              maxBlastForce: 25, // Stronger pop
              minBlastForce: 10,
              emissionFrequency: 0.02,
              numberOfParticles: 50, // More confetti
              gravity: 0.2, // Slower fall
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Color(0xFF00F2FE), // Cyan
                Color(0xFFFFD700), // Gold
              ],
            ),
          ),
        ],
      );
    },
  );
}
