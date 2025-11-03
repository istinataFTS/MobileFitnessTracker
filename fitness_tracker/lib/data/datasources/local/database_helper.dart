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
    // Return a dummy database on web
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
      version: 3, // Increment version to trigger migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create targets table
    await db.execute('''
      CREATE TABLE ${DatabaseTables.targets} (
        ${DatabaseTables.targetId} TEXT PRIMARY KEY,
        ${DatabaseTables.targetMuscleGroup} TEXT NOT NULL UNIQUE,
        ${DatabaseTables.targetWeeklyGoal} INTEGER NOT NULL,
        ${DatabaseTables.targetCreatedAt} TEXT NOT NULL
      )
    ''');

    // Create workout_sets table
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

    // Create exercises table
    await db.execute('''
      CREATE TABLE ${DatabaseTables.exercises} (
        ${DatabaseTables.exerciseId} TEXT PRIMARY KEY,
        ${DatabaseTables.exerciseName} TEXT NOT NULL UNIQUE,
        ${DatabaseTables.exerciseMuscleGroups} TEXT NOT NULL,
        ${DatabaseTables.exerciseCreatedAt} TEXT NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_workout_sets_exercise_id 
      ON ${DatabaseTables.workoutSets}(${DatabaseTables.setExerciseId})
    ''');

    await db.execute('''
      CREATE INDEX idx_workout_sets_date 
      ON ${DatabaseTables.workoutSets}(${DatabaseTables.setDate})
    ''');

    await db.execute('''
      CREATE INDEX idx_exercises_name 
      ON ${DatabaseTables.exercises}(${DatabaseTables.exerciseName})
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Migration logic for version 2
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

    if (oldVersion < 3) {
      // Migration logic for version 3 - add exercises table
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
  }

  Future<void> close() async {
    if (kIsWeb) return;
    
    final db = await database;
    await db.close();
    _database = null;
  }
}
