import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Zero-cost announcements cache with 30-minute refresh
/// Reduces Firestore reads from 2k/day to ~48/day
class AnnouncementsCache {
  static AnnouncementsCache? _instance;
  static List<Map<String, dynamic>>? _cache;
  static DateTime? _lastFetch;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Singleton
  factory AnnouncementsCache() {
    _instance ??= AnnouncementsCache._internal();
    return _instance!;
  }

  AnnouncementsCache._internal();

  /// Get announcements (cached for 30 minutes)
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    // Check memory cache first
    if (_cache != null && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!);

      // Use cache if less than 30 minutes old
      if (age < const Duration(minutes: 30)) {
        debugPrint(
          'OK: AnnouncementsCache: Using cached data (${age.inMinutes}m old)',
        );
        return _cache!;
      }
    }

    // Try loading from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('announcements_cache');
    final cachedTime = prefs.getInt('announcements_cache_time');

    if (cachedData != null && cachedTime != null) {
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTime;

      // Use cache if less than 30 minutes old
      if (cacheAge < const Duration(minutes: 30).inMilliseconds) {
        _cache = List<Map<String, dynamic>>.from(
          jsonDecode(cachedData).map((item) => Map<String, dynamic>.from(item)),
        );
        _lastFetch = DateTime.fromMillisecondsSinceEpoch(cachedTime);
        debugPrint('OK: AnnouncementsCache: Loaded from SharedPreferences');
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

  /// Get unread count (0 Firestore reads if cached)
  Future<int> getUnreadCount(
    Set<String> readIds,
    Set<String> deletedIds,
  ) async {
    final announcements = await getAnnouncements();

    return announcements.where((announcement) {
      final id = announcement['id'] as String;
      return !readIds.contains(id) && !deletedIds.contains(id);
    }).length;
  }

  /// Mark announcement as read (local only, no Firestore write)
  Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList('read_announcements') ?? [];

    if (!readIds.contains(id)) {
      readIds.add(id);
      await prefs.setStringList('read_announcements', readIds);
    }
  }

  /// Delete announcement (local only, no Firestore write)
  Future<void> deleteAnnouncement(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList('deleted_announcements') ?? [];

    if (!deletedIds.contains(id)) {
      deletedIds.add(id);
      await prefs.setStringList('deleted_announcements', deletedIds);
    }

    // Remove from cache
    if (_cache != null) {
      _cache!.removeWhere((announcement) => announcement['id'] == id);
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    _cache = null;
    _lastFetch = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('announcements_cache');
    await prefs.remove('announcements_cache_time');
  }

  // Private: Fetch from Firestore
  Future<List<Map<String, dynamic>>> _fetchFromFirestore() async {
    try {
      //  COST CONTROL: Reduced from 20 to 10
      final snapshot = await _db
          .collection('announcements')
          .orderBy('timestamp', descending: true)
          .limit(10) //  Keep small for cost control
          .get();

      _cache = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        // Convert Timestamp to ISO string for JSON serialization
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
      await prefs.setString('announcements_cache', jsonEncode(_cache));
      await prefs.setInt(
        'announcements_cache_time',
        _lastFetch!.millisecondsSinceEpoch,
      );

      debugPrint(
        'OK: AnnouncementsCache: Fetched ${_cache!.length} announcements from Firestore',
      );

      return _cache!;
    } catch (e) {
      debugPrint('Error: AnnouncementsCache: Fetch failed - $e');

      // Return empty list if no cache available
      _cache ??= [];

      return _cache!;
    }
  }

  /// Get last fetch time for UI display
  DateTime? getLastFetchTime() {
    return _lastFetch;
  }
}

