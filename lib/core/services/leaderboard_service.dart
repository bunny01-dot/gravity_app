import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gravity_app/core/cache/leaderboard_cache.dart';

/// Leaderboard service with zero-cost caching
/// Uses LeaderboardCache to reduce Firestore reads by 90%
class LeaderboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LeaderboardCache _cache = LeaderboardCache();

  /// Get global leaderboard (cached for 1 hour)
  /// Cost: 20 reads per hour = 480 reads/day (vs 5000/day before)
  Future<List<Map<String, dynamic>>> getGlobalLeaderboard({
    int limit = 20,
  }) async {
    //  COST CONTROL: Always use cache
    return await _cache.getGlobalLeaderboard();
  }

  /// Force refresh leaderboard (manual only)
  Future<List<Map<String, dynamic>>> refreshLeaderboard() async {
    return await _cache.refresh();
  }

  /// Get user's rank in leaderboard (0 Firestore reads if cached)
  Future<int?> getUserRank(String uid) async {
    return await _cache.getUserRank(uid);
  }

  /// Get user's XP and rank (minimal Firestore reads)
  Future<Map<String, dynamic>> getUserStats(String uid) async {
    try {
      // Single document read (1 read)
      final userDoc = await _db.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        return {'xp': 0, 'rank': null};
      }

      final xp = userDoc.data()?['xp'] ?? 0;
      final rank = await getUserRank(uid);

      return {
        'xp': xp,
        'rank': rank,
        'name': userDoc.data()?['name'] ?? 'User',
      };
    } catch (e) {
      return {'xp': 0, 'rank': null, 'error': e.toString()};
    }
  }

  /// Get last cache update time
  DateTime? getLastUpdateTime() {
    return _cache.getLastFetchTime();
  }
}
