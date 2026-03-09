import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> saveUserProgress(String key, dynamic value) async {
    if (currentUser == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('progress')
          .doc('all_data')
          .set({key: value}, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Firestore Error (saveProgress): \$e");
    }
  }

  Future<Map<String, dynamic>?> fetchUserProgress() async {
    if (currentUser == null) return null;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('progress')
          .doc('all_data')
          .get();
      return doc.data();
    } catch (e) {
      debugPrint("Firestore Error (fetchProgress): \$e");
      return null;
    }
  }

  Future<void> saveFCMToken(String token) async {
    if (currentUser == null) return;
    try {
      final userRef = _firestore.collection('users').doc(currentUser!.uid);
      final payload = <String, dynamic>{
        'fcmToken': token.trim(),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      };

      // Store device token in a private sub-document to keep public user docs
      // free of sensitive push credentials.
      await userRef
          .collection('private')
          .doc('device')
          .set(payload, SetOptions(merge: true));

      // Backfill a missing email only when needed; avoid writing sensitive
      // token fields to users/{uid}.
      final email = (currentUser!.email ?? '').trim();
      if (email.isNotEmpty) {
        final userDoc = await userRef.get();
        if (!userDoc.exists) return;
        final data = userDoc.data() ?? <String, dynamic>{};
        final storedEmail = (data['email'] as String?)?.trim() ?? '';
        if (storedEmail.isEmpty) {
          await userRef.update({'uid': currentUser!.uid, 'email': email});
        }
      }
    } catch (e) {
      debugPrint("Firestore Error (saveFCM): \$e");
    }
  }
}
