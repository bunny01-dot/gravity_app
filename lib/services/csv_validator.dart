import 'package:flutter/foundation.dart';

class CsvValidationResult {
  final bool isValid;
  final String message;
  final Map<int, int> dayNumberCounts; // dayNumber -> count
  final List<String> errors;
  final List<String> warnings;

  CsvValidationResult({
    required this.isValid,
    required this.message,
    this.dayNumberCounts = const {},
    this.errors = const [],
    this.warnings = const [],
  });
}

class CsvValidator {
  /// Validates that a CSV has:
  /// - A header row with a 'dayNumber' column
  /// - Exactly 5 entries for each dayNumber from 1 to 90
  /// - No missing dayNumbers
  /// - No duplicate or out-of-range dayNumbers
  static CsvValidationResult validateDayBasedCsv(
    List<List<dynamic>> csvData,
    String type, // 'vocabulary' or 'verbs'
  ) {
    List<String> errors = [];
    List<String> warnings = [];
    Map<int, int> dayNumberCounts = {};

    // 1. Check if CSV is empty
    if (csvData.isEmpty) {
      return CsvValidationResult(
        isValid: false,
        message: 'CSV is empty',
        errors: ['CSV contains no data'],
      );
    }

    // 2. Verify header row and find dayNumber column
    List<dynamic> headerRow = csvData[0];
    int dayNumberColumnIndex = -1;

    for (int i = 0; i < headerRow.length; i++) {
      String columnName = headerRow[i].toString().trim().toLowerCase();
      if (columnName == 'daynumber' || columnName == 'day number') {
        dayNumberColumnIndex = i;
        break;
      }
    }

    if (dayNumberColumnIndex == -1) {
      return CsvValidationResult(
        isValid: false,
        message: 'No dayNumber column found in CSV header',
        errors: [
          'CSV must have a column named "dayNumber" (case-insensitive)',
          'Found columns: ${headerRow.join(", ")}',
        ],
      );
    }

    // 3. Parse all rows and count dayNumbers
    for (int rowIndex = 1; rowIndex < csvData.length; rowIndex++) {
      List<dynamic> row = csvData[rowIndex];

      // Skip empty rows
      if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
        continue;
      }

      // Check if row has enough columns
      if (row.length <= dayNumberColumnIndex) {
        errors.add(
          'Row $rowIndex has insufficient columns (missing dayNumber)',
        );
        continue;
      }

      // Parse dayNumber
      String dayNumberStr = row[dayNumberColumnIndex].toString().trim();
      if (dayNumberStr.isEmpty) {
        errors.add('Row $rowIndex has empty dayNumber');
        continue;
      }

      int? dayNumber = int.tryParse(dayNumberStr);
      if (dayNumber == null) {
        errors.add('Row $rowIndex has invalid dayNumber: "$dayNumberStr"');
        continue;
      }

      // Check dayNumber range
      if (dayNumber < 1 || dayNumber > 90) {
        errors.add(
          'Row $rowIndex has out-of-range dayNumber: $dayNumber (must be 1-90)',
        );
        continue;
      }

      // Count occurrences
      dayNumberCounts[dayNumber] = (dayNumberCounts[dayNumber] ?? 0) + 1;
    }

    // 4. Verify exactly 5 items per day for days 1-90
    for (int day = 1; day <= 90; day++) {
      int count = dayNumberCounts[day] ?? 0;

      if (count == 0) {
        errors.add('Day $day has 0 entries (expected 5)');
      } else if (count < 5) {
        errors.add('Day $day has $count entries (expected 5)');
      } else if (count > 5) {
        errors.add('Day $day has $count entries (expected 5)');
      }
    }

    // 5. Check for any dayNumbers outside 1-90 range
    for (int dayNumber in dayNumberCounts.keys) {
      if (dayNumber < 1 || dayNumber > 90) {
        errors.add('Found invalid dayNumber: $dayNumber');
      }
    }

    // Determine if validation passed
    bool isValid = errors.isEmpty;

    String message;
    if (isValid) {
      int totalItems = dayNumberCounts.values.fold(
        0,
        (sum, count) => sum + count,
      );
      message =
          'OK: $type CSV validation passed: $totalItems items across 90 days (5 per day)';
    } else {
      message = 'Error: $type CSV validation failed with ${errors.length} error(s)';
    }

    return CsvValidationResult(
      isValid: isValid,
      message: message,
      dayNumberCounts: dayNumberCounts,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Prints a detailed validation report
  static void printValidationReport(CsvValidationResult result) {
    debugPrint('=== CSV VALIDATION REPORT ===');
    debugPrint(result.message);
    debugPrint('');

    if (result.errors.isNotEmpty) {
      debugPrint('ERRORS (${result.errors.length}):');
      for (String error in result.errors) {
        debugPrint('  Error: $error');
      }
      debugPrint('');
    }

    if (result.warnings.isNotEmpty) {
      debugPrint('WARNINGS (${result.warnings.length}):');
      for (String warning in result.warnings) {
        debugPrint('  [WARN]  $warning');
      }
      debugPrint('');
    }

    if (result.isValid && result.dayNumberCounts.isNotEmpty) {
      debugPrint('DAY DISTRIBUTION:');
      // Show first 5 and last 5 days as sample
      List<int> sortedDays = result.dayNumberCounts.keys.toList()..sort();
      for (int i = 0; i < sortedDays.length && i < 5; i++) {
        int day = sortedDays[i];
        int count = result.dayNumberCounts[day]!;
        debugPrint('  Day $day: $count items');
      }
      if (sortedDays.length > 10) {
        debugPrint('  ...');
      }
      for (
        int i = sortedDays.length - 5;
        i < sortedDays.length && i >= 0;
        i++
      ) {
        if (i >= 5) {
          int day = sortedDays[i];
          int count = result.dayNumberCounts[day]!;
          debugPrint('  Day $day: $count items');
        }
      }
    }

    debugPrint('=============================');
  }
}

