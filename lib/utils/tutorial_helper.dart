import 'package:flutter/material.dart';
import 'package:gravity_app/widgets/coach_mark_overlay.dart';
import 'package:gravity_app/services/tutorial_service.dart';

/// Helper class to display contextual tutorials using OverlayEntry
class TutorialHelper {
  static OverlayEntry? _currentOverlay;

  /// Shows a tutorial overlay with the given parameters
  /// Automatically prevents stacking by dismissing any existing tutorial
  static void showTutorial({
    required BuildContext context,
    required GlobalKey targetKey,
    required String title,
    required String message,
    required VoidCallback onDismiss,
    Color accentColor = const Color(0xFF4FACFE),
    Alignment alignment = Alignment.center,
    bool allowTargetInteraction = false,
    CoachMarkHighlightShape highlightShape =
        CoachMarkHighlightShape.roundedRect,
    EdgeInsets highlightPadding = const EdgeInsets.all(8),
  }) {
    // Do not interfere if a tutorial or notice is already showing
    if (TutorialService().isTutorialInProgress || _currentOverlay != null) {
      return;
    }

    // Mark tutorial as in progress
    TutorialService().startTutorial();

    // Create the overlay
    _currentOverlay = OverlayEntry(
      builder: (context) {
        // Get the RenderBox of the target widget
        Rect? targetRect;

        try {
          final renderBox =
              targetKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final size = renderBox.size;
            final position = renderBox.localToGlobal(Offset.zero);
            targetRect = position & size;
          }
        } catch (e) {
          debugPrint('Error getting target widget bounds: $e');
        }

        return CoachMarkOverlay(
          targetAlignment: alignment,
          title: title,
          message: message,
          accentColor: accentColor,
          allowTargetInteraction: allowTargetInteraction,
          highlightShape: highlightShape,
          highlightPadding: highlightPadding,
          onDismiss: () {
            dismissCurrentTutorial();
            onDismiss();
          },
          targetRect: targetRect,
        );
      },
    );

    // Insert the overlay
    Overlay.of(context).insert(_currentOverlay!);
  }

  /// Dismisses the current tutorial overlay if one exists
  static void dismissCurrentTutorial() {
    if (_currentOverlay != null) {
      _currentOverlay?.remove();
      _currentOverlay = null;
      TutorialService().endTutorial();
    }
  }

  /// Check if a tutorial is currently showing
  static bool get isShowingTutorial =>
      _currentOverlay != null || TutorialService().isTutorialInProgress;
}
