import 'dart:convert';

class DataServiceTextUtils {
  const DataServiceTextUtils._();

  static String removeParentheses(String text) {
    return text.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  }

  static final RegExp _indicScriptRegex = RegExp(r'[\u0900-\u0D7F]');
  static final RegExp _mojibakeMarkerRegex = RegExp(
    r'[\u00C2\u00C3\u00E0\u00E2]',
  );

  /// Repairs text that was accidentally stored as UTF-8 bytes interpreted as Latin-1.
  /// Example: "" -> ""
  static String repairMojibake(String text) {
    if (!_looksLikeMojibake(text)) return text;

    try {
      final repaired = utf8.decode(latin1.encode(text));
      if (repaired.isEmpty || repaired.contains('\uFFFD')) {
        return text;
      }

      final originalIndicCount = _countIndicChars(text);
      final repairedIndicCount = _countIndicChars(repaired);
      if (repairedIndicCount > originalIndicCount ||
          (!_looksLikeMojibake(repaired) && repairedIndicCount > 0)) {
        return repaired;
      }
    } catch (_) {
      // Keep original value if conversion is not safe.
    }

    return text;
  }

  static bool _looksLikeMojibake(String text) {
    if (text.isEmpty) return false;
    final hasMarkers = _mojibakeMarkerRegex.hasMatch(text);
    final hasIndic = _indicScriptRegex.hasMatch(text);
    return hasMarkers && !hasIndic;
  }

  static int _countIndicChars(String text) {
    return _indicScriptRegex.allMatches(text).length;
  }
}
