import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gravity_app/services/sound_service.dart';
import 'package:gravity_app/features/daily_sentences/daily_sentence_model.dart';
import 'package:gravity_app/features/daily_sentences/daily_sentence_service.dart';
import 'package:gravity_app/models/vocabulary_item.dart';
import 'package:gravity_app/models/verb_item.dart';
import 'package:gravity_app/services/data_service.dart';
import 'package:gravity_app/screens/games/word_match_screen.dart';
import 'package:gravity_app/screens/games/flashcard_flip_screen.dart';
import 'package:gravity_app/screens/games/word_builder_screen.dart';
import 'package:gravity_app/screens/games/synonym_swap_screen.dart';
import 'package:gravity_app/screens/games/antonym_attack_screen.dart';
import 'package:gravity_app/screens/games/word_search_screen.dart';
import 'package:gravity_app/screens/games/fill_the_gap_screen.dart';
import 'package:gravity_app/screens/games/word_categories_screen.dart';
import 'package:gravity_app/screens/games/grammar/sentence_scramble_screen.dart';
import 'package:gravity_app/screens/games/grammar/grammar_choice_screen.dart';
import 'package:gravity_app/screens/games/grammar/error_hunt_screen.dart';
import 'package:gravity_app/screens/games/grammar/tense_trainer_screen.dart';
import 'package:gravity_app/screens/games/grammar/parts_of_speech_screen.dart';
import 'package:gravity_app/screens/games/grammar/sentence_builder_screen.dart';
import 'package:gravity_app/screens/games/speed_vocabulary_screen.dart';
import 'package:gravity_app/screens/games/speaking/repeat_after_me_screen.dart';
import 'package:gravity_app/screens/games/speaking/pronunciation_match_screen.dart';
import 'package:gravity_app/screens/games/speaking/sound_picker_screen.dart';
import 'package:gravity_app/screens/games/speaking/tongue_twister_screen.dart';
import 'package:gravity_app/screens/games/speaking/read_aloud_screen.dart';
import 'package:gravity_app/screens/games/listening/audio_guess_screen.dart';
import 'package:gravity_app/screens/games/listening/dictation_game_screen.dart';
import 'package:gravity_app/screens/games/listening/conversation_catch_screen.dart';
import 'package:gravity_app/screens/games/casual/hangman_game_screen.dart';
import 'package:gravity_app/screens/games/casual/word_puzzle_screen.dart';
import 'package:gravity_app/screens/games/casual/quiz_battle_screen.dart';
import 'package:gravity_app/screens/games/casual/story_choice_screen.dart';
import 'package:gravity_app/screens/games/casual/word_race_screen.dart';
import 'package:gravity_app/screens/games/reading/story_builder_screen.dart';
import 'package:gravity_app/screens/games/reading/sentence_completion_screen.dart';
import 'package:gravity_app/screens/games/reading/reading_quest_screen.dart';
import 'package:gravity_app/screens/games/multiplayer/word_duel_lobby_screen.dart';
import 'package:gravity_app/screens/games/reading/emoji_to_sentence_screen.dart';
import 'package:gravity_app/models/game_filter.dart';
import 'package:gravity_app/services/tongue_twister_content_service.dart';
import 'package:gravity_app/services/read_aloud_content_service.dart';
import 'package:gravity_app/services/dictation_content_service.dart';
import 'package:gravity_app/services/audio_guess_content_service.dart';
import 'package:gravity_app/services/conversation_catch_content_service.dart';
import 'package:gravity_app/services/hangman_content_service.dart';
import 'package:gravity_app/services/quiz_battle_content_service.dart';
import 'package:gravity_app/services/story_adventure_content_service.dart';
import 'package:gravity_app/screens/games/game_filter_selection_screen.dart';

part 'games_hub_card_actions.dart';
part 'games_grid_sheet_logic.dart';
part 'games_grid_sheet_content.dart';

class GamesHubCard extends StatefulWidget {
  final VoidCallback? onGoToDailyTasks;
  final bool isLocked;
  final VoidCallback? onLockedTap;

  const GamesHubCard({
    super.key,
    this.onGoToDailyTasks,
    this.isLocked = false,
    this.onLockedTap,
  });

  @override
  State<GamesHubCard> createState() => _GamesHubCardState();
}

class _GamesHubCardState extends State<GamesHubCard> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;
  Future<void>? _gamesReadinessPreloadFuture;

  // Featured games for the carousel (Highlighting key playable/featured ones)
  List<Map<String, dynamic>> get _featuredGames => [
    {
      'title': 'Word Race', // Mapped from City Defense
      'subtitle': 'Beat the clock with vocabulary tasks!',
      'icon': Icons.keyboard_alt_rounded,
      'color': const Color(0xFF4FACFE), // Blue
      'type': 'vocab',
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WordRaceScreen()),
      ),
    },

    {
      'title': 'Error Hunt', // Mapped from Black Hole
      'subtitle': 'Find and fix mistakes.',
      'icon': Icons.bug_report_rounded,
      'color': const Color(0xFFC779D0), // Purple
      'type': 'grammar',
    },
    {
      'title': 'Word Match',
      'subtitle': 'Match words to pictures.',
      'icon': Icons.extension_rounded,
      'color': const Color(0xFF00E5FF), // Cyan
      'type': 'vocab',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _gamesReadinessPreloadFuture = _preloadGamesReadiness();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _preloadGamesReadiness() async {
    try {
      final dataService = DataService();
      await Future.wait([
        dataService.getLearnedVocabularyItems(),
        dataService.getLearnedVerbItems(),
        DailySentenceService().getDailySentences(),
        TongueTwisterContentService().getEligiblePhrases(),
        ReadAloudContentService().getEligibleItems(),
        DictationContentService().getEligibleSentences(),
        AudioGuessContentService().getEligibleQuestions(),
        ConversationCatchContentService().getEligibleConversations(),
        HangmanContentService().getEligibleWords(),
        QuizBattleContentService().getEligibleQuestions(),
        StoryAdventureContentService().getEligibleStories(),
      ]);
    } catch (e) {
      // Best-effort warmup; Games Grid has its own guarded readiness loader.
      debugPrint('GamesHubCard: readiness preload failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgStart = isDark
        ? const Color(0xFF1E1E2C)
        : colorScheme.primaryContainer;
    final bgEnd = isDark
        ? const Color(0xFF2A2A35)
        : colorScheme.secondaryContainer;

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Opacity(
        opacity: widget.isLocked ? 0.6 : 1.0,
        child: Container(
          height: 220, // Adjusted height
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : colorScheme.shadow.withValues(alpha: 0.12),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [bgStart, bgEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),

                // PageView Slideshow
                PageView.builder(
                  controller: _pageController,
                  itemCount: _featuredGames.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final game = _featuredGames[index];
                    return _buildSlideItem(game);
                  },
                ),

                // Indicators
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_featuredGames.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? (_featuredGames[index]['color'] as Color)
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),

                // "Games Hub" Label Badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black54
                          : colorScheme.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : colorScheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sports_esports,
                          size: 20,
                          color: isDark ? Colors.white : colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "GAMES HUB",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : colorScheme.onSurface,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GamesGridSheet extends StatefulWidget {
  const GamesGridSheet({super.key});

  @override
  State<GamesGridSheet> createState() => _GamesGridSheetState();
}

class _GamesGridSheetState extends State<GamesGridSheet> {
  // State variables for game content and unlocks
  bool _isAvailabilityLoading = true;
  bool _isFlashcardLocked = true;
  bool _isWordBuilderLocked = true;
  bool _isSynonymSwapLocked = true;
  bool _isAntonymAttackLocked = true;
  bool _isWordSearchLocked = true;
  static const int _minWordSearchWords = 5;
  bool _isFillTheGapLocked = true;
  bool _isPartsOfSpeechLocked = true;
  bool _isGrammarChoiceLocked = true;
  bool _isTenseTrainerLocked = true;
  bool _isSentenceBuilderLocked = true;
  bool _isSentenceScrambleLocked = true;
  bool _isErrorHuntLocked = true;
  bool _isSpeedVocabLocked = true;
  bool _isRepeatAfterMeLocked = true;
  bool _isPronunciationMatchLocked = true;
  bool _isTongueTwisterLocked = true;
  bool _isReadAloudLocked = true;
  bool _isDictationLocked = true;
  bool _isAudioGuessLocked = true;
  bool _isConversationCatchLocked = true;
  bool _isHangmanLocked = true;
  bool _isQuizBattleLocked = true;
  bool _isStoryAdventureLocked = true;
  bool _isWordRaceLocked = true;
  static const int _minGrammarWarmupWords = 8;
  static const int _minSentenceScrambleWarmupWords = 6;
  static const int _minTenseWarmupVerbs = 3;

  static const Map<String, String> _derivedGrammarPos = {
    'a': 'Article / Determiner',
    'an': 'Article / Determiner',
    'the': 'Article / Determiner',
    'and': 'Conjunction',
    'but': 'Conjunction',
    'or': 'Conjunction',
    'so': 'Conjunction',
    'because': 'Conjunction',
    'if': 'Conjunction',
    'i': 'Pronoun',
    'you': 'Pronoun',
    'he': 'Pronoun',
    'she': 'Pronoun',
    'it': 'Pronoun',
    'we': 'Pronoun',
    'they': 'Pronoun',
    'me': 'Pronoun',
    'him': 'Pronoun',
    'her': 'Pronoun',
    'us': 'Pronoun',
    'them': 'Pronoun',
    'in': 'Preposition',
    'on': 'Preposition',
    'at': 'Preposition',
    'to': 'Preposition',
    'for': 'Preposition',
    'with': 'Preposition',
    'from': 'Preposition',
    'by': 'Preposition',
    'of': 'Preposition',
    'over': 'Preposition',
    'under': 'Preposition',
    'between': 'Preposition',
    'into': 'Preposition',
    'through': 'Preposition',
    'during': 'Preposition',
    'before': 'Preposition',
    'after': 'Preposition',
    'above': 'Preposition',
    'below': 'Preposition',
    'around': 'Preposition',
    'near': 'Preposition',
    'about': 'Preposition',
    'am': 'Verb',
    'is': 'Verb',
    'are': 'Verb',
    'was': 'Verb',
    'were': 'Verb',
    'has': 'Verb',
    'have': 'Verb',
    'had': 'Verb',
    'will': 'Verb',
    'do': 'Verb',
    'does': 'Verb',
    'did': 'Verb',
  };

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAvailabilityLoading) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;

      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHigh
              : colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 14),
              Text(
                'Checking game readiness...',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return _buildContent();
  }
}

class _WordSearchAvailability {
  final bool isLocked;
  final int missing;

  const _WordSearchAvailability({
    required this.isLocked,
    required this.missing,
  });
}

class _WordSearchPlan {
  final int gridSize;
  final int wordsToPlace;

  const _WordSearchPlan({required this.gridSize, required this.wordsToPlace});
}
