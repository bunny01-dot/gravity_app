import 'package:flutter/material.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/data_service.dart';

class WordCategoriesScreen extends StatefulWidget {
  const WordCategoriesScreen({super.key});

  @override
  State<WordCategoriesScreen> createState() => _WordCategoriesScreenState();
}

class _WordCategoriesScreenState extends State<WordCategoriesScreen> {
  // Simplified mock categories for prototype
  final List<String> _categories = ['Space', 'Nature', 'Action'];

  // Words to sort. In a real app, Fetch items and tag them or use specific lists.
  // Here we manually create a small set for the game logic demonstration.
  final List<Map<String, dynamic>> _allWords = [
    {'word': 'Galaxy', 'category': 'Space', 'icon': Icons.star},
    {'word': 'Tree', 'category': 'Nature', 'icon': Icons.forest},
    {'word': 'Run', 'category': 'Action', 'icon': Icons.directions_run},
    {'word': 'Planet', 'category': 'Space', 'icon': Icons.public},
    {'word': 'Flower', 'category': 'Nature', 'icon': Icons.local_florist},
    {'word': 'Jump', 'category': 'Action', 'icon': Icons.hiking},
    {'word': 'Comet', 'category': 'Space', 'icon': Icons.rocket_launch},
    {'word': 'River', 'category': 'Nature', 'icon': Icons.water},
    {'word': 'Swim', 'category': 'Action', 'icon': Icons.pool},
  ];

  List<Map<String, dynamic>> _currentBatch = [];
  int _score = 0;
  int _highScore = 0; // Added High Score

  @override
  void initState() {
    super.initState();
    _startRound();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final high = await DataService().getHighScore('word_categories');
    if (mounted) setState(() => _highScore = high);
  }

  void _startRound() {
    setState(() {
      _currentBatch = List.from(_allWords)..shuffle();
      _score = 0;
    });
  }

  void _onItemDrop(Map<String, dynamic> item, String targetCategory) async {
    if (item['category'] == targetCategory) {
      SoundService().playSuccess();
      setState(() {
        _score += 50;
        _currentBatch.remove(item);
      });

      if (_currentBatch.isEmpty) {
        await _showCompletionDialog();
      }
    } else {
      SoundService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Wrong category! Try again."),
          backgroundColor: Colors.redAccent,
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  Future<void> _showCompletionDialog() async {
    SoundService().playCompletion();

    // Save High Score
    if (_score > _highScore) {
      _highScore = _score;
      await DataService().saveHighScore('word_categories', _score);
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
        title: Text(
          'Categorization Master!',
          style: TextStyle(color: onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score: $_score',
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.7),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'High Score: $_highScore',
              style: const TextStyle(color: Color(0xFF4FACFE), fontSize: 16),
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
              _startRound();
            },
            child: const Text('Replay'),
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
    final cardBg = isDark ? const Color(0xFF1E1E2C) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: onSurface),
        title: Text('Word Categories', style: TextStyle(color: onSurface)),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Column(
                // Stacked Display
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
      body: Column(
        children: [
          // Draggable Words Area
          Expanded(
            flex: 1,
            child: Center(
              child: _currentBatch.isEmpty
                  ? Text(
                      "All sorted!",
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.54),
                      ),
                    )
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: _currentBatch.map((item) {
                        return Draggable<Map<String, dynamic>>(
                          data: item,
                          feedback: Material(
                            color: Colors.transparent,
                            child: _buildWordChip(item, isDragging: true),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _buildWordChip(item),
                          ),
                          child: _buildWordChip(item),
                        );
                      }).toList(),
                    ),
            ),
          ),

          // Drop Zones
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _categories.map((category) {
                  return DragTarget<Map<String, dynamic>>(
                    onWillAcceptWithDetails: (details) => true,
                    onAcceptWithDetails: (details) =>
                        _onItemDrop(details.data, category),
                    builder: (context, candidateData, rejectedData) {
                      final bool isHovered = candidateData.isNotEmpty;
                      return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 100,
                            height: 150,
                            decoration: BoxDecoration(
                              color: isHovered
                                  ? const Color(
                                      0xFF4FACFE,
                                    ).withValues(alpha: 0.2)
                                  : (isDark
                                        ? Colors.white10
                                        : onSurface.withValues(alpha: 0.08)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isHovered
                                    ? const Color(0xFF4FACFE)
                                    : (isDark
                                          ? Colors.white24
                                          : onSurface.withValues(alpha: 0.16)),
                                width: isHovered ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getCategoryIcon(category),
                                  color: isHovered
                                      ? const Color(0xFF4FACFE)
                                      : onSurface.withValues(alpha: 0.7),
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  category,
                                  style: TextStyle(
                                    color: isHovered
                                        ? onSurface
                                        : onSurface.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate(target: isHovered ? 1 : 0)
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.1, 1.1),
                          );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordChip(Map<String, dynamic> item, {bool isDragging = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDragging
            ? const Color(0xFF4FACFE)
            : (isDark
                  ? const Color(0xFF2A2A35)
                  : onSurface.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: const Color(0xFF4FACFE).withValues(alpha: 0.5),
                  blurRadius: 15,
                ),
              ]
            : [],
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item['icon'] as IconData,
            color: isDragging ? Colors.white : onSurface.withValues(alpha: 0.7),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            item['word'],
            style: TextStyle(
              color: isDragging ? Colors.white : onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Space':
        return Icons.rocket_launch_rounded;
      case 'Nature':
        return Icons.forest_rounded;
      case 'Action':
        return Icons.run_circle_outlined;
      default:
        return Icons.category_rounded;
    }
  }
}
