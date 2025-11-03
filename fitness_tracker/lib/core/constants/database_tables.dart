/// Database table and column name constants
/// Following best practices: all strings centralized, no hardcoding
class DatabaseTables {
  DatabaseTables._();

  // ==================== Table Names ====================
  static const String targets = 'targets';
  static const String workoutSets = 'workout_sets';
  static const String exercises = 'exercises';

  // ==================== Targets Table Columns ====================
  static const String targetId = 'id';
  static const String targetMuscleGroup = 'muscle_group';
  static const String targetWeeklyGoal = 'weekly_goal';
  static const String targetCreatedAt = 'created_at';

  // ==================== Workout Sets Table Columns ====================
  static const String setId = 'id';
  static const String setExerciseId = 'exercise_id';
  static const String setReps = 'reps';
  static const String setWeight = 'weight';
  static const String setDate = 'date';
  static const String setCreatedAt = 'created_at';

  // ==================== Exercises Table Columns ====================
  static const String exerciseId = 'id';
  static const String exerciseName = 'name';
  static const String exerciseMuscleGroups = 'muscle_groups'; // Stored as JSON array
  static const String exerciseCreatedAt = 'created_at';
}