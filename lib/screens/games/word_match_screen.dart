import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/models/vocabulary_item.dart';

import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/offline_xp_service.dart';

import '../../services/level_manager.dart';

class WordMatchScreen extends StatefulWidget {
  final int level;
  final String difficulty; // ISSUE #3 FIX: Add difficulty parameter

  const WordMatchScreen({
    super.key,
    this.level = 1,
    this.difficulty = 'Easy', // Default to Easy
  });

  @override
  State<WordMatchScreen> createState() => _WordMatchScreenState();
}

class _WordMatchScreenState extends State<WordMatchScreen> {
  List<MatchCardItem> _cards = [];
  bool _isLoading = true;
  int _score = 0;
  int _highScore = 0;
  int _matchesFound = 0;
  int _totalPairs = 2; // ISSUE #3 FIX: Default to Easy (2 pairs)

  // Game Logic
  MatchCardItem? _firstSelected;
  bool _isProcessing = false; // Prevent tapping while animating
  Timer? _timer;
  int _secondsElapsed = 0;

  // ISSUE #10 FIX: Unique ID per difficulty
  String get _gameId => 'word_match_${widget.difficulty.toLowerCase()}';

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _startGame();
  }

  Future<void> _loadHighScore() async {
    final high = await DataService().getHighScore(_gameId);
    if (mounted) setState(() => _highScore = high);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    // ISSUE #3 FIX: Calculate pairs based on difficulty
    int pairsCount;
    switch (widget.difficulty) {
      case 'Medium':
        pairsCount =
            4; // 3x3 grid = 9 tiles, but we use 8 (4 pairs) for even match
        break;
      case 'Hard':
        pairsCount = 8; // 4x4 grid = 16 tiles (8 pairs)
        break;
      case 'Easy':
      default:
        pairsCount = 2; // 2x2 grid = 4 tiles (2 pairs)
        break;
    }

    setState(() {
      _isLoading = true;
      _score = 0;
      _matchesFound = 0;
      _secondsElapsed = 0;
      _cards = [];
      _firstSelected = null;
      _totalPairs = pairsCount;
    });

    _startTimer();
    _loadCards();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);

    List<VocabularyItem> items = [];

    // 1. STRICTLY Load from DataService (Learned Content Only)
    try {
      // We request _totalPairs, strict enforcement is handled by DataService default (onlyLearned: true)
      final dynamicDocs = await DataService().getRandomVocabulary(_totalPairs);

      if (dynamicDocs.isNotEmpty) {
        for (var doc in dynamicDocs) {
          items.add(
            VocabularyItem(
              id: doc['word'] ?? 'unknown',
              word: doc['word'] ?? '?',
              definition: doc['meaning'] ?? '?',
              exampleSentence: doc['example'] ?? '',
              synonyms: [],
              antonyms: [],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("WordMatch: Error loading dynamic data: $e");
    }

    // FAIL-SAFE CHECK: If insufficient items, BLOCK ENTRY.
    // Do NOT fall back to static levels or mocks.
    if (items.length < _totalPairs) {
      if (!mounted) return;

      // Show blocking dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final onSurface = Theme.of(context).colorScheme.onSurface;
          return AlertDialog(
            backgroundColor: isDark
                ? const Color(0xFF1E1E2C)
                : Colors.white.withValues(alpha: 0.97),
            title: Text(
              'More Learning Needed ',
              style: TextStyle(color: onSurface),
            ),
            content: Text(
              'You need to learn at least $_totalPairs words to play this difficulty level.\n\nCurrent learned: ${items.length}',
              style: TextStyle(color: onSurface.withValues(alpha: 0.72)),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Exit screen
                },
                child: const Text('Go Back'),
              ),
            ],
          );
        },
      );
      return; // Stop execution
    }

    _totalPairs = items.length;

    List<MatchCardItem> tempCards = [];
    for (var item in items) {
      tempCards.add(
        MatchCardItem(
          id: '${item.id}_word',
          vocabId: item.id,
          content: item.word,
          type: CardType.word,
        ),
      );
      tempCards.add(
        MatchCardItem(
          id: '${item.id}_def',
          vocabId: item.id,
          // Truncate long definitions for UI
          content: item.definition.length > 60
              ? '${item.definition.substring(0, 57)}...'
              : item.definition,
          type: CardType.definition,
        ),
      );
    }

    tempCards.shuffle();

    if (mounted) {
      setState(() {
        _cards = tempCards;
        _isLoading = false;
      });
    }
  }

  void _onCardTap(MatchCardItem card) {
    if (_isProcessing || card.isMatched || card.isSelected) return;

    SoundService().playTap();

    setState(() {
      card.isSelected = true;
    });

    if (_firstSelected == null) {
      // First card tapped
      _firstSelected = card;
    } else {
      // Second card tapped
      _checkForMatch(_firstSelected!, card);
    }
  }

  void _checkForMatch(MatchCardItem card1, MatchCardItem card2) async {
    _isProcessing = true;

    if (card1.vocabId == card2.vocabId) {
      // Match found!
      SoundService().playSuccess(); // Assuming this exists or works
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        card1.isMatched = true;
        card2.isMatched = true;
        card1.isSelected = false;
        card2.isSelected = false;
        _matchesFound++;
        _score += 100; // Basic scoring
      });

      _firstSelected = null;
      _isProcessing = false;

      if (_matchesFound == _totalPairs) {
        _handleGameOver();
      }
    } else {
      // No match
      // SoundService().playError();
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        setState(() {
          card1.isSelected = false;
          card2.isSelected = false;
          _score = (_score - 10).clamp(0, 99999); // Penalty
        });
        _firstSelected = null;
        _isProcessing = false;
      }
    }
  }

  void _handleGameOver() async {
    _timer?.cancel();

    // Award XP (10% of score)
    final xpEarned = (_score * 0.1).ceil();
    if (xpEarned > 0) {
      await OfflineXpService().addXp(xpEarned);
    }

    // Save High Score
    if (_score > _highScore) {
      _highScore = _score;
      await DataService().saveHighScore(_gameId, _score);
    }

    // Unlock Logic
    await LevelManager().unlockNextLevel(_gameId, widget.level);
    await LevelManager().saveStars(_gameId, widget.level, 3);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final onSurface = Theme.of(context).colorScheme.onSurface;
        return AlertDialog(
          backgroundColor: isDark
              ? const Color(0xFF1E1E2C)
              : Colors.white.withValues(alpha: 0.97),
          title: Text('Level Complete!', style: TextStyle(color: onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 64),
              const SizedBox(height: 16),
              Text(
                'Score: $_score',
                style: TextStyle(
                  color: onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Best: $_highScore',
                style: const TextStyle(color: Color(0xFF4FACFE), fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Time: ${_formatTime(_secondsElapsed)}',
                style: TextStyle(color: onSurface.withValues(alpha: 0.72)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to menu
              },
              child: const Text('Exit'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _startGame();
              },
              child: const Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final scaffoldBg = isDark
        ? const Color(0xFF030305)
        : theme.scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Word Match', style: TextStyle(color: onSurface)),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF4FACFE).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              // Use Column for stack
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFF4FACFE),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_score',
                      style: TextStyle(
                        color: onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Best: $_highScore',
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Timer & Progress
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.timer_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(_secondsElapsed),
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.72),
                    fontSize: 18,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 32),
                Text(
                  'Matches: $_matchesFound/$_totalPairs',
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.72),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4FACFE)),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      itemCount: _cards.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        // ISSUE #3 FIX: Dynamic grid size based on difficulty
                        crossAxisCount: widget.difficulty == 'Hard'
                            ? 4
                            : (widget.difficulty == 'Medium' ? 3 : 2),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, index) {
                        return _buildCard(_cards[index], index);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(MatchCardItem card, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    bool isFlipped = card.isSelected || card.isMatched;

    return GestureDetector(
      onTap: () => _onCardTap(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          color: isFlipped
              ? (isDark
                    ? const Color(0xFF2A2A35)
                    : Colors.white.withValues(alpha: 0.95))
              : const Color(0xFF4FACFE),
          borderRadius: BorderRadius.circular(12),
          border: isFlipped
              ? Border.all(
                  color: card.isMatched
                      ? Colors.greenAccent
                      : const Color(0xFF4FACFE),
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: !card.isMatched
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.transparent,
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isFlipped
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    card.content,
                    textAlign: TextAlign.center,
                    maxLines: card.type == CardType.word ? 2 : 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: card.isMatched ? Colors.greenAccent : onSurface,
                      fontSize: card.type == CardType.word ? 16 : 10,
                      fontWeight: card.type == CardType.word
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ).animate().fadeIn()
            : Center(
                child: Icon(
                  Icons.help_outline_rounded,
                  color: onSurface.withValues(alpha: 0.5),
                  size: 32,
                ),
              ),
      ).animate().scale(delay: (index * 50).ms, duration: 200.ms),
    );
  }
}

enum CardType { word, definition }

class MatchCardItem {
  final String id;
  final String vocabId;
  final String content;
  final CardType type;
  bool isSelected;
  bool isMatched;

  MatchCardItem({
    required this.id,
    required this.vocabId,
    required this.content,
    required this.type,
    this.isSelected = false,
    this.isMatched = false,
  });
}
