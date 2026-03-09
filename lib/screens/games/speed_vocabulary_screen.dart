import 'dart:async';
import 'dart:math';
import 'package:gravity_app/utils/game_utils.dart';
import 'package:flutter/material.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart'; // Fixed: Re-added
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/safe_game_content_provider.dart';

class SpeedVocabularyScreen extends StatefulWidget {
  const SpeedVocabularyScreen({super.key});

  @override
  State<SpeedVocabularyScreen> createState() => _SpeedVocabularyScreenState();
}

class _SpeedVocabularyScreenState extends State<SpeedVocabularyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerController;

  List<VocabularyItem> _allItems = [];
  VocabularyItem? _currentItem;
  List<String> _options = [];
  int _correctIndex = -1;

  bool _isLoading = true;
  bool _isGameOver = false;
  bool _hasStarted = false;
  bool _hasInsufficientContent = false;

  int _score = 0;
  int _highScore = 0;
  int _questionsAnswered = 0;
  static const int _gameDurationSeconds = 60; // 1 minute drill

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _timerController =
        AnimationController(
          vsync: this,
          duration: const Duration(seconds: _gameDurationSeconds),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _endGame();
          }
        });

    _loadData();
  }

  Future<void> _loadHighScore() async {
    final high = await DataService().getHighScore('speed_vocabulary');
    if (mounted) setState(() => _highScore = high);
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasInsufficientContent = false;
    });

    try {
      final safeProvider = SafeGameContentProvider(DataService());
      // Require at least 4 words for 1 target + 3 distractors.
      // Using 10 to ensure some variety in a 60s game.
      final items = await safeProvider.getEligibleVocabulary(minCount: 10);

      if (mounted) {
        setState(() {
          _allItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("SpeedVocab: Error loading data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          // In dev, we might fail silently or show error, but here we treat as content failure
          _hasInsufficientContent = true;
        });
      }
    }
  }

  void _startGame() {
    setState(() {
      _hasStarted = true;
      _isGameOver = false;
      _score = 0;
      _questionsAnswered = 0;
    });

    // Create an infinite source of questions by shuffling and reusing
    // We'll prepare the first question logic in _nextQuestion
    _timerController.forward(from: 0);
    _nextQuestion();
  }

  void _nextQuestion() {
    if (_isGameOver) return;

    if (_allItems.isEmpty) {
      // Fallback or restart if empty
      _loadData();
      return;
    }

    setState(() {
      // Pick random item (or sequential if we want to ensure everything is covered)
      // For random drill:
      final randomItem = _allItems[Random().nextInt(_allItems.length)];
      _currentItem = randomItem;

      // Prepare options safely
      final distractors = GameUtils.pickDistractors(_allItems, randomItem, 3);

      _options = [randomItem.word, ...distractors.map((d) => d.word)]
        ..shuffle();
      _correctIndex = _options.indexOf(randomItem.word);
    });
  }

  void _handleAnswer(int index) async {
    if (_isGameOver) return; // Prevent interaction during feedback

    // Stop timer briefly or just handle logic?
    // For a speed game, usually we don't stop, but pedagogy says show feedback.

    bool isCorrect = index == _correctIndex;

    if (isCorrect) {
      SoundService().playTap();
      setState(() {
        _score += 100;
        _questionsAnswered++;
      });
      // Short feedback for correct
      _nextQuestion();
    } else {
      SoundService().playError();
      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Wrong! Correct: ${_options[_correctIndex]}"),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 800),
        ),
      );

      // Reduce time penalty
      // _timerController.value += 0.05;

      // Delay slightly so they see the snackbar
      // We pause the "game logic" flow slightly but timer keeps going (pressure!)
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) _nextQuestion();
    }
  }

  void _endGame() async {
    setState(() => _isGameOver = true);
    SoundService().playCompletion();

    // Save High Score
    if (_score > _highScore) {
      _highScore = _score;
      await DataService().saveHighScore('speed_vocabulary', _score);
    }

    if (!mounted) return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        title: Text('Time up!', style: TextStyle(color: onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.timer_off_rounded, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            Text(
              'Score: $_score',
              style: TextStyle(
                color: onSurface,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'High Score: $_highScore',
              style: const TextStyle(color: Color(0xFF4FACFE), fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'You answered $_questionsAnswered questions!',
              style: TextStyle(color: onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _timerController.reset();
              _startGame();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final scaffoldBg = isDark
        ? const Color(0xFF030305)
        : theme.scaffoldBackgroundColor;

    if (_hasInsufficientContent) {
      return Scaffold(
        backgroundColor: Colors.indigo.shade50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.indigo),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text("No words found. Please complete more lessons."),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasStarted) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: BackButton(color: onSurface),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.speed_rounded,
                size: 80,
                color: Color(0xFF00FF7F),
              ),
              const SizedBox(height: 24),
              Text(
                "Speed Run",
                style: TextStyle(
                  color: onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Answer as many definition questions\nas you can in 60 seconds!",
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 48),
              FilledButton(
                onPressed: _startGame,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text("GO!", style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Timer Bar
            AnimatedBuilder(
              animation: _timerController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: 1.0 - _timerController.value,
                  backgroundColor: isDark
                      ? Colors.white10
                      : onSurface.withValues(alpha: 0.08),
                  color: _timerController.value > 0.8
                      ? Colors.red
                      : const Color(0xFF00FF7F),
                  minHeight: 8,
                );
              },
            ),

            // HUD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: onSurface.withValues(alpha: 0.54),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Score: $_score',
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Question
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    "DEFINITION",
                    style: TextStyle(
                      color: Color(0xFF00FF7F),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                        _currentItem?.definition ?? "...",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 24,
                          height: 1.4,
                        ),
                      )
                      .animate(key: ValueKey(_currentItem?.id))
                      .fadeIn()
                      .slideY(begin: 0.1, end: 0, duration: 200.ms),
                ],
              ),
            ),

            const Spacer(),

            // Options
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _options.asMap().entries.map((entry) {
                      return SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: FilledButton(
                          onPressed: () => _handleAnswer(entry.key),
                          style: FilledButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white10
                                : onSurface.withValues(alpha: 0.08),
                            foregroundColor: onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
