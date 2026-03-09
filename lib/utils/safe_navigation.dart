import 'package:flutter/material.dart';
import 'dart:async';

/// Centralized safe navigator helpers for async completion flows.
class SafeNavigation {
  const SafeNavigation._();

  static Future<bool> maybePop(
    BuildContext context, {
    Object? result,
    String? source,
  }) async {
    final navigator = Navigator.maybeOf(context);
    final label = source == null ? '' : ' ($source)';

    if (navigator == null) {
      debugPrint('SafeNavigation: No Navigator found$label.');
      return false;
    }

    final didPop = await navigator.maybePop(result);
    if (!didPop) {
      debugPrint('SafeNavigation: maybePop skipped$label.');
    }
    return didPop;
  }

  static void tryPop(BuildContext context, {Object? result, String? source}) {
    unawaited(maybePop(context, result: result, source: source));
  }
}
