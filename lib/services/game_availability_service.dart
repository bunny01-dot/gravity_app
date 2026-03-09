import 'package:shared_preferences/shared_preferences.dart';
import 'package:gravity_app/services/stage_progress_service.dart';

/// ISSUE #2 FIX: Game Requirements and Availability System
/// Tracks which games are playable based on learned words count

class GameRequirement {
  final String gameId;
  final String displayName;
  final int minLearnedWords;
  final String description;

  const GameRequirement({
    required this.gameId,
    required this.displayName,
    required this.minLearnedWords,
    required this.description,
  });
}

class GameAvailabilityService {
  static final GameAvailabilityService _instance =
      GameAvailabilityService._internal();
  factory GameAvailabilityService() => _instance;
  GameAvailabilityService._internal();

  // Define game requirements
  static const List<GameRequirement> gameRequirements = [
    GameRequirement(
      gameId: 'word_match',
      displayName: 'Word Match',
      minLearnedWords: 0,
      description: 'Always available',
    ),
    GameRequirement(
      gameId: 'flashcard_flip',
      displayName: 'Flashcard Flip',
      minLearnedWords: 0,
      description: 'Always available',
    ),
    GameRequirement(
      gameId: 'word_builder',
      displayName: 'Word Builder',
      minLearnedWords: 5,
      description: 'Build words from letters',
    ),
    GameRequirement(
      gameId: 'synonym_swap',
      displayName: 'Synonym Swap',
      minLearnedWords: 25,
      description: 'Match synonyms',
    ),
    GameRequirement(
      gameId: 'antonym_attack',
      displayName: 'Antonym Attack',
      minLearnedWords: 50,
      description: 'Find opposites',
    ),
  ];

  /// Get learned words count from user progress
  Future<int> getLearnedWordsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final stageService = StageProgressService();
    final currentStage = await stageService.getCurrentStage(prefs: prefs);
    final completedStages = currentStage > 1 ? currentStage - 1 : 0;
    const dailyWordCount = 5;
    return completedStages * dailyWordCount;
  }

  /// Check if a game is playable
  Future<bool> isGamePlayable(String gameId) async {
    final requirement = gameRequirements.firstWhere(
      (r) => r.gameId == gameId,
      orElse: () => const GameRequirement(
        gameId: '',
        displayName: '',
        minLearnedWords: 0,
        description: '',
      ),
    );

    final learnedWords = await getLearnedWordsCount();
    return learnedWords >= requirement.minLearnedWords;
  }

  /// Get words needed to unlock a game
  Future<int> getWordsNeeded(String gameId) async {
    final requirement = gameRequirements.firstWhere(
      (r) => r.gameId == gameId,
      orElse: () => const GameRequirement(
        gameId: '',
        displayName: '',
        minLearnedWords: 0,
        description: '',
      ),
    );

    final learnedWords = await getLearnedWordsCount();
    final needed = requirement.minLearnedWords - learnedWords;
    return needed > 0 ? needed : 0;
  }

  /// Check if first-time tutorial has been shown
  Future<bool> shouldShowFirstTimeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('games_unlock_hint_seen') != true;
  }

  /// Mark first-time tutorial as shown
  Future<void> markTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('games_unlock_hint_seen', true);
  }
}
