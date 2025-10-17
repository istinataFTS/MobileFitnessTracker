class MuscleGroups {
  
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
}
