import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WordDuelService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<String> createInvite({required String opponentId}) async {
    final callable = _functions.httpsCallable('createWordDuelMatch');
    final result = await callable.call({'opponentId': opponentId});
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['matchId'] as String;
  }

  Future<void> respondToInvite({
    required String matchId,
    required bool accept,
  }) async {
    final callable = _functions.httpsCallable('respondToWordDuelInvite');
    await callable.call({'matchId': matchId, 'accept': accept});
  }

  Future<void> submitAnswer({
    required String matchId,
    required String answer,
  }) async {
    final callable = _functions.httpsCallable('submitWordDuelAnswer');
    await callable.call({'matchId': matchId, 'answer': answer});
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchMatch(String matchId) {
    return _firestore.collection('matches').doc(matchId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchWaitingMatches() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('matches')
        .where('type', isEqualTo: 'word_duel')
        .where('players', arrayContains: uid)
        .where('status', isEqualTo: 'waiting')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveMatches() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('matches')
        .where('type', isEqualTo: 'word_duel')
        .where('players', arrayContains: uid)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }
}
