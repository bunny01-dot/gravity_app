import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Zero-cost attendance cache with daily refresh
/// Reduces Firestore reads from 5k/day to ~200/day
class AttendanceCache {
  static AttendanceCache? _instance;
  static Map<String, List<Map<String, dynamic>>> _dailyCache = {};

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Singleton
  factory AttendanceCache() {
    _instance ??= AttendanceCache._internal();
    return _instance!;
  }

  AttendanceCache._internal() {
    _loadFromPreferences();
  }

  /// Get today's attendance (cached)
  Future<List<Map<String, dynamic>>> getTodayAttendance() async {
    final today = _getToday();

    // Check memory cache first
    if (_dailyCache.containsKey(today)) {
      debugPrint('OK: AttendanceCache: Using cached data for $today');
      return _dailyCache[today]!;
    }

    // Fetch from Firestore (once per day)
    return await _fetchAttendance(today);
  }

  /// Get attendance for specific date
  Future<List<Map<String, dynamic>>> getAttendance(String date) async {
    // Check cache
    if (_dailyCache.containsKey(date)) {
      return _dailyCache[date]!;
    }

    // Fetch from Firestore
    return await _fetchAttendance(date);
  }

  /// Force refresh today's attendance
  Future<List<Map<String, dynamic>>> refresh() async {
    final today = _getToday();
    _dailyCache.remove(today); // Clear cache
    return await _fetchAttendance(today);
  }

  /// Mark student as present (write operation)
  Future<void> markPresent(String studentEmail, String studentName) async {
    final today = _getToday();

    try {
      await _db.collection('attendance').add({
        'studentEmail': studentEmail,
        'studentName': studentName,
        'date': today,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Invalidate cache to force refresh
      _dailyCache.remove(today);

      debugPrint('OK: AttendanceCache: Marked $studentEmail present');
    } catch (e) {
      debugPrint('Error: AttendanceCache: Failed to mark present - $e');
      rethrow;
    }
  }

  /// Get attendance count for today (0 Firestore reads if cached)
  Future<int> getTodayCount() async {
    final attendance = await getTodayAttendance();
    return attendance.length;
  }

  /// Check if student is present today (0 Firestore reads if cached)
  Future<bool> isPresent(String studentEmail) async {
    final attendance = await getTodayAttendance();
    return attendance.any((record) => record['studentEmail'] == studentEmail);
  }

  /// Clear all cache
  Future<void> clearCache() async {
    _dailyCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('attendance_cache');
  }

  // Private: Fetch attendance from Firestore
  Future<List<Map<String, dynamic>>> _fetchAttendance(String date) async {
    try {
      //  COST CONTROL: Limit to 200 students max
      final snapshot = await _db
          .collection('attendance')
          .where('date', isEqualTo: date)
          .limit(200) //  NEVER REMOVE THIS
          .get();

      final attendance = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Cache in memory
      _dailyCache[date] = attendance;

      // Clean old cache (keep only last 7 days)
      _cleanOldCache();

      // Persist to SharedPreferences
      await _saveToPreferences();

      debugPrint(
        'OK: AttendanceCache: Fetched ${attendance.length} records for $date',
      );

      return attendance;
    } catch (e) {
      debugPrint('Error: AttendanceCache: Fetch failed - $e');
      return [];
    }
  }

  // Private: Get today's date string
  String _getToday() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  // Private: Clean old cache entries
  void _cleanOldCache() {
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 7));

    _dailyCache.removeWhere((dateStr, _) {
      try {
        final parts = dateStr.split('-');
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        return date.isBefore(sevenDaysAgo);
      } catch (e) {
        return true; // Remove invalid entries
      }
    });
  }

  // Private: Load cache from SharedPreferences
  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('attendance_cache');

      if (cachedData != null) {
        final decoded = jsonDecode(cachedData) as Map<String, dynamic>;

        _dailyCache = decoded.map((key, value) {
          return MapEntry(
            key,
            List<Map<String, dynamic>>.from(
              (value as List).map((item) => Map<String, dynamic>.from(item)),
            ),
          );
        });

        debugPrint('OK: AttendanceCache: Loaded from SharedPreferences');
      }
    } catch (e) {
      debugPrint('Error: AttendanceCache: Failed to load from preferences - $e');
    }
  }

  // Private: Save cache to SharedPreferences
  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('attendance_cache', jsonEncode(_dailyCache));
    } catch (e) {
      debugPrint('Error: AttendanceCache: Failed to save to preferences - $e');
    }
  }
}

