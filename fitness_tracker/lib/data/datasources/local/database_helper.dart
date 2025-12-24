import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/constants/database_tables.dart';
import '../../../core/constants/muscle_stimulus_constants.dart';
import '../../../config/env_config.dart';

/// Centralized database helper with migration management
/// Singleton pattern ensures single database instance throughout app lifecycle
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  /// Get database instance (creates if doesn't exist)
  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Database is not supported on web platform');
    }
    
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database with versioning and migrations
  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Database is not supported on web platform');
    }
    
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, EnvConfig.databaseName);

    return await openDatabase(
      path,
      version: EnvConfig.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create all tables for new database
  Future<void> _onCreate(Database db, int version) async {
    // Targets table
    await db.execute('''
      CREATE TABLE ${DatabaseTables.targets} (
        ${DatabaseTables.targetId} TEXT PRIMARY KEY,
        ${DatabaseTables.targetMuscleGroup} TEXT NOT NULL UNIQUE,
        ${DatabaseTables.targetWeeklyGoal} INTEGER NOT NULL,
        ${DatabaseTables.targetCreatedAt} TEXT NOT NULL
      )
    ''');

    // Workout Sets table
    await db.execute('''
      CREATE TABLE ${DatabaseTables.workoutSets} (
        ${DatabaseTables.setId} TEXT PRIMARY KEY,
        ${DatabaseTables.setExerciseId} TEXT NOT NULL,
        ${DatabaseTables.setReps} INTEGER NOT NULL,
        ${DatabaseTables.setWeight} REAL NOT NULL,
        ${DatabaseTables.setIntensity} INTEGER NOT NULL DEFAULT ${MuscleStimulus.defaultIntensity},
        ${DatabaseTables.setDate} TEXT NOT NULL,
        ${DatabaseTables.setCreatedAt} TEXT NOT NULL
      )
    ''');

    // Exercises table
    await db.execute('''
      CREATE TABLE ${DatabaseTables.exercises} (
        ${DatabaseTables.exerciseId} TEXT PRIMARY KEY,
        ${DatabaseTables.exerciseName} TEXT NOT NULL UNIQUE,
        ${DatabaseTables.exerciseMuscleGroups} TEXT NOT NULL,
        ${DatabaseTables.exerciseCreatedAt} TEXT NOT NULL
      )
    ''');

    // Meals table
    await db.execute('''
      CREATE TABLE ${DatabaseTables.meals} (
        ${DatabaseTables.mealId} TEXT PRIMARY KEY,
        ${DatabaseTables.mealName} TEXT NOT NULL UNIQUE,
        ${DatabaseTables.mealCarbsPer100g} REAL NOT NULL,
        ${DatabaseTables.mealProteinPer100g} REAL NOT NULL,
        ${DatabaseTables.mealFatPer100g} REAL NOT NULL,
        ${DatabaseTables.mealCaloriesPer100g} REAL NOT NULL,
        ${DatabaseTables.mealCreatedAt} TEXT NOT NULL
      )
    ''');

    // Nutrition Logs table
    await db.execute('''
      CREATE TABLE ${DatabaseTables.nutritionLogs} (
        ${DatabaseTables.nutritionLogId} TEXT PRIMARY KEY,
        ${DatabaseTables.nutritionLogMealId} TEXT,
        ${DatabaseTables.nutritionLogGrams} REAL,
        ${DatabaseTables.nutritionLogCarbs} REAL NOT NULL,
        ${DatabaseTables.nutritionLogProtein} REAL NOT NULL,
        ${DatabaseTables.nutritionLogFat} REAL NOT NULL,
        ${DatabaseTables.nutritionLogCalories} REAL NOT NULL,
        ${DatabaseTables.nutritionLogDate} TEXT NOT NULL,
        ${DatabaseTables.nutritionLogCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DatabaseTables.nutritionLogMealId}) 
          REFERENCES ${DatabaseTables.meals}(${DatabaseTables.mealId})
          ON DELETE CASCADE
      )
    ''');

    // Exercise Muscle Factors table (NEW in v5)
    await db.execute('''
      CREATE TABLE ${DatabaseTables.exerciseMuscleFactor s} (
        ${DatabaseTables.factorId} TEXT PRIMARY KEY,
        ${DatabaseTables.factorExerciseId} TEXT NOT NULL,
        ${DatabaseTables.factorMuscleGroup} TEXT NOT NULL,
        ${DatabaseTables.factorValue} REAL NOT NULL,
        FOREIGN KEY (${DatabaseTables.factorExerciseId}) 
          REFERENCES ${DatabaseTables.exercises}(${DatabaseTables.exerciseId})
          ON DELETE CASCADE,
        UNIQUE(${DatabaseTables.factorExerciseId}, ${DatabaseTables.factorMuscleGroup})
      )
    ''');

    // Muscle Stimulus table (NEW in v5)
    await db.execute('''
      CREATE TABLE ${DatabaseTables.muscleStimulus} (
        ${DatabaseTables.stimulusId} TEXT PRIMARY KEY,
        ${DatabaseTables.stimulusMuscleGroup} TEXT NOT NULL,
        ${DatabaseTables.stimulusDate} TEXT NOT NULL,
        ${DatabaseTables.stimulusDailyStimulus} REAL NOT NULL DEFAULT 0.0,
        ${DatabaseTables.stimulusRollingWeeklyLoad} REAL NOT NULL DEFAULT 0.0,
        ${DatabaseTables.stimulusLastSetTimestamp} INTEGER,
        ${DatabaseTables.stimulusLastSetStimulus} REAL,
        ${DatabaseTables.stimulusCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.stimulusUpdatedAt} TEXT NOT NULL,
        UNIQUE(${DatabaseTables.stimulusMuscleGroup}, ${DatabaseTables.stimulusDate})
      )
    ''');

    // Create all indexes
    await _createIndexes(db);
  }

  /// Handle database version upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration from v1 to v2: Restructure workout_sets
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS ${DatabaseTables.workoutSets}');
      
      await db.execute('''
        CREATE TABLE ${DatabaseTables.workoutSets} (
          ${DatabaseTables.setId} TEXT PRIMARY KEY,
          ${DatabaseTables.setExerciseId} TEXT NOT NULL,
          ${DatabaseTables.setReps} INTEGER NOT NULL,
          ${DatabaseTables.setWeight} REAL NOT NULL,
          ${DatabaseTables.setDate} TEXT NOT NULL,
          ${DatabaseTables.setCreatedAt} TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_workout_sets_exercise_id 
        ON ${DatabaseTables.workoutSets}(${DatabaseTables.setExerciseId})
      ''');

      await db.execute('''
        CREATE INDEX idx_workout_sets_date 
        ON ${DatabaseTables.workoutSets}(${DatabaseTables.setDate})
      ''');
    }

    // Migration from v2 to v3: Add exercises table
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseTables.exercises} (
          ${DatabaseTables.exerciseId} TEXT PRIMARY KEY,
          ${DatabaseTables.exerciseName} TEXT NOT NULL UNIQUE,
          ${DatabaseTables.exerciseMuscleGroups} TEXT NOT NULL,
          ${DatabaseTables.exerciseCreatedAt} TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_exercises_name 
        ON ${DatabaseTables.exercises}(${DatabaseTables.exerciseName})
      ''');
    }

    // Migration from v3 to v4: Add nutrition tracking (meals + nutrition_logs)
    if (oldVersion < 4) {
      // Create meals table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseTables.meals} (
          ${DatabaseTables.mealId} TEXT PRIMARY KEY,
          ${DatabaseTables.mealName} TEXT NOT NULL UNIQUE,
          ${DatabaseTables.mealCarbsPer100g} REAL NOT NULL,
          ${DatabaseTables.mealProteinPer100g} REAL NOT NULL,
          ${DatabaseTables.mealFatPer100g} REAL NOT NULL,
          ${DatabaseTables.mealCaloriesPer100g} REAL NOT NULL,
          ${DatabaseTables.mealCreatedAt} TEXT NOT NULL
        )
      ''');

      // Create nutrition logs table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseTables.nutritionLogs} (
          ${DatabaseTables.nutritionLogId} TEXT PRIMARY KEY,
          ${DatabaseTables.nutritionLogMealId} TEXT,
          ${DatabaseTables.nutritionLogGrams} REAL,
          ${DatabaseTables.nutritionLogCarbs} REAL NOT NULL,
          ${DatabaseTables.nutritionLogProtein} REAL NOT NULL,
          ${DatabaseTables.nutritionLogFat} REAL NOT NULL,
          ${DatabaseTables.nutritionLogCalories} REAL NOT NULL,
          ${DatabaseTables.nutritionLogDate} TEXT NOT NULL,
          ${DatabaseTables.nutritionLogCreatedAt} TEXT NOT NULL,
          FOREIGN KEY (${DatabaseTables.nutritionLogMealId}) 
            REFERENCES ${DatabaseTables.meals}(${DatabaseTables.mealId})
            ON DELETE CASCADE
        )
      ''');

      // Create indexes for meals
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_meals_name 
        ON ${DatabaseTables.meals}(${DatabaseTables.mealName})
      ''');

      // Create indexes for nutrition logs
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_nutrition_logs_meal_id 
        ON ${DatabaseTables.nutritionLogs}(${DatabaseTables.nutritionLogMealId})
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_nutrition_logs_date 
        ON ${DatabaseTables.nutritionLogs}(${DatabaseTables.nutritionLogDate})
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_nutrition_logs_created_at 
        ON ${DatabaseTables.nutritionLogs}(${DatabaseTables.nutritionLogCreatedAt})
      ''');
    }

    // Migration from v4 to v5: Add muscle stimulus system
    if (oldVersion < 5) {
      // Add intensity column to workout_sets
      await db.execute('''
        ALTER TABLE ${DatabaseTables.workoutSets} 
        ADD COLUMN ${DatabaseTables.setIntensity} INTEGER NOT NULL 
        DEFAULT ${MuscleStimulus.defaultIntensity}
      ''');

      // Create exercise_muscle_factors table
      await db.execute('''
        CREATE TABLE ${DatabaseTables.exerciseMuscleFactor s} (
          ${DatabaseTables.factorId} TEXT PRIMARY KEY,
          ${DatabaseTables.factorExerciseId} TEXT NOT NULL,
          ${DatabaseTables.factorMuscleGroup} TEXT NOT NULL,
          ${DatabaseTables.factorValue} REAL NOT NULL,
          FOREIGN KEY (${DatabaseTables.factorExerciseId}) 
            REFERENCES ${DatabaseTables.exercises}(${DatabaseTables.exerciseId})
            ON DELETE CASCADE,
          UNIQUE(${DatabaseTables.factorExerciseId}, ${DatabaseTables.factorMuscleGroup})
        )
      ''');

      // Create muscle_stimulus table
      await db.execute('''
        CREATE TABLE ${DatabaseTables.muscleStimulus} (
          ${DatabaseTables.stimulusId} TEXT PRIMARY KEY,
          ${DatabaseTables.stimulusMuscleGroup} TEXT NOT NULL,
          ${DatabaseTables.stimulusDate} TEXT NOT NULL,
          ${DatabaseTables.stimulusDailyStimulus} REAL NOT NULL DEFAULT 0.0,
          ${DatabaseTables.stimulusRollingWeeklyLoad} REAL NOT NULL DEFAULT 0.0,
          ${DatabaseTables.stimulusLastSetTimestamp} INTEGER,
          ${DatabaseTables.stimulusLastSetStimulus} REAL,
          ${DatabaseTables.stimulusCreatedAt} TEXT NOT NULL,
          ${DatabaseTables.stimulusUpdatedAt} TEXT NOT NULL,
          UNIQUE(${DatabaseTables.stimulusMuscleGroup}, ${DatabaseTables.stimulusDate})
        )
      ''');

      // Create indexes for new tables
      await db.execute('''
        CREATE INDEX idx_exercise_muscle_factors_exercise_id 
        ON ${DatabaseTables.exerciseMuscleFactor s}(${DatabaseTables.factorExerciseId})
      ''');

      await db.execute('''
        CREATE INDEX idx_exercise_muscle_factors_muscle_group 
        ON ${DatabaseTables.exerciseMuscleFactor s}(${DatabaseTables.factorMuscleGroup})
      ''');

      await db.execute('''
        CREATE INDEX idx_muscle_stimulus_muscle_group 
        ON ${DatabaseTables.muscleStimulus}(${DatabaseTables.stimulusMuscleGroup})
      ''');

      await db.execute('''
        CREATE INDEX idx_muscle_stimulus_date 
        ON ${DatabaseTables.muscleStimulus}(${DatabaseTables.stimulusDate})
      ''');

      await db.execute('''
        CREATE INDEX idx_muscle_stimulus_muscle_date 
        ON ${DatabaseTables.muscleStimulus}(${DatabaseTables.stimulusMuscleGroup}, ${DatabaseTables.stimulusDate})
      ''');
    }
  }

  /// Create all performance indexes
  Future<void> _createIndexes(Database db) async {
    // Workout sets indexes
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_sets_exercise_id 
      ON ${DatabaseTables.workoutSets}(${DatabaseTables.setExerciseId})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_sets_date 
      ON ${DatabaseTables.workoutSets}(${DatabaseTables.setDate})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_sets_created_at 
      ON ${DatabaseTables.workoutSets}(${DatabaseTables.setCreatedAt})
    ''');

    // Exercises indexes
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_exercises_name 
      ON ${DatabaseTables.exercises}(${DatabaseTables.exerciseName})
    ''');

    // Meals indexes
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_meals_name 
      ON ${DatabaseTables.meals}(${DatabaseTables.mealName})
    ''');

    // Nutrition logs indexes
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_nutrition_logs_meal_id 
      ON ${DatabaseTables.nutritionLogs}(${DatabaseTables.nutritionLogMealId})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_nutrition_logs_date 
      ON ${DatabaseTables.nutritionLogs}(${DatabaseTables.nutritionLogDate})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_nutrition_logs_created_at 
      ON ${DatabaseTables.nutritionLogs}(${DatabaseTables.nutritionLogCreatedAt})
    ''');

    // Exercise muscle factors indexes
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_exercise_muscle_factors_exercise_id 
      ON ${DatabaseTables.exerciseMuscleFactor s}(${DatabaseTables.factorExerciseId})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_exercise_muscle_factors_muscle_group 
      ON ${DatabaseTables.exerciseMuscleFactor s}(${DatabaseTables.factorMuscleGroup})
    ''');

    // Muscle stimulus indexes
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_muscle_stimulus_muscle_group 
      ON ${DatabaseTables.muscleStimulus}(${DatabaseTables.stimulusMuscleGroup})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_muscle_stimulus_date 
      ON ${DatabaseTables.muscleStimulus}(${DatabaseTables.stimulusDate})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_muscle_stimulus_muscle_date 
      ON ${DatabaseTables.muscleStimulus}(${DatabaseTables.stimulusMuscleGroup}, ${DatabaseTables.stimulusDate})
    ''');
  }

  /// Close database connection
  /// WARNING: Should persist throughout app lifecycle for mobile
  /// Only close for testing or app termination
  Future<void> close() async {
    if (kIsWeb) return;
    
    final db = await database;
    await db.close();
    _database = null;
  }
}