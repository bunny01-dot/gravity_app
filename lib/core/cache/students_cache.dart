import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Zero-cost students cache with daily sync
/// Reduces Firestore reads from 200k/day to ~100/day
class StudentsCache {
  static StudentsCache? _instance;
  static List<Map<String, dynamic>>? _students;
  static DateTime? _lastSync;
  static const int _maxStudents = 500;

  // Singleton
  factory StudentsCache() {
    _instance ??= StudentsCache._internal();
    return _instance!;
  }

  StudentsCache._internal();

  /// Get students with pagination (0 Firestore reads after first sync)
  Future<List<Map<String, dynamic>>> getStudents({
    int page = 0,
    int pageSize = 20,
  }) async {
    // Load from cache or sync
    await _ensureLoaded();

    if (_students == null || _students!.isEmpty) {
      return [];
    }

    // Paginate locally (0 Firestore reads)
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, _students!.length);

    if (start >= _students!.length) {
      return [];
    }

    return _students!.sublist(start, end);
  }

  /// Get total student count (0 Firestore reads)
  Future<int> getStudentCount() async {
    await _ensureLoaded();
    return _students?.length ?? 0;
  }

  /// Search students locally (0 Firestore reads)
  Future<List<Map<String, dynamic>>> searchStudents(String query) async {
    await _ensureLoaded();

    if (_students == null || query.isEmpty) {
      return _students ?? [];
    }

    final lowerQuery = query.toLowerCase();
    return _students!.where((student) {
      final name = (student['name'] ?? '').toString().toLowerCase();
      final email = (student['email'] ?? '').toString().toLowerCase();
      return name.contains(lowerQuery) || email.contains(lowerQuery);
    }).toList();
  }

  /// Force refresh from Firestore (manual only)
  Future<void> refresh() async {
    await _syncFromFirestore();
  }

  /// Manually remove a student from the cache (e.g. after deletion)
  Future<void> removeStudent(String uid) async {
    if (_students == null) return;
    _students!.removeWhere((s) => s['uid'] == uid);

    // Save updated cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('students_cache', jsonEncode(_students));
  }

  /// Clear cache
  Future<void> clearCache() async {
    _students = null;
    _lastSync = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('students_cache');
    await prefs.remove('students_cache_time');
  }

  /// Manually add a student (forced from debug)
  Future<void> forceAddStudent(DocumentSnapshot doc) async {
    await _ensureLoaded();
    _students ??= [];

    // Check if already exists
    final index = _students!.indexWhere((s) => s['uid'] == doc.id);
    if (index != -1) return; // Already there

    final data = doc.data() as Map<String, dynamic>;
    data['uid'] = doc.id;

    // Serialize
    final serializedData = <String, dynamic>{};
    data.forEach((key, value) {
      serializedData[key] = _serializeValue(value);
    });

    _students!.add(serializedData);

    // Re-sort
    _students!.sort((a, b) {
      final aTime = a['createdAt'] as int? ?? 0;
      final bTime = b['createdAt'] as int? ?? 0;
      return bTime.compareTo(aTime);
    });

    // Save
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('students_cache', jsonEncode(_students));
  }

  // Private: Ensure data is loaded
  Future<void> _ensureLoaded() async {
    // If in memory, use it
    if (_students != null && _lastSync != null) {
      // Sync once per day
      if (DateTime.now().difference(_lastSync!) < const Duration(hours: 24)) {
        return;
      }
    }

    // Try loading from SharedPreferences first
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('students_cache');
    final cachedTime = prefs.getInt('students_cache_time');

    if (cachedData != null && cachedTime != null) {
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTime;

      // Use cache if less than 24 hours old
      if (cacheAge < const Duration(hours: 24).inMilliseconds) {
        _students = List<Map<String, dynamic>>.from(
          jsonDecode(cachedData).map((item) => Map<String, dynamic>.from(item)),
        );
        _lastSync = DateTime.fromMillisecondsSinceEpoch(cachedTime);
        return;
      }
    }

    // Cache expired or missing - sync from Firestore
    await _syncFromFirestore();
  }

  // Private: Sync from Firestore (expensive operation)
  Future<void> _syncFromFirestore() async {
    try {
      QuerySnapshot snapshot;
      try {
        // Attempt 1: Optimized query (requires Index)
        snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .orderBy('createdAt', descending: true)
            .limit(_maxStudents)
            .get();
      } catch (e) {
        // Attempt 2: Fallback (Missing Index or other error)
        debugPrint(
          " StudentsCache: Index query failed ($e). Falling back to basic query.",
        );
        snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .limit(_maxStudents)
            .get();
      }

      _students = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>; // Safer cast
        data['uid'] = doc.id; // Include document ID

        // OK: FIX: Convert Timestamp objects to milliseconds for JSON encoding
        final serializedData = <String, dynamic>{};
        data.forEach((key, value) {
          serializedData[key] = _serializeValue(value);
        });

        return serializedData;
      }).toList();

      // Client-side sort if fallback was used (or just to be safe)
      _students!.sort((a, b) {
        final aTime = a['createdAt'] as int? ?? 0;
        final bTime = b['createdAt'] as int? ?? 0;
        return bTime.compareTo(aTime); // Descending
      });

      _lastSync = DateTime.now();

      // Persist to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('students_cache', jsonEncode(_students));
      await prefs.setInt(
        'students_cache_time',
        _lastSync!.millisecondsSinceEpoch,
      );

      debugPrint(
        'OK: StudentsCache: Synced ${_students!.length} students from Firestore',
      );
    } catch (e) {
      debugPrint('Error: StudentsCache: Sync failed - $e');

      // Fallback to old cache if available
      _students ??= [];
    }
  }

  // Helper: Recursively serialize values
  dynamic _serializeValue(dynamic value) {
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    } else if (value is Map) {
      final serialized = <String, dynamic>{};
      value.forEach((k, v) {
        serialized[k.toString()] = _serializeValue(v);
      });
      return serialized;
    } else if (value is List) {
      return value.map((item) => _serializeValue(item)).toList();
    } else {
      return value;
    }
  }

  /// Get last sync time for UI display
  DateTime? getLastSyncTime() {
    return _lastSync;
  }
}

