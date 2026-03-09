import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/services/safe_game_content_provider.dart';

import '../../services/level_manager.dart';

class WordBuilderScreen extends StatefulWidget {
  final int level;
  const WordBuilderScreen({super.key, this.level = 1});

  @override
  State<WordBuilderScreen> createState() => _WordBuilderScreenState();
}

class _WordBuilderScreenState extends State<WordBuilderScreen> {
  List<VocabularyItem> _allItems = [];
  VocabularyItem? _currentItem;
  List<String> _shuffledLetters = [];
  List<String?> _userAnswer = [];
  bool _isLoading = true;
  int _score = 0;
  int _highScore = 0;
  int _currentStreak = 0;
  bool _isChecking = false;
  bool _hasInsufficientContent = false;

  // Mode Selection
  bool _isVerbMode = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _loadData();
  }

  Future<void> _loadHighScore() async {
    final high = await DataService().getHighScore('word_builder');
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

      if (_isVerbMode) {
        // --- Verb Mode (DVeS) ---
        // Minimum 3 verbs to play?
        final verbs = await safeProvider.getEligibleVerbs(minCount: 3);

        items = verbs.map((v) {
          return VocabularyItem(
            id: v.id,
            word: v.base, // Base form
            definition: "Meaning: ${v.tamilMeaning}", // Hint
            exampleSentence: v.exampleSentences['present'] ?? '',
          );
        }).toList();
      } else {
        // --- Vocabulary Mode (DVS) ---
        // Minimum 3 vocab
        items = await safeProvider.getEligibleVocabulary(minCount: 3);
      }
    } catch (e) {
      debugPrint("WordBuilder: Error loading data: $e");
    }

    if (items.isNotEmpty) {
      setState(() {
        _allItems = items..shuffle();
        _isLoading = false;
        _hasInsufficientContent = false;
        _nextRound();
      });
    } else {
      setState(() {
        _isLoading = false;
        _hasInsufficientContent = true;
      });
    }
  }

  // ... (Keep existing _nextRound, _shuffleWord, etc. unchanged unless requested)

  // We need to inject the Mode Switcher into the Build method.
  // Since we are replacing class fields, we can't easily replace just the build method actions partial.
  // We will assume the existing build method structure and just modify relevant parts if possible,
  // but since we can't effectively "replace partial method body" with this tool easily for the actions list specifically
  // without context, I'll rely on replacing the whole file content for the top part or carefully targeting.
  // Wait, I can target the build method if I view it.

  // Let's stick to replacing the _loadData and class vars first.
  // I will skip the build method replacement in this block and do it in a second one to ensure safety.

  void _nextRound() {
    if (_allItems.isEmpty) {
      // Level Complete
      _unlockNextLevel();
      _showCompletionDialog();
      return;
    }

    setState(() {
      _currentItem = _allItems.removeLast();

      // Prepare letters
      String word = _currentItem!.word.toUpperCase();
      _userAnswer = List.filled(word.length, null);

      // Shuffle letters + Distractors
      List<String> chars = word.split('');

      // Add Distractors based on Level
      int distractorCount = 0;
      if (widget.level >= 3) distractorCount = 1;
      if (widget.level >= 6) distractorCount = 2;
      if (widget.level >= 9) distractorCount = 3;

      const String alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
      for (int i = 0; i < distractorCount; i++) {
        // Try to avoid adding a letter that is already needed if possible,
        // helps avoid confusion, but duplicates are actually harder, so allow them.
        chars.add(alphabet[Random().nextInt(alphabet.length)]);
      }

      chars.shuffle();
      _shuffledLetters = chars;

      _isChecking = false;
    });
  }

  void _onLetterTap(String letter, int index) {
    if (_isChecking) return;
    SoundService().playTap();

    // Find first empty slot
    int emptyIndex = _userAnswer.indexOf(null);
    if (emptyIndex != -1) {
      setState(() {
        _userAnswer[emptyIndex] = letter;
        _shuffledLetters[index] = ""; // Mark used in source
      });

      // Check if full
      if (!_userAnswer.contains(null)) {
        _checkAnswer();
      }
    }
  }

  void _onAnswerSlotTap(int index) {
    if (_isChecking || _userAnswer[index] == null) return;
    SoundService().playTap();

    setState(() {
      // Return letter to pool
      String letter = _userAnswer[index]!;
      _userAnswer[index] = null;

      // Put back in first empty source slot (or original position if we tracked it)
      // For simplicity, just finding first empty string in shuffled list
      int poolIndex = _shuffledLetters.indexOf("");
      if (poolIndex != -1) {
        _shuffledLetters[poolIndex] = letter;
      }
    });
  }

  void _checkAnswer() async {
    _isChecking = true;
    String userWord = _userAnswer.join("");
    String correctWord = _currentItem!.word.toUpperCase();

    if (userWord == correctWord) {
      SoundService().playSuccess();
      final newScore = _score + 10 + (_currentStreak * 2);
      setState(() {
        _score = newScore;
        _currentStreak++;
      });

      if (newScore > _highScore) {
        _highScore = newScore;
        DataService().saveHighScore('word_builder', newScore);
      }

      await Future.delayed(const Duration(seconds: 1));
      _nextRound();
    } else {
      SoundService().playError();
      setState(() {
        _currentStreak = 0;
        // Shake effect handled by UI update
      });

      await Future.delayed(const Duration(milliseconds: 800));
      // Reset mostly, or just let user fix it. Let's reset for simplicity
      setState(() {
        // Return all letters
        List<String> chars = correctWord.split('');
        chars.shuffle();
        _shuffledLetters = chars;
        _userAnswer = List.filled(correctWord.length, null);
        _isChecking = false;
      });
    }
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
        title: Text(
          _isVerbMode ? 'Build a Verb' : 'Build a Word',
          style: TextStyle(color: onSurface),
        ),
        actions: [
          // Mode Switcher
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isVerbMode = !_isVerbMode;
                  _score = 0;
                  _currentStreak = 0;
                });
                _loadData();
              },
              icon: const Icon(
                Icons.swap_horiz,
                size: 16,
                color: Color(0xFF4FACFE),
              ),
              label: Text(
                _isVerbMode ? "Verb" : "Vocab",
                style: const TextStyle(color: Color(0xFF4FACFE), fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4FACFE), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

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
          children: [
            // Hint Section
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_currentItem?.imageUrl != null)
                    Container(
                      height: 100,
                      width: 100,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: _getImageProvider(_currentItem!.imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Text(
                    _currentItem?.definition ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.7),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            // Answer Slots
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_userAnswer.length, (index) {
                  return GestureDetector(
                    onTap: () => _onAnswerSlotTap(index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 40,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _userAnswer[index] != null
                                ? onSurface
                                : onSurface.withValues(alpha: 0.24),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        _userAnswer[index] ?? '',
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Letter Pool
            Expanded(
              flex: 2,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(_shuffledLetters.length, (index) {
                  final letter = _shuffledLetters[index];
                  if (letter.isEmpty) {
                    return const SizedBox(
                      width: 50,
                      height: 50,
                    ); // Empty placeholder
                  }

                  return GestureDetector(
                    onTap: () => _onLetterTap(letter, index),
                    child:
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4FACFE),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF4FACFE,
                                ).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            letter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ).animate().scale(
                          duration: 200.ms,
                          curve: Curves.easeOutBack,
                        ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlockNextLevel() async {
    await LevelManager().unlockNextLevel('word_builder', widget.level);
    await LevelManager().saveStars('word_builder', widget.level, 3);
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
              _loadData(); // Replay
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
                        WordBuilderScreen(level: widget.level + 1),
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

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else {
      return NetworkImage(path);
    }
  }
}
