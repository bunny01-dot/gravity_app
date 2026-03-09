import 'package:flutter/material.dart';
import '../../services/level_manager.dart';

class LevelSelectionScreen extends StatefulWidget {
  final String gameId;
  final String gameTitle;
  final Function(int level) onLevelSelected;

  const LevelSelectionScreen({
    super.key,
    required this.gameId,
    required this.gameTitle,
    required this.onLevelSelected,
  });

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  int _unlockedLevel = 1;
  int _totalLevels = 1;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    const int totalLevels = 10;
    if (!mounted) return;
    setState(() {
      _unlockedLevel = totalLevels;
      _totalLevels = totalLevels;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E1E2C)
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.gameTitle, style: TextStyle(color: onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: onSurface),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF6A11CB), Color(0xFF2575FC)]
                  : const [Color(0xFFEAF3FF), Color(0xFFD8E8FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF1E1E2C), Color(0xFF2A2A35)]
                : const [Color(0xFFF4F8FF), Color(0xFFE8F1FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.8,
          ),
          itemCount: _totalLevels,
          itemBuilder: (context, index) {
            final int level = index + 1;
            final bool isLocked = level > _unlockedLevel;

            return _buildLevelCard(
              level,
              isLocked,
              isDark: isDark,
              onSurface: onSurface,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLevelCard(
    int level,
    bool isLocked, {
    required bool isDark,
    required Color onSurface,
  }) {
    return GestureDetector(
      onTap: () async {
        // Async
        if (!isLocked) {
          // Await the navigation result (requires callback to return Future)
          await widget.onLevelSelected(level);
          // Reload progress when back
          _loadProgress();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Complete previous levels to unlock!"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: FutureBuilder<int>(
        future: LevelManager().getStars(widget.gameId, level),
        builder: (context, snapshot) {
          int stars = snapshot.data ?? 0;

          return Container(
            decoration: BoxDecoration(
              color: isLocked
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.72))
                  : (isDark
                        ? const Color(0xFF33333E)
                        : Colors.white.withValues(alpha: 0.96)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLocked
                    ? (isDark
                          ? Colors.transparent
                          : onSurface.withValues(alpha: 0.08))
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : onSurface.withValues(alpha: 0.1)),
              ),
              boxShadow: isLocked
                  ? []
                  : [
                      BoxShadow(
                        color:
                            (isDark
                                    ? const Color(0xFF2575FC)
                                    : const Color(0xFF4FACFE))
                                .withValues(alpha: isDark ? 0.3 : 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLocked)
                  Icon(
                    Icons.lock,
                    size: 32,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : onSurface.withValues(alpha: 0.35),
                  )
                else
                  Text(
                    "$level",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : onSurface,
                    ),
                  ),
                const SizedBox(height: 10),
                if (!isLocked)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Icon(
                        Icons.star,
                        size: 16,
                        color: index < stars
                            ? Colors.amber
                            : (isDark
                                  ? Colors.white12
                                  : onSurface.withValues(alpha: 0.24)),
                      );
                    }),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
