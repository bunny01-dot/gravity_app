import 'package:gravity_app/core/cache/students_cache.dart';
import 'package:gravity_app/core/cache/leaderboard_cache.dart';
import 'package:gravity_app/core/cache/attendance_cache.dart';
import 'package:gravity_app/core/cache/announcements_cache.dart';
import 'package:flutter/foundation.dart';

/// Centralized cache manager for zero-cost Firestore operations
///
/// This manager coordinates all cache services to ensure:
/// - No duplicate Firestore reads
/// - Consistent cache invalidation
/// - Predictable refresh patterns
/// - Stay within Firebase free tier (50k reads/day)
class CacheManager {
  static CacheManager? _instance;

  final StudentsCache _studentsCache = StudentsCache();
  final LeaderboardCache _leaderboardCache = LeaderboardCache();
  final AttendanceCache _attendanceCache = AttendanceCache();
  final AnnouncementsCache _announcementsCache = AnnouncementsCache();

  // Singleton
  factory CacheManager() {
    _instance ??= CacheManager._internal();
    return _instance!;
  }

  CacheManager._internal();

  // Getters for individual caches
  StudentsCache get students => _studentsCache;
  LeaderboardCache get leaderboard => _leaderboardCache;
  AttendanceCache get attendance => _attendanceCache;
  AnnouncementsCache get announcements => _announcementsCache;

  /// Refresh all caches (use sparingly - costs Firestore reads)
  Future<void> refreshAll() async {
    debugPrint('[REFRESH] CacheManager: Refreshing all caches...');

    await Future.wait([
      _studentsCache.refresh(),
      _leaderboardCache.refresh(),
      _attendanceCache.refresh(),
      _announcementsCache.refresh(),
    ]);

    debugPrint('OK: CacheManager: All caches refreshed');
  }

  /// Clear all caches (use when logging out)
  Future<void> clearAll() async {
    debugPrint('[DELETE] CacheManager: Clearing all caches...');

    await Future.wait([
      _studentsCache.clearCache(),
      _leaderboardCache.clearCache(),
      _attendanceCache.clearCache(),
      _announcementsCache.clearCache(),
    ]);

    debugPrint('OK: CacheManager: All caches cleared');
  }

  /// Get cache status for debugging
  Map<String, dynamic> getCacheStatus() {
    return {
      'students': {
        'last_sync': _studentsCache.getLastSyncTime()?.toIso8601String(),
        'age_minutes': _studentsCache.getLastSyncTime() != null
            ? DateTime.now()
                  .difference(_studentsCache.getLastSyncTime()!)
                  .inMinutes
            : null,
      },
      'leaderboard': {
        'last_fetch': _leaderboardCache.getLastFetchTime()?.toIso8601String(),
        'age_minutes': _leaderboardCache.getLastFetchTime() != null
            ? DateTime.now()
                  .difference(_leaderboardCache.getLastFetchTime()!)
                  .inMinutes
            : null,
      },
      'announcements': {
        'last_fetch': _announcementsCache.getLastFetchTime()?.toIso8601String(),
        'age_minutes': _announcementsCache.getLastFetchTime() != null
            ? DateTime.now()
                  .difference(_announcementsCache.getLastFetchTime()!)
                  .inMinutes
            : null,
      },
    };
  }

  /// Estimate daily Firestore reads based on cache strategy
  Map<String, dynamic> estimateDailyReads() {
    return {
      'students': {
        'reads_per_sync': 100, // .limit(100)
        'syncs_per_day': 1, // Once per 24 hours
        'total': 100,
      },
      'leaderboard': {
        'reads_per_fetch': 20, // .limit(20)
        'fetches_per_day': 24, // Once per hour
        'total': 480,
      },
      'attendance': {
        'reads_per_fetch': 200, // .limit(200)
        'fetches_per_day': 1, // Once per day
        'total': 200,
      },
      'announcements': {
        'reads_per_fetch': 10, // .limit(10)
        'fetches_per_day': 48, // Every 30 minutes
        'total': 480,
      },
      'grand_total': 1260, // Well within 50k free tier
      'free_tier_limit': 50000,
      'usage_percentage': 2.52,
    };
  }
}

