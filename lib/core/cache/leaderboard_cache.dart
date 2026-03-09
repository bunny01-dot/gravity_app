import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Zero-cost leaderboard cache with 1-hour refresh
/// Reduces Firestore reads from 5k/day to ~480/day
class LeaderboardCache {
  static LeaderboardCache? _instance;
  static List<Map<String, dynamic>>? _cache;
  static DateTime? _lastFetch;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Singleton
  factory LeaderboardCache() {
    _instance ??= LeaderboardCache._internal();
    return _instance!;
  }

  LeaderboardCache._internal();

  /// Get global leaderboard (cached for 1 hour)
  Future<List<Map<String, dynamic>>> getGlobalLeaderboard() async {
    // Check memory cache first
    if (_cache != null && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!);

      // Use cache if less than 1 hour old
      if (age < const Duration(hours: 1)) {
        debugPrint('OK: LeaderboardCache: Using cached data (${age.inMinutes}m old)');
        return _cache!;
      }
    }

    // Try loading from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('leaderboard_cache');
    final cachedTime = prefs.getInt('leaderboard_cache_time');

    if (cachedData != null && cachedTime != null) {
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTime;

      // Use cache if less than 1 hour old
      if (cacheAge < const Duration(hours: 1).inMilliseconds) {
        _cache = List<Map<String, dynamic>>.from(
          jsonDecode(cachedData).map((item) => Map<String, dynamic>.from(item)),
        );
        _lastFetch = DateTime.fromMillisecondsSinceEpoch(cachedTime);
        debugPrint('OK: LeaderboardCache: Loaded from SharedPreferences');
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

  /// Clear cache
  Future<void> clearCache() async {
    _cache = null;
    _lastFetch = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('leaderboard_cache');
    await prefs.remove('leaderboard_cache_time');
  }

  /// Get user's rank (0 Firestore reads if cached)
  Future<int?> getUserRank(String uid) async {
    final leaderboard = await getGlobalLeaderboard();

    for (int i = 0; i < leaderboard.length; i++) {
      if (leaderboard[i]['uid'] == uid) {
        return i + 1; // Rank is 1-indexed
      }
    }

    return null; // User not in top 20
  }

  // Private: Fetch from Firestore
  Future<List<Map<String, dynamic>>> _fetchFromFirestore() async {
    try {
      //  COST CONTROL: Reduced from 50 to 20
      final snapshot = await _db
          .collection('users')
          .orderBy('xp', descending: true)
          .limit(20) //  NEVER INCREASE ABOVE 50
          .get();

      _cache = snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();

      _lastFetch = DateTime.now();

      // Persist to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('leaderboard_cache', jsonEncode(_cache));
      await prefs.setInt(
        'leaderboard_cache_time',
        _lastFetch!.millisecondsSinceEpoch,
      );

      debugPrint(
        'OK: LeaderboardCache: Fetched ${_cache!.length} users from Firestore',
      );

      return _cache!;
    } catch (e) {
      debugPrint('Error: LeaderboardCache: Fetch failed - $e');

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

