import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gravity_app/core/cache/students_cache.dart';
import 'package:gravity_app/screens/games/multiplayer/word_duel_match_screen.dart';
import 'package:gravity_app/services/placement_state_service.dart';
import 'package:gravity_app/services/word_duel_service.dart';

class WordDuelLobbyScreen extends StatefulWidget {
  const WordDuelLobbyScreen({super.key});

  @override
  State<WordDuelLobbyScreen> createState() => _WordDuelLobbyScreenState();
}

class _WordDuelLobbyScreenState extends State<WordDuelLobbyScreen> {
  final WordDuelService _service = WordDuelService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String? _levelCode;
  String _levelLabel = '';
  String? _statusMessage;
  List<Map<String, dynamic>> _classmates = [];
  Map<String, Map<String, dynamic>> _classmatesById = {};
  final Set<String> _sendingInvites = {};

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _onSurface => Theme.of(context).colorScheme.onSurface;
  Color get _bgColor => _isDark
      ? const Color(0xFF030305)
      : Theme.of(context).scaffoldBackgroundColor;
  Color get _cardColor => _isDark ? const Color(0xFF1E1E2C) : Colors.white;
  Color get _borderColor =>
      _isDark ? Colors.white12 : _onSurface.withValues(alpha: 0.12);

  @override
  void initState() {
    super.initState();
    _loadClassmates();
  }

  Future<void> _loadClassmates() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _statusMessage = 'Sign in to access Word Duel.';
        _isLoading = false;
      });
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      final levelCode = userData['placement_level_code']?.toString().trim();

      if (levelCode == null || levelCode.isEmpty) {
        setState(() {
          _statusMessage =
              'Complete the placement quiz to find opponents at your level.';
          _isLoading = false;
        });
        return;
      }

      final normalizedLevelCode = levelCode.toUpperCase();
      final cache = StudentsCache();
      await cache.refresh();
      final students = await cache.getStudents(page: 0, pageSize: 500);

      final classmates = students.where((student) {
        final studentId = student['uid']?.toString();
        if (studentId == null || studentId == uid) return false;
        if ((student['role'] ?? 'student') != 'student') return false;
        if (student['isBlocked'] == true) return false;
        final studentLevel = student['placement_level_code']
            ?.toString()
            .trim()
            .toUpperCase();
        return studentLevel == normalizedLevelCode;
      }).toList();

      final byId = <String, Map<String, dynamic>>{};
      for (final student in classmates) {
        final id = student['uid']?.toString();
        if (id != null) {
          byId[id] = student;
        }
      }

      setState(() {
        _levelCode = normalizedLevelCode;
        _levelLabel = PlacementStateService.mapPlacementCodeToUserLevel(
          normalizedLevelCode,
        );
        _classmates = classmates;
        _classmatesById = byId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Could not load classmates. Please try again.';
        _isLoading = false;
      });
    }
  }

  String _displayName(Map<String, dynamic> data) {
    return data['name']?.toString().trim().isNotEmpty == true
        ? data['name'].toString()
        : (data['email']?.toString() ?? 'Student');
  }

  String _nameForUser(String uid) {
    final data = _classmatesById[uid];
    if (data == null) return 'Student';
    return _displayName(data);
  }

  Future<void> _sendInvite(String opponentId) async {
    if (_sendingInvites.contains(opponentId)) return;

    setState(() => _sendingInvites.add(opponentId));
    try {
      final matchId = await _service.createInvite(opponentId: opponentId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WordDuelMatchScreen(matchId: matchId),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      _showMessage(e.message ?? 'Unable to send invite.');
    } catch (e) {
      _showMessage('Unable to send invite.');
    } finally {
      if (mounted) {
        setState(() => _sendingInvites.remove(opponentId));
      }
    }
  }

  Future<void> _respondToInvite(String matchId, bool accept) async {
    try {
      await _service.respondToInvite(matchId: matchId, accept: accept);
      if (!mounted) return;
      if (accept) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WordDuelMatchScreen(matchId: matchId),
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      _showMessage(e.message ?? 'Unable to respond to invite.');
    } catch (e) {
      _showMessage('Unable to respond to invite.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Word Duel'),
        backgroundColor: Colors.transparent,
        foregroundColor: _onSurface,
      ),
      body: RefreshIndicator(
        onRefresh: _loadClassmates,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildPracticeBanner(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Color(0xFF4FACFE)),
                ),
              )
            else if (_statusMessage != null)
              _buildInfoCard(_statusMessage!)
            else ...[
              _buildInvitesSection(uid),
              const SizedBox(height: 20),
              _buildActiveMatchesSection(uid),
              const SizedBox(height: 24),
              _buildClassmatesSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4FACFE).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, color: Color(0xFF4FACFE)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Practice Match - No XP',
              style: TextStyle(color: _onSurface, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        message,
        style: TextStyle(color: _onSurface.withValues(alpha: 0.7)),
      ),
    );
  }

  Widget _buildInvitesSection(String? uid) {
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.watchWaitingMatches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return _buildInfoCard('Unable to load invites.');
        }

        final docs = snapshot.data?.docs ?? [];
        final incoming = docs.where((doc) {
          final data = doc.data();
          final accepted = Map<String, dynamic>.from(data['accepted'] ?? {});
          return data['createdBy'] != uid && accepted[uid] != true;
        }).toList();

        final outgoing = docs.where((doc) {
          final data = doc.data();
          final accepted = Map<String, dynamic>.from(data['accepted'] ?? {});
          return data['createdBy'] == uid &&
              accepted.values.any((value) => value == false);
        }).toList();

        if (incoming.isEmpty && outgoing.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (incoming.isNotEmpty) ...[
              Text(
                'Incoming invites',
                style: TextStyle(color: _onSurface, fontSize: 16),
              ),
              const SizedBox(height: 8),
              for (final doc in incoming) _buildInviteCard(doc, incoming: true),
              const SizedBox(height: 16),
            ],
            if (outgoing.isNotEmpty) ...[
              Text(
                'Pending invites',
                style: TextStyle(color: _onSurface, fontSize: 16),
              ),
              const SizedBox(height: 8),
              for (final doc in outgoing)
                _buildInviteCard(doc, incoming: false),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInviteCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool incoming,
  }) {
    final data = doc.data();
    final players = (data['players'] as List<dynamic>? ?? []).cast<String>();
    final opponentId = incoming
        ? data['createdBy']?.toString()
        : players.firstWhere(
            (id) => id != _auth.currentUser?.uid,
            orElse: () => '',
          );
    final opponentName = opponentId is String && opponentId.isNotEmpty
        ? _nameForUser(opponentId)
        : 'Student';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(opponentName, style: TextStyle(color: _onSurface, fontSize: 15)),
          const SizedBox(height: 6),
          Text(
            incoming ? 'Wants to play Word Duel' : 'Waiting for response',
            style: TextStyle(
              color: _onSurface.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          if (incoming)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respondToInvite(doc.id, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _onSurface.withValues(alpha: 0.7),
                      side: BorderSide(
                        color: _isDark
                            ? Colors.white24
                            : _onSurface.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondToInvite(doc.id, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FACFE),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WordDuelMatchScreen(matchId: doc.id),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveMatchesSection(String? uid) {
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.watchActiveMatches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return _buildInfoCard('Unable to load active matches.');
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active matches',
              style: TextStyle(color: _onSurface, fontSize: 16),
            ),
            const SizedBox(height: 8),
            for (final doc in docs)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _nameForUser(
                          ((doc.data()['players'] as List<dynamic>? ?? [])
                                  .cast<String>())
                              .firstWhere(
                                (id) => id != uid,
                                orElse: () => 'Student',
                              ),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WordDuelMatchScreen(matchId: doc.id),
                          ),
                        );
                      },
                      child: const Text('Resume'),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildClassmatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Same-level classmates',
          style: TextStyle(color: _onSurface, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          _levelLabel.isNotEmpty
              ? 'Level: ${_levelLabel[0].toUpperCase()}${_levelLabel.substring(1)}'
              : 'Level: ${_levelCode ?? ''}',
          style: TextStyle(
            color: _onSurface.withValues(alpha: 0.54),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        if (_classmates.isEmpty)
          _buildInfoCard('No classmates found at your level yet.')
        else
          Column(
            children: _classmates.map((student) {
              final studentId = student['uid']?.toString() ?? '';
              final name = _displayName(student);
              final email = student['email']?.toString() ?? '';
              final isSending = _sendingInvites.contains(studentId);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: TextStyle(
                                color: _onSurface.withValues(alpha: 0.38),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isSending)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4FACFE),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: studentId.isEmpty
                            ? null
                            : () => _sendInvite(studentId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FACFE),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Invite'),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
