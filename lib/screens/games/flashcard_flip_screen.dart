import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/safe_game_content_provider.dart';

import '../../services/level_manager.dart';

class FlashcardFlipScreen extends StatefulWidget {
  final int level;
  const FlashcardFlipScreen({super.key, this.level = 1});

  @override
  State<FlashcardFlipScreen> createState() => _FlashcardFlipScreenState();
}

class _FlashcardFlipScreenState extends State<FlashcardFlipScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  List<VocabularyItem> _items = [];
  int _currentIndex = 0;
  bool _isFront = true;
  bool _isLoading = true;

  // Game stats
  int _cardsLearned = 0;
  int _highScore = 0;
  bool _hasInsufficientContent = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    _loadHighScore();
    _loadData();
  }

  Future<void> _loadHighScore() async {
    final high = await DataService().getHighScore('flashcard_flip');
    if (mounted) setState(() => _highScore = high);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasInsufficientContent = false;
    });

    List<VocabularyItem> items = [];

    try {
      final safeProvider = SafeGameContentProvider(DataService());
      items = await safeProvider.getEligibleVocabulary(minCount: 3);
    } catch (e) {
      debugPrint("Flashcards: Error loading dynamic data: $e");
    }

    if (items.isNotEmpty) {
      setState(() {
        _items = items..shuffle();
        _isLoading = false;
        _hasInsufficientContent = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _hasInsufficientContent = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    SoundService().playTap();
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  void _nextCard(String difficulty) async {
    // Logic for scheduling repetition
    SoundService().playTap();

    // 1. Handle Difficulty
    if (difficulty == 'Hard') {
      // Re-queue the card so user sees it again THIS session
      _items.add(_items[_currentIndex]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Marked Hard: Added to end of deck for review."),
            duration: Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Good or Easy -> Mark as learned
      if (difficulty == 'Easy') SoundService().playSuccess();

      setState(() {
        _cardsLearned++;
      });

      if (_cardsLearned > _highScore) {
        _highScore = _cardsLearned;
        DataService().saveHighScore('flashcard_flip', _cardsLearned);
      }
    }

    // 2. Move to Next Card
    // Reset card to front without animation if moving to new card
    if (!_isFront) {
      _controller.reverse(from: 1.0).whenComplete(() {
        _advanceCard();
      });
    } else {
      _advanceCard();
    }
  }

  void _advanceCard() {
    setState(() {
      _isFront = true;
      if (_currentIndex < _items.length - 1) {
        _currentIndex++;
      } else {
        _showCompletionDialog();
        _unlockNextLevel();
      }
    });
  }

  void _showCompletionDialog() {
    SoundService().playCompletion();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final onSurface = theme.colorScheme.onSurface;
        return AlertDialog(
          backgroundColor: isDark
              ? const Color(0xFF1E1E2C)
              : Colors.white.withValues(alpha: 0.97),
          title: Text('Set Complete!', style: TextStyle(color: onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have reviewed all the cards in this set.',
                style: TextStyle(color: onSurface.withValues(alpha: 0.72)),
              ),
              const SizedBox(height: 16),
              Text(
                'Cards Reviewed: $_cardsLearned',
                style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
              ),
              Text(
                'Best Run: $_highScore',
                style: const TextStyle(color: Color(0xFF4FACFE)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _currentIndex = 0;
                  _cardsLearned = 0; // Reset session count
                  _items.shuffle();
                });
              },
              child: const Text('Restart'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = colorScheme.onSurface;
    final scaffoldBg = isDark
        ? const Color(0xFF030305)
        : theme.scaffoldBackgroundColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (_items.isEmpty || _hasInsufficientContent) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: colorScheme.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            "No words found. Please complete more lessons.",
            style: TextStyle(color: onSurface.withValues(alpha: 0.82)),
          ),
        ),
      );
    }

    final item = _items[_currentIndex];

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Card ${_currentIndex + 1}/${_items.length}',
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.72),
                fontSize: 16,
              ),
            ),
            Text(
              'Best Run: $_highScore',
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.3),
                fontSize: 10,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _flipCard,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final angle = _animation.value * pi;
                    final isUnder = _animation.value > 0.5;
                    final transform = Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspective
                      ..rotateY(angle);

                    return Transform(
                      transform: transform,
                      alignment: Alignment.center,
                      child: isUnder
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..rotateY(pi), // Flip content back
                              child: _buildBack(item),
                            )
                          : _buildFront(item),
                    );
                  },
                ),
              ),
            ),
          ),

          // Controls
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRatingButton(
                  'Hard',
                  Colors.redAccent,
                  Icons.sentiment_dissatisfied_rounded,
                ),
                _buildRatingButton(
                  'Good',
                  Colors.amber,
                  Icons.sentiment_neutral_rounded,
                ),
                _buildRatingButton(
                  'Easy',
                  Colors.greenAccent,
                  Icons.sentiment_satisfied_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildFront(VocabularyItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E2C)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white10 : onSurface.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4FACFE).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.word,
            style: TextStyle(
              color: onSurface,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to flip',
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(VocabularyItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2A35)
            : Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF4FACFE), width: 2),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (item.imageUrl != null) ...[
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: item.imageUrl!.startsWith('assets/')
                      ? AssetImage(item.imageUrl!) as ImageProvider
                      : NetworkImage(item.imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          Text(
            item.definition,
            textAlign: TextAlign.center,
            style: TextStyle(color: onSurface, fontSize: 20, height: 1.4),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Example',
                  style: TextStyle(
                    color: Color(0xFF4FACFE),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"${item.exampleSentence}"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.72),
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingButton(String label, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _nextCard(label),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _unlockNextLevel() async {
    await LevelManager().unlockNextLevel('flashcard_flip', widget.level);
    await LevelManager().saveStars('flashcard_flip', widget.level, 3);
  }
}
