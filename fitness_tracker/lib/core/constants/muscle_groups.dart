/// Core constants for muscle groups in the fitness tracker app
class MuscleGroups {
  /// List of all trackable muscle groups
  static const List<String> all = [
    'shoulder',
    'traps',
    'lats',
    'chest',
    'biceps',
    'triceps',
    'neck',
    'forearms',
    'obliques',
    'abs',
    'lower back',
    'glutes',
    'hamstring',
    'quads',
  ];

  /// Default weekly goals for each muscle group (in sets)
  static const Map<String, int> defaultWeeklyGoals = {
    'shoulder': 12,
    'traps': 8,
    'lats': 10,
    'chest': 15,
    'biceps': 12,
    'triceps': 12,
    'neck': 6,
    'forearms': 8,
    'obliques': 10,
    'abs': 15,
    'lower back': 8,
    'glutes': 12,
    'hamstring': 10,
    'quads': 15,
  };

  /// Display names for muscle groups (for UI)
  static const Map<String, String> displayNames = {
    'shoulder': 'Shoulders',
    'traps': 'Traps',
    'lats': 'Lats',
    'chest': 'Chest',
    'biceps': 'Biceps',
    'triceps': 'Triceps',
    'neck': 'Neck',
    'forearms': 'Forearms',
    'obliques': 'Obliques',
    'abs': 'Abs',
    'lower back': 'Lower Back',
    'glutes': 'Glutes',
    'hamstring': 'Hamstrings',
    'quads': 'Quads',
  };

  /// Validate if a muscle group name is valid
  static bool isValid(String muscleGroup) {
    return all.contains(muscleGroup.toLowerCase());
  }

  /// Get display name for a muscle group
  static String getDisplayName(String muscleGroup) {
    return displayNames[muscleGroup.toLowerCase()] ?? muscleGroup;
  }

  /// Get default weekly goal for a muscle group
  static int getDefaultGoal(String muscleGroup) {
    return defaultWeeklyGoals[muscleGroup.toLowerCase()] ?? 10;
  }
}