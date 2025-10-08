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

    // Create workout_sets table
    await db.execute('''
      CREATE TABLE ${DatabaseTables.workoutSets} (
        ${DatabaseTables.setId} TEXT PRIMARY KEY,
        ${DatabaseTables.setMuscleGroup} TEXT NOT NULL,
        ${DatabaseTables.setExerciseName} TEXT NOT NULL,
        ${DatabaseTables.setReps} INTEGER NOT NULL,
        ${DatabaseTables.setWeight} REAL NOT NULL,
        ${DatabaseTables.setDate} TEXT NOT NULL,
        ${DatabaseTables.setCreatedAt} TEXT NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_workout_sets_muscle_group 
      ON ${DatabaseTables.workoutSets}(${DatabaseTables.setMuscleGroup})
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
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}