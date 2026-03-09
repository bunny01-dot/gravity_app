import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/services/sound_service.dart';

import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/safe_game_content_provider.dart';
import 'package:gravity_app/services/analytics_service.dart';
import 'package:gravity_app/widgets/insufficient_content_widget.dart';
import 'package:gravity_app/config/app_config.dart';

import '../../services/level_manager.dart';

class PictureGuessScreen extends StatefulWidget {
  final int level;
  const PictureGuessScreen({super.key, this.level = 1});

  @override
  State<PictureGuessScreen> createState() => _PictureGuessScreenState();
}

class _PictureGuessScreenState extends State<PictureGuessScreen> {
  List<VocabularyItem> _allItems = [];
  VocabularyItem? _currentItem;

  List<String> _options = [];
  bool _isLoading = true;
  bool _answered = false;
  int _score = 0;
  int _highScore = 0;
  bool _hasInsufficientContent = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _loadData();
  }

  Future<void> _loadHighScore() async {
    final high = await DataService().getHighScore('picture_guess');
    if (mounted) setState(() => _highScore = high);
  }

  Future<void> _loadData() async {
    List<VocabularyItem> items = [];

    try {
      final safeProvider = SafeGameContentProvider(DataService());

      // Get items, but we need ones with Img URL strictly?
      // The SafeProvider ensures "Learned" content.
      // If learned content doesn't have images, this game is broken for them.
      // But we must obey strict rules.

      final candidates = await safeProvider.getEligibleVocabulary(minCount: 4);

      // Filter for those with images
      items = candidates
          .where((i) => i.imageUrl != null && i.imageUrl!.isNotEmpty)
          .toList();

      if (items.length < 4) {
        if (AppConfig.isProduction) throw InsufficientContentException();
      }
    } on InsufficientContentException catch (_) {
      if (mounted) {
        AnalyticsService().logGameBlockedInsufficientContent('Picture Guess');
        setState(() {
          _isLoading = false;
          _hasInsufficientContent = true;
        });
        return;
      }
    } catch (e) {
      debugPrint("PictureGuess: Error loading dynamic data: $e");
    }

    if (items.isNotEmpty) {
      setState(() {
        _allItems = items..shuffle();
        _isLoading = false;
        _nextRound();
      });
    } else {
      if (AppConfig.isProduction) {
        if (mounted) {
          AnalyticsService().logGameBlockedInsufficientContent('Picture Guess');
          setState(() {
            _isLoading = false;
            _hasInsufficientContent = true;
          });
        }
      } else {
        // Dev Fallback
        setState(() {
          _isLoading = false;
          _hasInsufficientContent = true;
        });
      }
    }
  }

  void _nextRound() {
    if (_allItems.isEmpty) {
      _unlockNextLevel();
      _showCompletionDialog();
      return;
    }

    setState(() {
      _currentItem = _allItems.removeLast();
      _answered = false;

      // Options
      final correct = _currentItem!.word;
      final distractors = <String>{};

      // Strict Rule: No random/mock in production.
      final pool = _allItems.toList();
      int attempts = 0;
      while (distractors.length < 3 && attempts < 50) {
        attempts++;
        if (pool.isNotEmpty) {
          final item = pool[Random().nextInt(pool.length)];
          if (item.word != correct) distractors.add(item.word);
        } else {
          break;
        }
      }

      // Fallback
      if (distractors.length < 3) {
        distractors.add('Apple');
        distractors.add('Banana');
        distractors.add('Cherry');
      }

      _options = [correct, ...distractors.take(3)]..shuffle();
    });
  }

  void _handleOptionTap(String option) {
    if (_answered) return;

    setState(() {
      _answered = true;
    });

    if (option == _currentItem!.word) {
      SoundService().playSuccess();
      setState(() {
        _score += 10;
        if (_score > _highScore) {
          _highScore = _score;
          DataService().saveHighScore('picture_guess', _score);
        }
      });
    } else {
      SoundService().playError();
    }

    Future.delayed(const Duration(seconds: 1), _nextRound);
  }

  Future<void> _unlockNextLevel() async {
    await LevelManager().unlockNextLevel('picture_guess', widget.level);
    await LevelManager().saveStars('picture_guess', widget.level, 3);
  }

  void _showCompletionDialog() {
    SoundService().playCompletion();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text(
          'Round Complete!',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'You scored $_score!',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Menu'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close Dialog
              _loadData();
            },
            child: const Text('Replay'),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint("Asset load error: $path -> $error");
          return const Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: Colors.white24,
              size: 50,
            ),
          );
        },
      );
    } else {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: Colors.white24,
              size: 50,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasInsufficientContent) {
      return Scaffold(
        backgroundColor: const Color(0xFF030305),
        appBar: AppBar(
          title: const Text("Picture Guess"),
          backgroundColor: Colors.transparent,
        ),
        body: InsufficientContentWidget(
          onGoToDailyTasks: () => Navigator.pop(context),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF030305),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentItem == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFF030305),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Picture Guess",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                "Score: $_score",
                style: const TextStyle(
                  color: Color(0xFF4FACFE),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _currentItem!.imageUrl != null
                      ? _buildImage(_currentItem!.imageUrl!)
                      : const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white24,
                            size: 48,
                          ),
                        ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(24),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: _options.map((opt) {
                final isCorrect = opt == _currentItem!.word;
                // If answered, show Green for correct one.
                // If this specific button was tapped (not tracked here easily unless we track picked option),
                // we just show Green for correct answer to educate user.
                Color color = const Color(0xFF1E1E2C);
                Color textColor = Colors.white;

                if (_answered) {
                  if (isCorrect) {
                    color = Colors.greenAccent.withValues(alpha: 0.2);
                    textColor = Colors.greenAccent;
                  } else {
                    color = Colors.white10;
                    textColor = Colors.white38;
                  }
                }

                return FilledButton(
                  onPressed: () => _handleOptionTap(opt),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
