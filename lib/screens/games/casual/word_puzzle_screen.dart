import 'package:flutter/material.dart';

import 'package:gravity_app/services/sound_service.dart';

class WordPuzzleScreen extends StatefulWidget {
  const WordPuzzleScreen({super.key});

  @override
  State<WordPuzzleScreen> createState() => _WordPuzzleScreenState();
}

class _WordPuzzleScreenState extends State<WordPuzzleScreen> {
  // Simple 5x5 grid for demo
  // ' ' = empty user fillable, '#' = block, 'A' = pre-filled answer

  final int _gridSize = 5;

  // Solution Grid
  final List<List<String>> _solution = [
    ['C', 'A', 'T', '#', 'D'],
    ['#', 'R', '#', 'G', 'O'],
    ['B', 'T', 'S', '#', 'G'],
    ['U', '#', 'U', 'N', '#'],
    ['S', 'K', 'Y', '#', '#'],
  ];

  // User Grid (initially masking solution)
  late List<List<String>> _userGrid;

  // Blocks
  final List<List<bool>> _blocks = [
    [false, false, false, true, false],
    [true, false, true, false, false],
    [false, false, false, true, false],
    [false, true, false, false, true],
    [false, false, false, true, true],
  ];

  // Which cells are pre-filled hints?
  final List<List<bool>> _hints = [
    [true, false, false, false, true],
    [false, false, false, true, false],
    [false, false, false, false, false],
    [false, false, false, false, false],
    [false, false, false, false, false],
  ];

  int? _selectedRow;
  int? _selectedCol;

  @override
  void initState() {
    super.initState();
    _initGrid();
  }

  void _initGrid() {
    _userGrid = List.generate(_gridSize, (r) {
      return List.generate(_gridSize, (c) {
        if (_blocks[r][c]) return '#';
        if (_hints[r][c]) return _solution[r][c];
        return '';
      });
    });
  }

  void _onCellTap(int r, int c) {
    if (_blocks[r][c] || _hints[r][c]) return; // Can't edit blocks or hints
    setState(() {
      _selectedRow = r;
      _selectedCol = c;
    });
  }

  void _onKeyTap(String letter) {
    if (_selectedRow == null || _selectedCol == null) return;

    setState(() {
      _userGrid[_selectedRow!][_selectedCol!] = letter;
    });

    _checkWin();
  }

  void _checkWin() {
    bool complete = true;
    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        if (_blocks[r][c]) continue;
        if (_userGrid[r][c] != _solution[r][c]) {
          complete = false;
          break;
        }
      }
    }

    if (complete) {
      SoundService().playSuccess();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Puzzle Solved!"),
          content: const Text("Excellent work!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
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
    final cardBg = isDark ? const Color(0xFF1E1E2C) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Mini Crossword"),
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Grid
          Container(
            padding: const EdgeInsets.all(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _gridSize * _gridSize,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridSize,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  int r = index ~/ _gridSize;
                  int c = index % _gridSize;

                  bool isBlock = _blocks[r][c];
                  bool isSelected = r == _selectedRow && c == _selectedCol;
                  bool isHint = _hints[r][c];
                  String char = _userGrid[r][c];

                  if (isBlock) {
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }

                  return GestureDetector(
                    onTap: () => _onCellTap(r, c),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.amberAccent
                            : (isHint
                                  ? (isDark
                                        ? Colors.white24
                                        : onSurface.withValues(alpha: 0.14))
                                  : Colors.white),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isDark
                              ? Colors.white24
                              : onSurface.withValues(alpha: 0.18),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        char,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const Spacer(),

          // Keyboard
          Container(
            padding: const EdgeInsets.all(8),
            color: cardBg,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split('').map((l) {
                return GestureDetector(
                  onTap: () => _onKeyTap(l),
                  child: Container(
                    width: 36,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white10
                          : onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l,
                      style: TextStyle(
                        color: onSurface,
                        fontWeight: FontWeight.bold,
                      ),
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
