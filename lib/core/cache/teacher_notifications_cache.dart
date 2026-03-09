import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Zero-cost cache for Teacher Notifications (Student Activity)
class TeacherNotificationsCache {
  static TeacherNotificationsCache? _instance;
  static List<Map<String, dynamic>>? _cache;
  static DateTime? _lastFetch;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Singleton
  factory TeacherNotificationsCache() {
    _instance ??= TeacherNotificationsCache._internal();
    return _instance!;
  }

  TeacherNotificationsCache._internal();

  /// Get notifications (cached for 15 minutes)
  Future<List<Map<String, dynamic>>> getNotifications() async {
    // Check memory cache first
    if (_cache != null && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!);
      if (age < const Duration(minutes: 15)) {
        return _cache!;
      }
    }

    // Try loading from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('teacher_notifications_cache');
    final cachedTime = prefs.getInt('teacher_notifications_cache_time');

    if (cachedData != null && cachedTime != null) {
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTime;
      if (cacheAge < const Duration(minutes: 15).inMilliseconds) {
        _cache = List<Map<String, dynamic>>.from(
          jsonDecode(cachedData).map((item) => Map<String, dynamic>.from(item)),
        );
        _lastFetch = DateTime.fromMillisecondsSinceEpoch(cachedTime);
        return _cache!;
      }
    }

    // Cache expired - fetch from Firestore
    return await _fetchFromFirestore();
  }

  /// Force refresh from Firestore
  Future<List<Map<String, dynamic>>> refresh() async {
    return await _fetchFromFirestore();
  }

  // Private: Fetch from Firestore
  Future<List<Map<String, dynamic>>> _fetchFromFirestore() async {
    try {
      final snapshot = await _db
          .collection('teacher_notifications')
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to 50 recent items
          .get();

      _cache = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        // Convert Timestamp to ISO string
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        return data;
      }).toList();

      _lastFetch = DateTime.now();

      // Persist to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('teacher_notifications_cache', jsonEncode(_cache));
      await prefs.setInt(
        'teacher_notifications_cache_time',
        _lastFetch!.millisecondsSinceEpoch,
      );

      return _cache!;
    } catch (e) {
      debugPrint('Error: TeacherNotificationsCache: Fetch failed - $e');
      _cache ??= [];
      return _cache!;
    }
  }
}

