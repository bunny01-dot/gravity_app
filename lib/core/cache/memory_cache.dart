import 'package:flutter/foundation.dart';

/// Generic in-memory cache with TTL (Time To Live) and LRU eviction
///
/// Features:
/// - Automatic expiration based on TTL
/// - LRU (Least Recently Used) eviction when size limit reached
/// - Thread-safe operations
/// - Memory-efficient
class MemoryCache<T> {
  final Map<String, _CacheEntry<T>> _cache = {};
  final Duration ttl;
  final int maxSize;

  MemoryCache({this.ttl = const Duration(minutes: 30), this.maxSize = 100});

  /// Get value from cache (returns null if expired or not found)
  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Check if expired
    if (DateTime.now().difference(entry.timestamp) > ttl) {
      _cache.remove(key);
      debugPrint('[DELETE] Cache expired: $key');
      return null;
    }

    // Update last accessed time for LRU
    entry.lastAccessed = DateTime.now();
    debugPrint(
      'OK: Cache hit: $key (age: ${DateTime.now().difference(entry.timestamp).inSeconds}s)',
    );
    return entry.value;
  }

  /// Set value in cache
  void set(String key, T value) {
    // Enforce size limit (evict LRU if needed)
    if (_cache.length >= maxSize && !_cache.containsKey(key)) {
      _evictLeastRecentlyUsed();
    }

    _cache[key] = _CacheEntry(value);
    debugPrint('[SAVE] Cached: $key (total: ${_cache.length}/$maxSize)');
  }

  /// Check if key exists and is not expired
  bool contains(String key) {
    return get(key) != null;
  }

  /// Remove specific key
  void remove(String key) {
    _cache.remove(key);
    debugPrint('[DELETE] Removed from cache: $key');
  }

  /// Clear all cache
  void clear() {
    final count = _cache.length;
    _cache.clear();
    debugPrint('[DELETE] Cleared cache: $count items removed');
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'size': _cache.length,
      'maxSize': maxSize,
      'ttl_minutes': ttl.inMinutes,
      'entries': _cache.keys.toList(),
    };
  }

  /// Evict the least recently used entry
  void _evictLeastRecentlyUsed() {
    if (_cache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (var entry in _cache.entries) {
      if (oldestTime == null || entry.value.lastAccessed.isBefore(oldestTime)) {
        oldestTime = entry.value.lastAccessed;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
      debugPrint('[DELETE] LRU evicted: $oldestKey');
    }
  }

  /// Remove all expired entries
  void cleanupExpired() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (var entry in _cache.entries) {
      if (now.difference(entry.value.timestamp) > ttl) {
        expiredKeys.add(entry.key);
      }
    }

    for (var key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint('[DELETE] Cleaned up ${expiredKeys.length} expired entries');
    }
  }
}

/// Internal cache entry with metadata
class _CacheEntry<T> {
  final T value;
  final DateTime timestamp;
  DateTime lastAccessed;

  _CacheEntry(this.value)
    : timestamp = DateTime.now(),
      lastAccessed = DateTime.now();
}

