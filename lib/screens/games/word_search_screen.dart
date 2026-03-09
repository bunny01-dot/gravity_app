import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/safe_game_content_provider.dart';

import '../../services/level_manager.dart';

class WordSearchScreen extends StatefulWidget {
  final int level;
  const WordSearchScreen({super.key, this.level = 1});

  @override
  State<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends State<WordSearchScreen> {
  int _gridSize = 8;
  List<List<String>> _grid = [];
  List<String> _wordsToFind = [];
  List<String> _foundWords = [];
  List<Point> _selectedCells = [];

  bool _isLoading = true;
  Point? _startDrag;
  Point? _currentDrag;

  int _score = 0;
  int _highScore = 0;
  bool _hasInsufficientContent = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _startGame();
  }

  Future<void> _loadHighScore() async {
    final high = await DataService().getHighScore('word_search');
    if (mounted) setState(() => _highScore = high);
  }

  Future<void> _startGame() async {
    setState(() {
      _isLoading = true;
      _score = 0;
      _hasInsufficientContent = false;
    });

    List<String> wordsToUse = [];

    try {
      final safeProvider = SafeGameContentProvider(DataService());
      // Minimum 4 words for a game
      final items = await safeProvider.getEligibleVocabulary(minCount: 4);

      final valid = items
          .where((w) => w.word.length <= _gridSize && w.word.length > 2)
          .map((e) => e.word.toUpperCase())
          .toSet()
          .toList();

      if (valid.length >= 4) {
        wordsToUse = valid.take(5).toList();
      } else {
        debugPrint(
          "WordSearch: Warning, fewer items than requested were fetched.",
        );
        // We can still try to play if there's at least 1 word, but the game might
        // have an optimal minimum. Let's just use what we have if any.
        wordsToUse = valid;
      }
    } catch (e) {
      debugPrint("WordSearch: Error loading dynamic words: $e");
    }

    if (wordsToUse.isNotEmpty) {
      _generateGrid(wordsToUse);
    } else {
      setState(() {
        _isLoading = false;
        _hasInsufficientContent = true;
      });
    }
  }

  void _generateGrid(List<String> words) {
    // Initialize empty grid
    _grid = List.generate(_gridSize, (_) => List.filled(_gridSize, ''));
    _wordsToFind = words;
    _foundWords = [];

    final random = Random();

    for (String word in words) {
      bool placed = false;
      int attempts = 0;

      while (!placed && attempts < 100) {
        attempts++;
        // 0: horizontal, 1: vertical, 2: diagonal (simplified to H/V for now for easier play)
        int direction = random.nextInt(2);
        int row = random.nextInt(_gridSize);
        int col = random.nextInt(_gridSize);

        if (_canPlaceWord(word, row, col, direction)) {
          _placeWord(word, row, col, direction);
          placed = true;
        }
      }
    }

    // Fill empty cells
    const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (_grid[i][j] == '') {
          _grid[i][j] = letters[random.nextInt(letters.length)];
        }
      }
    }

    setState(() => _isLoading = false);
  }

  bool _canPlaceWord(String word, int row, int col, int direction) {
    if (direction == 0) {
      // Horizontal
      if (col + word.length > _gridSize) return false;
      for (int i = 0; i < word.length; i++) {
        if (_grid[row][col + i] != '' && _grid[row][col + i] != word[i])
          return false;
      }
    } else {
      // Vertical
      if (row + word.length > _gridSize) return false;
      for (int i = 0; i < word.length; i++) {
        if (_grid[row + i][col] != '' && _grid[row + i][col] != word[i])
          return false;
      }
    }
    return true;
  }

  void _placeWord(String word, int row, int col, int direction) {
    if (direction == 0) {
      for (int i = 0; i < word.length; i++) {
        _grid[row][col + i] = word[i];
      }
    } else {
      for (int i = 0; i < word.length; i++) {
        _grid[row + i][col] = word[i];
      }
    }
  }

  // --- Interaction Logic ---

  final GlobalKey _gridKey = GlobalKey();

  void _onPanStart(DragStartDetails details) {
    final point = _getGridPoint(details.globalPosition);
    if (point != null) {
      setState(() {
        _startDrag = point;
        _currentDrag = point;
        _updateSelectedCells();
      });
      SoundService().playTap();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final point = _getGridPoint(details.globalPosition);
    if (point != null && point != _currentDrag) {
      setState(() {
        _currentDrag = point;
        _updateSelectedCells();
      });
    }
  }

  Future<void> _unlockNextLevel() async {
    await LevelManager().unlockNextLevel('word_search', widget.level);
    await LevelManager().saveStars(
      'word_search',
      widget.level,
      3,
    ); // 3 stars for winning
  }

  void _onPanEnd(DragEndDetails details) {
    _checkSelection();
  }

  Point? _getGridPoint(Offset globalPosition) {
    final RenderBox? renderBox =
        _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final localPosition = renderBox.globalToLocal(globalPosition);
    final size = renderBox.size;

    // Bounds check
    if (localPosition.dx < 0 ||
        localPosition.dx >= size.width ||
        localPosition.dy < 0 ||
        localPosition.dy >= size.height) {
      return null;
    }

    double cellSize = size.width / _gridSize; // Assuming square aspect

    int col = (localPosition.dx / cellSize).floor();
    int row = (localPosition.dy / cellSize).floor();

    if (row >= 0 && row < _gridSize && col >= 0 && col < _gridSize) {
      return Point(row, col);
    }
    return null;
  }

  void _updateSelectedCells() {
    _selectedCells = [];
    if (_startDrag == null || _currentDrag == null) return;

    int r1 = _startDrag!.x.toInt();
    int c1 = _startDrag!.y.toInt();
    int r2 = _currentDrag!.x.toInt();
    int c2 = _currentDrag!.y.toInt();

    // Determine direction (snap to axis)
    int dr = r2 - r1;
    int dc = c2 - c1;

    if (dr == 0) {
      // Horizontal
      int start = min(c1, c2);
      int end = max(c1, c2);
      for (int c = start; c <= end; c++) _selectedCells.add(Point(r1, c));
    } else if (dc == 0) {
      // Vertical
      int start = min(r1, r2);
      int end = max(r1, r2);
      for (int r = start; r <= end; r++) _selectedCells.add(Point(r, c1));
    } else if (dr.abs() == dc.abs()) {
      // Diagonal
      int steps = dr.abs();
      int rStep = dr > 0 ? 1 : -1;
      int cStep = dc > 0 ? 1 : -1;
      for (int i = 0; i <= steps; i++) {
        _selectedCells.add(Point(r1 + (i * rStep), c1 + (i * cStep)));
      }
    }
  }

  void _checkSelection() async {
    if (_selectedCells.isEmpty) return;

    // Form word from selection
    // Sort logic needed if we selected backwards?
    // Actually current logic adds in order if simpler loops used,
    // but diagonal might be tricky. For now assume order follows list creation
    // We should strictly follow start->current text

    // Re-calculating properly for string formulation
    int r1 = _startDrag!.x.toInt();
    int c1 = _startDrag!.y.toInt();
    int r2 = _currentDrag!.x.toInt();
    int c2 = _currentDrag!.y.toInt();

    String formed = "";
    int dr = 0, dc = 0;

    if (r1 == r2) {
      dr = 0;
      dc = c2 > c1 ? 1 : -1;
    } else if (c1 == c2) {
      dr = r2 > r1 ? 1 : -1;
      dc = 0;
    } else if ((r2 - r1).abs() == (c2 - c1).abs()) {
      dr = r2 > r1 ? 1 : -1;
      dc = c2 > c1 ? 1 : -1;
    } else {
      // Invalid shape (not line)
      setState(() => _selectedCells = []);
      return;
    }

    int len = max((r2 - r1).abs(), (c2 - c1).abs()) + 1;
    for (int i = 0; i < len; i++) {
      formed += _grid[r1 + (i * dr)][c1 + (i * dc)];
    }

    // Check against word list (allow reverse selection?)
    if (_wordsToFind.contains(formed)) {
      if (!_foundWords.contains(formed)) {
        setState(() {
          _foundWords.add(formed);
          _score += 100; // Found word points
        });
        SoundService().playSuccess();

        if (_foundWords.length == _wordsToFind.length) {
          SoundService().playCompletion();
          _unlockNextLevel();
          await _showWinDialog();
        }
      }
    } else if (_wordsToFind.contains(formed.split('').reversed.join(''))) {
      // handle reverse selection
      String reversed = formed.split('').reversed.join('');
      if (!_foundWords.contains(reversed)) {
        setState(() {
          _foundWords.add(reversed);
          _score += 100; // Found word points
        });
        SoundService().playSuccess();
        if (_foundWords.length == _wordsToFind.length) {
          SoundService().playCompletion();
          _unlockNextLevel();
          await _showWinDialog();
        }
      }
    } else {
      SoundService().playError(); // Subtle error
    }

    setState(() => _selectedCells = []);
  }

  Future<void> _showWinDialog() async {
    SoundService().playCompletion();

    // Save High Score
    if (_score > _highScore) {
      _highScore = _score;
      await DataService().saveHighScore('word_search', _score);
    }

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
          title: Text('Puzzle Complete!', style: TextStyle(color: onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // Left align
            children: [
              Text(
                "You found all words!",
                style: TextStyle(color: onSurface.withValues(alpha: 0.72)),
              ),
              const SizedBox(height: 12),
              Text(
                "Score: $_score",
                style: TextStyle(
                  color: onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "High Score: $_highScore",
                style: TextStyle(color: Color(0xFF4FACFE)),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _startGame();
              },
              child: const Text('New Puzzle'),
            ),
          ],
        );
      },
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.indigo.shade50,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
      );
    }

    if (_wordsToFind.isEmpty || _hasInsufficientContent) {
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
        leading: BackButton(color: onSurface),
        title: Text('Word Search', style: TextStyle(color: onSurface)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Score: $_score",
                    style: const TextStyle(
                      color: Color(0xFF4FACFE),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Best: $_highScore",
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.62),
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
            // Word List
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _wordsToFind.map((word) {
                final isFound = _foundWords.contains(word);
                return AnimatedOpacity(
                  duration: 300.ms,
                  opacity: isFound ? 0.4 : 1.0,
                  child: Chip(
                    label: Text(
                      word,
                      style: TextStyle(
                        color: isFound ? Colors.greenAccent : onSurface,
                        fontWeight: FontWeight.bold,
                        decoration: isFound ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    backgroundColor: isDark
                        ? Colors.white10
                        : onSurface.withValues(alpha: 0.08),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            // Grid
            AspectRatio(
              aspectRatio: 1,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Container(
                  key: _gridKey,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E2C)
                        : Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _gridSize * _gridSize,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridSize,
                    ),
                    itemBuilder: (context, index) {
                      int row = index ~/ _gridSize;
                      int col = index % _gridSize;
                      String char = _grid[row][col];

                      // Check if part of current selection
                      bool isSelected = _selectedCells.any(
                        (p) => p.x == row && p.y == col,
                      );
                      // Determine if part of already found word? (Requires storing found coordinates. Skipped for brevity in this step)

                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4FACFE).withValues(alpha: 0.4)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          char,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : onSurface.withValues(alpha: 0.72),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
