class XpRewardPolicy {
  static const int minimumReward = 100;
  static const int standardTaskReward = 250;
  static const int baseXpForLevel = 1000;
  static const int perLevelIncrease = 200;
  // Additional growth applied to each next level increment.
  // Increments become: 200, 220, 240, 260...
  static const int perLevelIncreaseGrowth = 20;

  static int requiredXpForLevel(int level) {
    assert(level > 0, 'Level must be positive.');
    final safeLevel = level < 1 ? 1 : level;
    final n = safeLevel - 1;
    final progressiveBonus =
        (perLevelIncreaseGrowth * n * (n - 1)) ~/ 2;
    return baseXpForLevel + (n * perLevelIncrease) + progressiveBonus;
  }

  static int normalize(int amount) {
    if (amount <= 0) return 0;
    if (amount < minimumReward) return minimumReward;
    return amount;
  }
}
