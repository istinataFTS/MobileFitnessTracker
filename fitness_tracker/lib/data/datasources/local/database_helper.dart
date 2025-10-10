import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../core/constants/database_tables.dart';
import '../../../config/app_config.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
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
    // Create targets table
    await db.execute('''
      CREATE TABLE ${DatabaseTables.targets} (
        ${DatabaseTables.targetId} TEXT PRIMARY KEY,
        ${DatabaseTables.targetMuscleGroup} TEXT NOT NULL UNIQUE,
        ${DatabaseTables.targetWeeklyGoal} INTEGER NOT NULL,
        ${DatabaseTables.targetCreatedAt} TEXT NOT NULL
      )
    ''');

    // Create workout_sets table with exerciseId instead of muscleGroup
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

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_workout_sets_exercise_id 
      ON ${DatabaseTables.workoutSets}(${DatabaseTables.setExerciseId})
    ''');

    await db.execute('''
      CREATE INDEX idx_workout_sets_date 
      ON ${DatabaseTables.workoutSets}(${DatabaseTables.setDate})
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Migration logic for version 2
      // Drop old table and recreate with new schema
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
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}