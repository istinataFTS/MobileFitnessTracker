/// Database table and column name constants
/// Centralizes all database schema definitions to avoid hardcoding
class DatabaseTables {
  DatabaseTables._();

  // ==================== TABLE NAMES ====================
  static const String targets = 'targets';
  static const String workoutSets = 'workout_sets';
  static const String exercises = 'exercises';
  static const String meals = 'meals';
  static const String nutritionLogs = 'nutrition_logs';
  static const String exerciseMuscleFactors = 'exercise_muscle_factors';
  static const String muscleStimulus = 'muscle_stimulus';

  // ==================== TARGETS TABLE COLUMNS ====================
  static const String targetId = 'id';
  static const String targetType = 'type';
  static const String targetCategoryKey = 'category_key';
  static const String targetValue = 'target_value';
  static const String targetUnit = 'unit';
  static const String targetPeriod = 'period';
  static const String targetCreatedAt = 'created_at';

  // Legacy target columns kept for migration only
  static const String legacyTargetMuscleGroup = 'muscle_group';
  static const String legacyTargetWeeklyGoal = 'weekly_goal';

  // ==================== WORKOUT SETS TABLE COLUMNS ====================
  static const String setId = 'id';
  static const String setExerciseId = 'exercise_id';
  static const String setReps = 'reps';
  static const String setWeight = 'weight';
  static const String setIntensity = 'intensity';
  static const String setDate = 'date';
  static const String setCreatedAt = 'created_at';

  // ==================== EXERCISES TABLE COLUMNS ====================
  static const String exerciseId = 'id';
  static const String exerciseName = 'name';
  static const String exerciseMuscleGroups = 'muscle_groups';
  static const String exerciseCreatedAt = 'created_at';

  // ==================== MEALS TABLE COLUMNS ====================
  static const String mealId = 'id';
  static const String mealName = 'name';
  static const String mealServingSize = 'serving_size_grams';
  static const String mealCarbsPer100g = 'carbs_per_100g';
  static const String mealProteinPer100g = 'protein_per_100g';
  static const String mealFatPer100g = 'fat_per_100g';
  static const String mealCaloriesPer100g = 'calories_per_100g';
  static const String mealCreatedAt = 'created_at';

  // ==================== NUTRITION LOGS TABLE COLUMNS ====================
  static const String nutritionLogId = 'id';
  static const String nutritionLogMealId = 'meal_id';
  static const String nutritionLogMealName = 'meal_name';
  static const String nutritionLogGrams = 'grams';
  static const String nutritionLogCarbs = 'carbs';
  static const String nutritionLogProtein = 'protein';
  static const String nutritionLogFat = 'fat';
  static const String nutritionLogCalories = 'calories';
  static const String nutritionLogDate = 'date';
  static const String nutritionLogCreatedAt = 'created_at';

  // ==================== EXERCISE MUSCLE FACTORS TABLE COLUMNS ====================
  static const String factorId = 'id';
  static const String factorExerciseId = 'exercise_id';
  static const String factorMuscleGroup = 'muscle_group';
  static const String factorValue = 'factor';
  static const String factorCreatedAt = 'created_at';

  // ==================== MUSCLE STIMULUS TABLE COLUMNS ====================
  static const String stimulusId = 'id';
  static const String stimulusMuscleGroup = 'muscle_group';
  static const String stimulusDate = 'date';
  static const String stimulusDailyStimulus = 'daily_stimulus';
  static const String stimulusRollingWeeklyLoad = 'rolling_weekly_load';
  static const String stimulusLastSetTimestamp = 'last_set_timestamp';
  static const String stimulusLastSetStimulus = 'last_set_stimulus';
  static const String stimulusCreatedAt = 'created_at';
  static const String stimulusUpdatedAt = 'updated_at';
}