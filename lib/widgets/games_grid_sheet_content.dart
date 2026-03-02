// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, use_build_context_synchronously

part of 'games_hub_card.dart';

extension GamesGridSheetContent on _GamesGridSheetState {
  Widget _buildContent() {
    // REMOVED LockedGamesView entirely
    // REMOVED Info Banner entirely

    // ... Definitions ...
    final List<Map<String, dynamic>> categories = [
      {
        'title': 'ðŸ§  Vocabulary Games',
        'color': const Color(0xFF4FACFE),
        'games': [
          {
            'title': 'Word Match',
            'subtitle': _availabilitySubtitle('Match words to meanings', true),
            'hasContent': true,
            'icon': Icons.extension_rounded,
            'onTap': () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WordMatchEntryScreen()),
              );
            },
          },
          {
            'title': 'Flashcard Flip',
            'subtitle': _availabilitySubtitle(
              'Flip to master words',
              !_isFlashcardLocked,
            ),
            'hasContent': !_isFlashcardLocked,
            'icon': Icons.flip_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameFilterSelectionScreen(
                  gameTitle: 'Flashcard Flip',
                  gameBuilder: (filter) => FlashcardFlipScreen(filter: filter),
                ),
              ),
            ),
          },
          {
            'title': 'Word Builder',
            'subtitle': _availabilitySubtitle(
              'Unscramble the letters',
              !_isWordBuilderLocked,
            ),
            'hasContent': !_isWordBuilderLocked,
            'icon': Icons.build_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameFilterSelectionScreen(
                  gameTitle: 'Word Builder',
                  gameBuilder: (filter) => WordBuilderScreen(filter: filter),
                ),
              ),
            ),
          },
          {
            'title': 'Synonym Swap',
            'subtitle': _availabilitySubtitle(
              'Find similar meanings',
              !_isSynonymSwapLocked,
            ),
            'hasContent': !_isSynonymSwapLocked,
            'icon': Icons.sync_alt_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameFilterSelectionScreen(
                  gameTitle: 'Synonym Swap',
                  initialFilter: const GameFilter(
                    source: GameContentSource.learned,
                    difficulty: GameDifficulty.medium,
                  ),
                  gameBuilder: (filter) => SynonymSwapScreen(filter: filter),
                ),
              ),
            ),
          },
          {
            'title': 'Antonym Attack',
            'subtitle': _availabilitySubtitle(
              'Find opposite meanings',
              !_isAntonymAttackLocked,
            ),
            'hasContent': !_isAntonymAttackLocked,
            'icon': Icons.compare_arrows_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameFilterSelectionScreen(
                  gameTitle: 'Antonym Attack',
                  initialFilter: const GameFilter(
                    source: GameContentSource.learned,
                    difficulty: GameDifficulty.medium,
                  ),
                  gameBuilder: (filter) => AntonymAttackScreen(filter: filter),
                ),
              ),
            ),
          },
          {
            'title': 'Word Search',
            'subtitle': _availabilitySubtitle(
              'Swipe to find words',
              !_isWordSearchLocked,
            ),
            'hasContent': !_isWordSearchLocked,
            'icon': Icons.grid_on_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameFilterSelectionScreen(
                  gameTitle: 'Word Search',
                  gameBuilder: (filter) => WordSearchScreen(filter: filter),
                ),
              ),
            ),
          },
          {
            'title': 'Fill the Gap',
            'subtitle': _availabilitySubtitle(
              'Complete the sentence',
              !_isFillTheGapLocked,
            ),
            'hasContent': !_isFillTheGapLocked,
            'icon': Icons.short_text_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameFilterSelectionScreen(
                  gameTitle: 'Fill the Gap',
                  gameBuilder: (filter) => FillTheGapScreen(filter: filter),
                ),
              ),
            ),
          },
          {
            'title': 'Word Categories',
            'subtitle': 'Sort words into groups',
            'hasContent': true,
            'icon': Icons.category_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WordCategoriesScreen()),
            ),
          },
          {
            'title': 'Speed Vocabulary',
            'subtitle': _availabilitySubtitle(
              'Fast-paced drill',
              !_isSpeedVocabLocked,
            ),
            'hasContent': !_isSpeedVocabLocked,
            'icon': Icons.speed_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SpeedVocabularyScreen()),
            ),
          },
        ],
      },
      {
        'title': 'ðŸ§© Grammar Games',
        'color': const Color(0xFFC779D0),
        'games': [
          {
            'title': 'Error Hunt',
            'subtitle': _availabilitySubtitle(
              'Find and fix mistakes',
              !_isErrorHuntLocked,
            ),
            'icon': Icons.bug_report_rounded,
            'hasContent': !_isErrorHuntLocked,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ErrorHuntScreen()),
            ),
          },
          {
            'title': 'Sentence Scramble',
            'subtitle': _availabilitySubtitle(
              'Arrange words correctly',
              !_isSentenceScrambleLocked,
            ),
            'hasContent': !_isSentenceScrambleLocked,
            'icon': Icons.sort_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SentenceScrambleScreen()),
            ),
          },
          {
            'title': 'Grammar Choice',
            'subtitle': _availabilitySubtitle(
              'Multiple-choice questions',
              !_isGrammarChoiceLocked,
            ),
            'hasContent': !_isGrammarChoiceLocked,
            'icon': Icons.check_box_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GrammarChoiceScreen()),
            ),
          },
          {
            'title': 'Tense Trainer',
            'subtitle': _availabilitySubtitle(
              'Choose correct tense',
              !_isTenseTrainerLocked,
            ),
            'hasContent': !_isTenseTrainerLocked,
            'icon': Icons.timelapse_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TenseTrainerScreen()),
            ),
          },
          {
            'title': 'Parts of Speech',
            'subtitle': _availabilitySubtitle(
              'Identify nouns, verbs...',
              !_isPartsOfSpeechLocked,
            ),
            'hasContent': !_isPartsOfSpeechLocked,
            'icon': Icons.category_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PartsOfSpeechScreen()),
            ),
          },
          {
            'title': 'Sentence Builder',
            'subtitle': _availabilitySubtitle(
              'Build step by step',
              !_isSentenceBuilderLocked,
            ),
            'hasContent': !_isSentenceBuilderLocked,
            'icon': Icons.add_circle_outline_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SentenceBuilderGameScreen(),
              ),
            ),
          },
        ],
      },
      {
        'title': 'ðŸ—£ï¸ Speaking & Pronunciation',
        'color': const Color(0xFF00E5FF),
        'games': [
          {
            'title': 'Repeat After Me',
            'subtitle': _availabilitySubtitle(
              'Speech recognition',
              !_isRepeatAfterMeLocked,
            ),
            'hasContent': !_isRepeatAfterMeLocked,
            'icon': Icons.record_voice_over_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RepeatAfterMeScreen()),
            ),
          },
          {
            'title': 'Pronunciation Match',
            'subtitle': _availabilitySubtitle(
              'Match spoken word',
              !_isPronunciationMatchLocked,
            ),
            'hasContent': !_isPronunciationMatchLocked,
            'icon': Icons.graphic_eq_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PronunciationMatchScreen(),
              ),
            ),
          },
          {
            'title': 'Sound Picker',
            'subtitle': 'Identify phonetic sounds',
            'hasContent': true,
            'icon': Icons.hearing_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SoundPickerScreen()),
            ),
          },
          {
            'title': 'Tongue Twisters',
            'subtitle': _availabilitySubtitle(
              'Say this clearly',
              !_isTongueTwisterLocked,
            ),
            'hasContent': !_isTongueTwisterLocked,
            'icon': Icons.tornado_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TongueTwisterScreen()),
            ),
          },
          {
            'title': 'Read Aloud',
            'subtitle': _availabilitySubtitle(
              'Read this aloud',
              !_isReadAloudLocked,
            ),
            'hasContent': !_isReadAloudLocked,
            'icon': Icons.import_contacts_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReadAloudScreen()),
            ),
          },
        ],
      },
      {
        'title': 'ðŸŽ® Fun & Casual Games',
        'color': const Color(0xFFFF6B6B),
        'games': [
          {
            'title': 'Hangman',
            'subtitle': _availabilitySubtitle(
              'Guess the word',
              !_isHangmanLocked,
            ),
            'hasContent': !_isHangmanLocked,
            'icon': Icons.sentiment_dissatisfied_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HangmanGameScreen()),
            ),
          },
          {
            'title': 'Word Puzzle',
            'subtitle': 'Mini crosswords',
            'hasContent': true,
            'icon': Icons.grid_view_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WordPuzzleScreen()),
            ),
          },
          {
            'title': 'Quiz Battle',
            'subtitle': _availabilitySubtitle(
              'Calm daily quiz practice',
              !_isQuizBattleLocked,
            ),
            'hasContent': !_isQuizBattleLocked,
            'icon': Icons.flash_on_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuizBattleScreen()),
            ),
          },
          {
            'title': 'Story Adventure',
            'subtitle': _availabilitySubtitle(
              'Choose the next step',
              !_isStoryAdventureLocked,
            ),
            'hasContent': !_isStoryAdventureLocked,
            'icon': Icons.auto_stories_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StoryChoiceScreen()),
            ),
          },
          {
            'title': 'Word Race',
            'subtitle': _availabilitySubtitle(
              'Fast, calm word practice',
              !_isWordRaceLocked,
            ),
            'hasContent': !_isWordRaceLocked,
            'icon': Icons.timer_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WordRaceScreen()),
            ),
          },
        ],
      },
      {
        'title': 'ðŸŽ§ Listening Games',
        'color': const Color(0xFFFFD700),
        'games': [
          {
            'title': 'Audio Guess',
            'subtitle': _availabilitySubtitle(
              'Choose the word you hear',
              !_isAudioGuessLocked,
            ),
            'hasContent': !_isAudioGuessLocked,
            'icon': Icons.music_note_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AudioGuessScreen()),
            ),
          },
          {
            'title': 'Dictation Master',
            'subtitle': _availabilitySubtitle(
              'Listen and type what you hear',
              !_isDictationLocked,
            ),
            'hasContent': !_isDictationLocked,
            'icon': Icons.keyboard_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DictationGameScreen()),
            ),
          },
          {
            'title': 'Conversation Catch',
            'subtitle': _availabilitySubtitle(
              'Answer the dialogue question',
              !_isConversationCatchLocked,
            ),
            'hasContent': !_isConversationCatchLocked,
            'icon': Icons.forum_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ConversationCatchScreen(),
              ),
            ),
          },
        ],
      },
      {
        'title': 'ðŸ§‘â€ðŸ¤â€ðŸ§‘ Multiplayer',
        'color': const Color(0xFF00FF7F),
        'games': [
          {
            'title': 'Word Duel',
            'subtitle': 'Compete with friends',
            'hasContent': true,
            'icon': Icons.sports_kabaddi_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WordDuelLobbyScreen()),
            ),
          },
          {
            'title': 'Sentence Battle',
            'subtitle': 'Build sentences faster',
            'hasContent': true,
            'icon': Icons.flash_on_rounded,
            'onTap': () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Multiplayer coming soon!")),
              );
            },
          },
          {
            'title': 'Team Quiz',
            'subtitle': 'Group challenges',
            'hasContent': true,
            'icon': Icons.groups_rounded,
            'onTap': () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Multiplayer coming soon!")),
              );
            },
          },
        ],
      },
      {
        'title': 'ðŸ“š Reading & Writing',
        'color': const Color(0xFFE040FB),
        'games': [
          {
            'title': 'Story Builder',
            'subtitle': 'Fill blanks in story',
            'hasContent': true,
            'icon': Icons.edit_note_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StoryBuilderScreen()),
            ),
          },
          {
            'title': 'Sentence Completion',
            'subtitle': 'Finish the thought',
            'hasContent': true,
            'icon': Icons.more_horiz_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SentenceCompletionScreen(),
              ),
            ),
          },
          {
            'title': 'Reading Quest',
            'subtitle': 'Comprehension test',
            'hasContent': true,
            'icon': Icons.menu_book_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReadingQuestScreen()),
            ),
          },
          {
            'title': 'Emoji Translate',
            'subtitle': 'Emoji to sentence',
            'hasContent': true,
            'icon': Icons.emoji_emotions_rounded,
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmojiToSentenceScreen()),
            ),
          },
        ],
      },
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // Taller sheet
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 40, spreadRadius: 10),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                const Icon(Icons.grid_view_rounded, color: Color(0xFF4FACFE)),
                const SizedBox(width: 12),
                const Text(
                  "Game Library",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),

                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Scrollable List of Categories
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 50),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Text(
                        category['title'] as String,
                        style: TextStyle(
                          color: (category['color'] as Color),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 180, // Height for horizontal scroll
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        scrollDirection: Axis.horizontal,
                        itemCount: (category['games'] as List).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, gameIndex) {
                          final game = (category['games'] as List)[gameIndex];
                          return _buildGameCard(
                            context,
                            game,
                            category['color'] as Color,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper for availability badge
  Widget _buildAvailabilityBadge({required bool hasContent}) {
    if (hasContent) return const SizedBox.shrink();
    const color = Colors.orangeAccent;
    const label = 'Needs words';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context,
    Map<String, dynamic> game,
    Color color,
  ) {
    final hasContent = game['hasContent'] != false;

    return GestureDetector(
      onTap: () {
        SoundService().playTap();
        if (!hasContent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Learn a few words to play this mode.'),
              backgroundColor: Colors.orangeAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        if (game['onTap'] != null) {
          (game['onTap'] as VoidCallback)();
        }
      },
      child: Container(
        width: 160, // ISSUE #8 FIX: Widen tile to fit content
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon((game['icon'] as IconData), color: color, size: 20),
            ),
            const SizedBox(height: 12), // Fixed spacing instead of Spacer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    game['title'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.visible, // Allow wrap
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!hasContent) ...[
                    const SizedBox(height: 6),
                    _buildAvailabilityBadge(hasContent: hasContent),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    game['subtitle'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
