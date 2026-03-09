enum GameContentSource {
  currentStage,
  learned,
  blackhole,
}

enum GameDifficulty {
  easy,
  medium,
  hard,
}

extension GameContentSourceLabels on GameContentSource {
  String get title {
    switch (this) {
      case GameContentSource.currentStage:
        return 'Current Plan';
      case GameContentSource.learned:
        return 'Learned Words';
      case GameContentSource.blackhole:
        return 'Blackhole Words';
    }
  }

  String get subtitle {
    switch (this) {
      case GameContentSource.currentStage:
        return "Practice your current plan words";
      case GameContentSource.learned:
        return 'Mix of all learned words';
      case GameContentSource.blackhole:
        return 'Review difficult words';
    }
  }
}

extension GameDifficultyLabels on GameDifficulty {
  String get label {
    switch (this) {
      case GameDifficulty.easy:
        return 'Easy';
      case GameDifficulty.medium:
        return 'Medium';
      case GameDifficulty.hard:
        return 'Hard';
    }
  }

  int get itemLimit {
    switch (this) {
      case GameDifficulty.easy:
        return 6;
      case GameDifficulty.medium:
        return 10;
      case GameDifficulty.hard:
        return 14;
    }
  }

  int get levelIndex {
    switch (this) {
      case GameDifficulty.easy:
        return 1;
      case GameDifficulty.medium:
        return 2;
      case GameDifficulty.hard:
        return 3;
    }
  }
}

class GameFilter {
  final GameContentSource source;
  final GameDifficulty difficulty;

  const GameFilter({
    required this.source,
    required this.difficulty,
  });
}
