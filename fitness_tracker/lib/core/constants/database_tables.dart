/// Database table and column name constants
class DatabaseTables {
  DatabaseTables._();

  // Table Names
  static const String targets = 'targets';
  static const String workoutSets = 'workout_sets';

  // Targets Table Columns
  static const String targetId = 'id';
  static const String targetMuscleGroup = 'muscle_group';
  static const String targetWeeklyGoal = 'weekly_goal';
  static const String targetCreatedAt = 'created_at';

  // Workout Sets Table Columns
  static const String setId = 'id';
  static const String setMuscleGroup = 'muscle_group';
  static const String setExerciseName = 'exercise_name';
  static const String setReps = 'reps';
  static const String setWeight = 'weight';
  static const String setDate = 'date';
  static const String setCreatedAt = 'created_at';
}