/// Configuration for Symbol Game level progression based on user score.
class LevelConfig {
  /// Defines the score ranges required to unlock each level.
  /// The key is the level number (1-7), and the value is a map with 'min' and 'max' score thresholds.
  static const Map<int, Map<String, int>> scoreThresholds = {
    1: {'min': 0, 'max': 999},
    2: {'min': 1000, 'max': 1999},
    3: {'min': 2000, 'max': 2999},
    4: {'min': 3000, 'max': 3999},
    5: {'min': 4000, 'max': 4999},
    6: {'min': 5000, 'max': 5999},
    7: {'min': 6000, 'max': 9999999}, // Max level, anything above 6000
  };

  /// Calculates the highest unlocked level based on the user's total score.
  static int getUnlockedLevel(int score) {
    int maxUnlockedLevel = 1;

    for (var entry in scoreThresholds.entries) {
      if (score >= entry.value['min']!) {
        maxUnlockedLevel = entry.key;
      }
    }

    return maxUnlockedLevel;
  }
}
