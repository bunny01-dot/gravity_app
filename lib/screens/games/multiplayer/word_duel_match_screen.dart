import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gravity_app/services/word_duel_service.dart';

class WordDuelMatchScreen extends StatefulWidget {
  final String matchId;

  const WordDuelMatchScreen({super.key, required this.matchId});

  @override
  State<WordDuelMatchScreen> createState() => _WordDuelMatchScreenState();
}

class _WordDuelMatchScreenState extends State<WordDuelMatchScreen> {
  final WordDuelService _service = WordDuelService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSubmitting = false;
  bool _isLoadingNames = false;
  final Map<String, String> _playerNames = {};

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _onSurface => Theme.of(context).colorScheme.onSurface;
  Color get _bgColor => _isDark
      ? const Color(0xFF030305)
      : Theme.of(context).scaffoldBackgroundColor;
  Color get _cardColor => _isDark ? const Color(0xFF1E1E2C) : Colors.white;
  Color get _borderColor =>
      _isDark ? Colors.white12 : _onSurface.withValues(alpha: 0.12);

  String? get _uid => _auth.currentUser?.uid;

  void _ensurePlayerNames(List<String> players) {
    if (_isLoadingNames) return;
    final missing = players
        .where((id) => !_playerNames.containsKey(id))
        .toList();
    if (missing.isEmpty) return;
    _loadPlayerNames(missing);
  }

  Future<void> _loadPlayerNames(List<String> playerIds) async {
    setState(() => _isLoadingNames = true);
    try {
      final futures = playerIds.map(
        (id) => _firestore.collection('users').doc(id).get(),
      );
      final snaps = await Future.wait(futures);
      for (final snap in snaps) {
        final data = snap.data() ?? {};
        final name = (data['name']?.toString().trim().isNotEmpty == true)
            ? data['name'].toString()
            : (data['email']?.toString() ?? 'Student');
        _playerNames[snap.id] = name;
      }
      if (mounted) setState(() {});
    } catch (_) {
      // Ignore name failures; fallback will be used.
    } finally {
      if (mounted) setState(() => _isLoadingNames = false);
    }
  }

  String _nameFor(String? uid) {
    if (uid == null || uid.isEmpty) return 'Student';
    return _playerNames[uid] ?? 'Student';
  }

  Future<void> _submitAnswer(String answer) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _service.submitAnswer(matchId: widget.matchId, answer: answer);
    } on FirebaseFunctionsException catch (e) {
      _showMessage(e.message ?? 'Unable to submit answer.');
    } catch (_) {
      _showMessage('Unable to submit answer.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Word Duel'),
        backgroundColor: Colors.transparent,
        foregroundColor: _onSurface,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _service.watchMatch(widget.matchId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4FACFE)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildCenterMessage('Match not found.');
          }

          final data = snapshot.data!.data() ?? {};
          final status = data['status']?.toString() ?? 'waiting';
          final players = (data['players'] as List<dynamic>? ?? [])
              .cast<String>();
          _ensurePlayerNames(players);

          if (status == 'completed') {
            return _buildCompleted(data);
          }

          if (status != 'active') {
            return _buildWaiting(data);
          }

          return _buildActiveMatch(data);
        },
      ),
    );
  }

  Widget _buildCenterMessage(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: _onSurface.withValues(alpha: 0.7)),
      ),
    );
  }

  Widget _buildWaiting(Map<String, dynamic> data) {
    final opponentId = _opponentId(data);
    final opponentName = _nameFor(opponentId);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPracticeBanner(),
          const SizedBox(height: 20),
          _buildStatusCard(
            title: 'Waiting for opponent...',
            subtitle: 'Invite sent to $opponentName',
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMatch(Map<String, dynamic> data) {
    final uid = _uid;
    if (uid == null) return _buildCenterMessage('Sign in to continue.');

    final questions = (data['questions'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final index = (data['currentQuestionIndex'] ?? 0) as int;
    if (index >= questions.length || questions.isEmpty) {
      return _buildCenterMessage('Questions are loading...');
    }

    final question = questions[index];
    final answers = Map<String, dynamic>.from(data['answers'] ?? {});
    final myAnswers = (answers[uid] as List<dynamic>? ?? []).toList(
      growable: false,
    );
    final hasAnswered = myAnswers.length > index;
    final currentTurn = data['currentTurn']?.toString();
    final isMyTurn = currentTurn == uid;
    final canAnswer = isMyTurn && !hasAnswered && !_isSubmitting;

    final type = question['type']?.toString() ?? 'meaning';
    final header = _questionHeader(type);
    final prompt = _questionPrompt(type, question);
    final options = (question['options'] as List<dynamic>? ?? [])
        .cast<String>();

    final scores = Map<String, dynamic>.from(data['scores'] ?? {});
    final opponentId = _opponentId(data);
    final myScore = (scores[uid] ?? 0) as num;
    final opponentScore = (scores[opponentId] ?? 0) as num;
    final turnLabel = isMyTurn
        ? 'Your turn'
        : '${_nameFor(currentTurn)}\'s turn';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPracticeBanner(),
          const SizedBox(height: 16),
          _buildScoreRow(myScore, opponentScore, opponentId),
          const SizedBox(height: 12),
          Text(
            'Question ${index + 1} of ${questions.length}',
            style: TextStyle(
              color: _onSurface.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            turnLabel,
            style: const TextStyle(color: Color(0xFF4FACFE), fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildQuestionCard(header, prompt),
          const SizedBox(height: 16),
          for (final option in options) _buildOptionButton(option, canAnswer),
          if (!canAnswer)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                hasAnswered
                    ? 'Answer submitted. Waiting for opponent...'
                    : 'Waiting for opponent...',
                style: TextStyle(
                  color: _onSurface.withValues(alpha: 0.54),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompleted(Map<String, dynamic> data) {
    final uid = _uid;
    if (uid == null) return _buildCenterMessage('Sign in to continue.');

    final scores = Map<String, dynamic>.from(data['scores'] ?? {});
    final opponentId = _opponentId(data);
    final myScore = (scores[uid] ?? 0) as num;
    final opponentScore = (scores[opponentId] ?? 0) as num;

    String resultText = 'It\'s a draw';
    if (myScore > opponentScore) {
      resultText = 'You win!';
    } else if (myScore < opponentScore) {
      resultText = '${_nameFor(opponentId)} wins';
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPracticeBanner(),
          const SizedBox(height: 20),
          _buildStatusCard(title: 'Match complete', subtitle: resultText),
          const SizedBox(height: 16),
          _buildScoreRow(myScore, opponentScore, opponentId),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FACFE),
              foregroundColor: Colors.white,
            ),
            child: const Text('Play again'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _onSurface.withValues(alpha: 0.7),
              side: BorderSide(
                color: _isDark
                    ? Colors.white24
                    : _onSurface.withValues(alpha: 0.24),
              ),
            ),
            child: const Text('Exit'),
          ),
        ],
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

  Widget _buildStatusCard({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: _onSurface, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: _onSurface.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(num myScore, num opponentScore, String? opponentId) {
    return Row(
      children: [
        Expanded(child: _scoreCard('You', myScore)),
        const SizedBox(width: 12),
        Expanded(child: _scoreCard(_nameFor(opponentId), opponentScore)),
      ],
    );
  }

  Widget _scoreCard(String label, num score) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: _onSurface.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score.toInt().toString(),
            style: TextStyle(
              color: _onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String header, String prompt) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: TextStyle(
              color: _onSurface.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(prompt, style: TextStyle(color: _onSurface, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String option, bool enabled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: enabled ? () => _submitAnswer(option) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled
              ? const Color(0xFF4FACFE)
              : (_isDark
                    ? const Color(0xFF2A2A35)
                    : _onSurface.withValues(alpha: 0.08)),
          foregroundColor: enabled ? Colors.white : _onSurface,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Align(alignment: Alignment.centerLeft, child: Text(option)),
      ),
    );
  }

  String? _opponentId(Map<String, dynamic> data) {
    final players = (data['players'] as List<dynamic>? ?? []).cast<String>();
    final uid = _uid;
    if (uid == null) return null;
    return players.firstWhere((id) => id != uid, orElse: () => '');
  }

  String _questionHeader(String type) {
    switch (type) {
      case 'fill_blank':
        return 'Fill in the blank';
      case 'antonym':
        return 'Antonym';
      case 'meaning':
      default:
        return 'Word meaning';
    }
  }

  String _questionPrompt(String type, Map<String, dynamic> question) {
    if (type == 'fill_blank') {
      return question['sentence']?.toString() ?? '';
    }
    return question['prompt']?.toString() ?? '';
  }
}
