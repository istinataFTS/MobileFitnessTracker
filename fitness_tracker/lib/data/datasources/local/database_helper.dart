import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/constants/database_tables.dart';
import '../../../config/env_config.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Database is not supported on web');
    }
    
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Database is not supported on web');
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

    // Indexes for workout sets
    await db.execute('''
      CREATE INDEX idx_workout_sets_exercise_id 
      ON ${DatabaseTables.workoutSets}(${DatabaseTables.setExerciseId})
    ''');

    await db.execute('''
      CREATE INDEX idx_workout_sets_date 
      ON ${DatabaseTables.workoutSets}(${DatabaseTables.setDate})
    ''');

    // Indexes for exercises
    await db.execute('''
      CREATE INDEX idx_exercises_name 
      ON ${DatabaseTables.exercises}(${DatabaseTables.exerciseName})
    ''');

    // Indexes for meals
    await db.execute('''
      CREATE INDEX idx_meals_name 
      ON ${DatabaseTables.meals}(${DatabaseTables.mealName})
    ''');

    // Indexes for nutrition logs
    await db.execute('''
      CREATE INDEX idx_nutrition_logs_meal_id 
      ON ${DatabaseTables.nutritionLogs}(${DatabaseTables.nutritionLogMealId})
    ''');

    await db.execute('''
      CREATE INDEX idx_nutrition_logs_date 
      ON ${DatabaseTables.nutritionLogs}(${DatabaseTables.nutritionLogDate})
    ''');

    await db.execute('''
      CREATE INDEX idx_nutrition_logs_created_at 
      ON ${DatabaseTables.nutritionLogs}(${DatabaseTables.nutritionLogCreatedAt})
    ''');
  }

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
  }

  Future<void> close() async {
    if (kIsWeb) return;
    
    final db = await database;
    await db.close();
    _database = null;
  }
}