import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gravity_app/models/vocabulary_item.dart';

import 'package:gravity_app/services/sound_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/data_service.dart';

import '../../services/level_manager.dart';
import 'package:gravity_app/services/safe_game_content_provider.dart';

class SynonymSwapScreen extends StatefulWidget {
  final int level;
  const SynonymSwapScreen({super.key, this.level = 1});

  @override
  State<SynonymSwapScreen> createState() => _SynonymSwapScreenState();
}

class _SynonymSwapScreenState extends State<SynonymSwapScreen> {
  static const int _minPlayableWords = 4;
  List<VocabularyItem> _allItems = [];
  List<VocabularyItem> _roundQueue = [];
  VocabularyItem? _currentItem;
  List<String> _options = [];
  int _correctIndex = -1;

  bool _isLoading = true;
  bool _hasInsufficientContent = false;
  bool _answered = false;
  int _selectedOptionIndex = -1;
  int _score = 0;
  int _highScore = 0;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _loadData();
  }

  Future<void> _loadHighScore() async {
    final high = await DataService().getHighScore('synonym_swap');
    if (mounted) setState(() => _highScore = high);
  }

  Future<void> _loadData() async {
    try {
      final safeProvider = SafeGameContentProvider(DataService());

      var items = await safeProvider.getEligibleVocabulary(
        minCount: _minPlayableWords,
      );

      items = items
          .where((item) => !_isVerbPos(item.pos))
          .where((item) => _playableSynonymsFor(item).isNotEmpty)
          .toList();

      if (items.length < _minPlayableWords) {
        // SafeGameContentProvider should return enough, but if it somehow fails,
        // we can still let the user play with fewer words or mock data if implemented elsewhere.
        debugPrint(
          "SynonymSwap: Warning, fewer items than requested were fetched.",
        );
      }

      setState(() {
        _allItems = items;
        _roundQueue = List.from(items); // Use all learned items for the round
        _isLoading = false;
        _hasInsufficientContent = false;
        _nextRound();
      });
    } catch (e) {
      debugPrint("SynonymSwap: Error loading data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          // In case of error let the fail state handle it, or exit gracefully
        });
      }
    }
  }

  void _nextRound() {
    if (_roundQueue.isEmpty) {
      if (_score == 0 && !_hasInsufficientContent) {
        return; // Early exit if immediate fail
      }
      _unlockNextLevel();
      _showCompletionDialog();
      return;
    }

    setState(() {
      _currentItem = _roundQueue.removeLast();
      _answered = false;
      _selectedOptionIndex = -1;

      final currentSynonyms = _playableSynonymsFor(_currentItem!);
      if (currentSynonyms.isEmpty) {
        _hasInsufficientContent = true;
        return;
      }
      final correct = currentSynonyms.first;

      final distractors = <String>{};
      int safety = 0;

      while (distractors.length < 3 && safety < 50) {
        safety++;
        final randomItem = _allItems[Random().nextInt(_allItems.length)];
        final playableSynonyms = _playableSynonymsFor(randomItem);

        if (randomItem.word != _currentItem!.word &&
            playableSynonyms.isNotEmpty) {
          final d = playableSynonyms.first;
          if (!distractors.contains(d) && d != correct) {
            distractors.add(d);
          }
        }
      }

      if (distractors.length < 3) {
        _hasInsufficientContent = true;
        return;
      }

      _options = [correct, ...distractors]..shuffle();
      _correctIndex = _options.indexOf(correct);
    });
  }

  bool _isVerbPos(String pos) {
    final normalized = pos.trim().toLowerCase();
    return normalized == 'verb' || normalized.contains('verb');
  }

  List<String> _playableSynonymsFor(VocabularyItem item) {
    final normalizedWord = _normalizeWord(item.word);
    return item.synonyms
        .map(_normalizeWord)
        .where((syn) => syn.isNotEmpty && syn != normalizedWord)
        .toSet()
        .toList();
  }

  String _normalizeWord(String value) {
    final lower = value.trim().toLowerCase();
    final cleaned = lower.replaceAll(RegExp(r"[^a-z']"), '');
    return cleaned.replaceAll(RegExp(r"^'+|'+$"), '');
  }

  void _handleOptionTap(int index) async {
    if (_answered) return;

    SoundService().playTap();
    setState(() {
      _answered = true;
      _selectedOptionIndex = index;
    });

    if (index == _correctIndex) {
      SoundService().playSuccess();
      final newScore = _score + 100 + (_streak * 10);
      setState(() {
        _streak++;
        _score = newScore;
      });

      if (newScore > _highScore) {
        _highScore = newScore;
        DataService().saveHighScore('synonym_swap', newScore);
      }
    } else {
      SoundService().playError();
      setState(() {
        _streak = 0;
      });
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    _nextRound();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final scaffoldBg = isDark
        ? const Color(0xFF030305)
        : theme.scaffoldBackgroundColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.indigo.shade50,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
      );
    }

    if (_allItems.isEmpty || _hasInsufficientContent) {
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

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Synonym Swap', style: TextStyle(color: onSurface)),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Score: $_score',
                    style: const TextStyle(
                      color: Color(0xFF4FACFE),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Best: $_highScore',
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Find the synonym for:",
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.54),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentItem!.word,
              style: TextStyle(
                color: onSurface,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn().scale(),

            const SizedBox(height: 48),

            ...List.generate(_options.length, (index) {
              Color bgColor = isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : onSurface.withValues(alpha: 0.05);
              Color borderColor = isDark
                  ? Colors.white10
                  : onSurface.withValues(alpha: 0.1);

              if (_answered) {
                if (index == _correctIndex) {
                  bgColor = Colors.green.withValues(alpha: 0.2);
                  borderColor = Colors.green;
                } else if (index == _selectedOptionIndex) {
                  bgColor = Colors.red.withValues(alpha: 0.2);
                  borderColor = Colors.red;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child:
                    InkWell(
                      onTap: () => _handleOptionTap(index),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 24,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _options[index],
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_answered && index == _correctIndex)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                              ),
                            if (_answered &&
                                index == _selectedOptionIndex &&
                                index != _correctIndex)
                              const Icon(
                                Icons.cancel_rounded,
                                color: Colors.red,
                              ),
                          ],
                        ),
                      ),
                    ).animate().slideY(
                      begin: 0.5,
                      end: 0,
                      delay: (index * 100).ms,
                      duration: 400.ms,
                      curve: Curves.easeOutQuart,
                    ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _unlockNextLevel() async {
    await LevelManager().unlockNextLevel('synonym_swap', widget.level);
    await LevelManager().saveStars('synonym_swap', widget.level, 3);
  }

  void _showCompletionDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        title: Text('Level Complete!', style: TextStyle(color: onSurface)),
        content: Text(
          'You scored $_score!',
          style: TextStyle(color: onSurface.withValues(alpha: 0.7)),
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
              Navigator.pop(context);
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Replay'),
          ),
          if (widget.level < 10)
            FilledButton(
              onPressed: () {
                Navigator.pop(context); // Close Dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SynonymSwapScreen(level: widget.level + 1),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4FACFE),
              ),
              child: const Text('Next Level'),
            ),
        ],
      ),
    );
  }
}
