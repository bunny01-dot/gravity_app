import 'package:flutter/material.dart';
import 'package:gravity_app/models/game_filter.dart';
import 'package:gravity_app/services/game_content_service.dart';

class GameFilterSelectionScreen extends StatefulWidget {
  final String gameTitle;
  final Widget Function(GameFilter) gameBuilder;
  final GameFilter initialFilter;

  const GameFilterSelectionScreen({
    super.key,
    required this.gameTitle,
    required this.gameBuilder,
    this.initialFilter = const GameFilter(
      source: GameContentSource.currentStage,
      difficulty: GameDifficulty.medium,
    ),
  });

  @override
  State<GameFilterSelectionScreen> createState() =>
      _GameFilterSelectionScreenState();
}

class _GameFilterSelectionScreenState extends State<GameFilterSelectionScreen> {
  late GameContentSource _source;
  late GameDifficulty _difficulty;
  final GameContentService _contentService = GameContentService();
  bool _isCheckingAvailability = false;

  @override
  void initState() {
    super.initState();
    _source = widget.initialFilter.source;
    _difficulty = widget.initialFilter.difficulty;
    _refreshAvailability();
  }

  void _startGame() {
    final filter = GameFilter(source: _source, difficulty: _difficulty);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => widget.gameBuilder(filter)),
    );
  }

  Future<void> _refreshAvailability() async {
    if (mounted) setState(() => _isCheckingAvailability = true);
    try {
      // Preload content for the game  doesn't block Start button.
      final filter = GameFilter(source: _source, difficulty: _difficulty);
      await _contentService.getVocabularyItems(filter);
    } catch (_) {
      // Ignore errors; games handle their own fallback.
    } finally {
      if (mounted) setState(() => _isCheckingAvailability = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF030305)
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.gameTitle, style: TextStyle(color: onSurface)),
        centerTitle: true,
        leading: BackButton(color: onSurface),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your practice focus',
                style: TextStyle(
                  color: onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pick a word source and difficulty to start quickly.',
                style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
              Text(
                'Word Source',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.72),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              ...GameContentSource.values.map(_buildSourceCard),
              const SizedBox(height: 28),
              Text(
                'Difficulty',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.72),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: GameDifficulty.values
                    .map((difficulty) => _buildDifficultyChip(difficulty))
                    .toList(),
              ),
              const SizedBox(height: 16),
              if (_isCheckingAvailability)
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Loading content...',
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _startGame,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.disabled)) {
                        return Colors.white12;
                      }
                      return const Color(0xFF4FACFE);
                    }),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 16),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Start Game',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceCard(GameContentSource source) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final selected = _source == source;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (_source == source) return;
          setState(() => _source = source);
          _refreshAvailability();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF4FACFE).withValues(alpha: 0.2)
                : (isDark
                      ? const Color(0xFF1E1E2C)
                      : Colors.white.withValues(alpha: 0.95)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF4FACFE)
                  : (isDark
                        ? Colors.white10
                        : onSurface.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? const Color(0xFF4FACFE)
                    : onSurface.withValues(alpha: 0.34),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.title,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : onSurface.withValues(alpha: 0.72),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      source.subtitle,
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(GameDifficulty difficulty) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final selected = _difficulty == difficulty;
    return ChoiceChip(
      label: Text(difficulty.label),
      selected: selected,
      onSelected: (_) {
        if (_difficulty == difficulty) return;
        setState(() => _difficulty = difficulty);
        _refreshAvailability();
      },
      selectedColor: const Color(0xFF4FACFE).withValues(alpha: 0.3),
      backgroundColor: isDark
          ? const Color(0xFF1E1E2C)
          : Colors.white.withValues(alpha: 0.95),
      labelStyle: TextStyle(
        color: selected ? Colors.white : onSurface.withValues(alpha: 0.72),
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected
            ? const Color(0xFF4FACFE)
            : (isDark ? Colors.white10 : onSurface.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
