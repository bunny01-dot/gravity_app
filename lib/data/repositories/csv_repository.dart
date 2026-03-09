import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

class CsvRepository {
  // Parsing running in isolate via compute
  static List<List<dynamic>> _parseCsvIsolate(String csvContent) {
    return const CsvToListConverter().convert(csvContent);
  }

  Future<List<List<dynamic>>> fetchAndParseCsv(String url) async {
    try {
      debugPrint("Fetching CSV from \$url...");
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Force UTF-8 decoding
        String csvContent = utf8.decode(response.bodyBytes);

        // Run parsing in background isolate to prevent UI jank
        List<List<dynamic>> rows = await compute(_parseCsvIsolate, csvContent);
        return rows;
      } else {
        throw Exception("Failed to load CSV: \${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching CSV: \$e");
      rethrow;
    }
  }
}
