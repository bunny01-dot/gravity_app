import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:gravity_app/services/data_service.dart' as app_data_service;
import 'package:gravity_app/services/xp_reward_policy.dart';

/// Offline-first XP service with transaction safety
/// ALWAYS use this service for XP updates, NEVER update Firestore directly
class OfflineXpService {
  static final OfflineXpService _instance = OfflineXpService._internal();
  factory OfflineXpService() => _instance;
  OfflineXpService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StreamController<int> _xpAwardController =
      StreamController<int>.broadcast();

  Stream<int> get xpAwards => _xpAwardController.stream;

  /// Add XP with offline support and transaction safety
  /// This is the ONLY method that should update XP
  Future<void> addXp(int amount) async {
    final normalizedAmount = XpRewardPolicy.normalize(amount);
    if (normalizedAmount <= 0) {
      debugPrint('Attempted to add non-positive XP: $amount');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Cannot add XP: User not logged in');
      return;
    }

    try {
      // Update Firestore with transaction (prevents race conditions)
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(user.uid);
        final snapshot = await transaction.get(userRef);

        if (!snapshot.exists) {
          debugPrint('User document does not exist, creating...');
          transaction.set(userRef, {
            'xp': normalizedAmount,
            'email': user.email,
            'lastXpUpdate': FieldValue.serverTimestamp(),
          });
        } else {
          final currentXp = snapshot.data()?['xp'] ?? 0;
          transaction.update(userRef, {
            'xp': currentXp + normalizedAmount,
            'lastXpUpdate': FieldValue.serverTimestamp(),
          });
        }
      });

      // Also update local cache
      final prefs = await SharedPreferences.getInstance();
      final currentLocalXp = prefs.getInt('local_xp') ?? 0;
      await prefs.setInt('local_xp', currentLocalXp + normalizedAmount);
      await _syncCanonicalXp(normalizedAmount);
      _emitXpAward(normalizedAmount);

      debugPrint('Added $normalizedAmount XP successfully');
    } catch (e) {
      debugPrint('Failed to add XP online, queuing for later: $e');

      // Queue for offline sync
      await _queueOfflineXp(normalizedAmount);
      await _syncCanonicalXp(normalizedAmount);
      _emitXpAward(normalizedAmount);
    }
  }

  Future<void> _syncCanonicalXp(int amount) async {
    try {
      await app_data_service.DataService().addXp(amount);
    } catch (e) {
      debugPrint('Failed to sync canonical XP counters: $e');
    }
  }

  void _emitXpAward(int amount) {
    if (_xpAwardController.isClosed) return;
    _xpAwardController.add(amount);
  }

  /// Queue XP for later sync when offline
  Future<void> _queueOfflineXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final queuedXp = prefs.getInt('queued_xp') ?? 0;
    await prefs.setInt('queued_xp', queuedXp + amount);

    // Also update local display
    final currentLocalXp = prefs.getInt('local_xp') ?? 0;
    await prefs.setInt('local_xp', currentLocalXp + amount);

    debugPrint(
      'Queued $amount XP for offline sync (total queued: ${queuedXp + amount})',
    );
  }

  /// Sync queued XP when back online
  Future<void> syncQueuedXp() async {
    final prefs = await SharedPreferences.getInstance();
    final queuedXp = prefs.getInt('queued_xp') ?? 0;

    if (queuedXp <= 0) {
      debugPrint('No queued XP to sync');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Cannot sync XP: User not logged in');
      return;
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(user.uid);
        final snapshot = await transaction.get(userRef);

        if (!snapshot.exists) {
          transaction.set(userRef, {
            'xp': queuedXp,
            'email': user.email,
            'lastXpUpdate': FieldValue.serverTimestamp(),
          });
        } else {
          final currentXp = snapshot.data()?['xp'] ?? 0;
          transaction.update(userRef, {
            'xp': currentXp + queuedXp,
            'lastXpUpdate': FieldValue.serverTimestamp(),
          });
        }
      });

      // Clear queue after successful sync
      await prefs.setInt('queued_xp', 0);
      debugPrint('Synced $queuedXp queued XP successfully');
    } catch (e) {
      debugPrint('Failed to sync queued XP: $e');
    }
  }

  /// Get current XP (local cache)
  Future<int> getCurrentXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_total_xp') ?? prefs.getInt('local_xp') ?? 0;
  }
}
