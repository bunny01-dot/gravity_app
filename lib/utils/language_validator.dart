import 'package:flutter/foundation.dart';

class LanguageValidator {
  static final RegExp _tamilRegex = RegExp(r'[\u0B80-\u0BFF]');
  static final RegExp _devanagariRegex = RegExp(r'[\u0900-\u097F]');

  static bool isTamilText(String text) => _tamilRegex.hasMatch(text);
  static bool isHindiText(String text) => _devanagariRegex.hasMatch(text);

  static bool isValidForLanguage(String text, String language) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    if (language == 'Tamil') {
      return isTamilText(trimmed) && !isHindiText(trimmed);
    }
    if (language == 'Hindi') {
      return isHindiText(trimmed) && !isTamilText(trimmed);
    }
    return true;
  }

  static void logMismatch({
    required String context,
    required String word,
    required String language,
    required String value,
  }) {
    debugPrint(
      'LANGUAGE_MISMATCH[$context] lang=$language word="$word" value="$value"',
    );
  }
}
