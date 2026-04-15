import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../../config/env_config.dart';
import '../../../core/constants/database_tables.dart';
import '../../../core/constants/muscle_stimulus_constants.dart';

class UnsupportedDatabaseVersionException implements Exception {
  const UnsupportedDatabaseVersionException({
    required this.oldVersion,
    required this.newVersion,
    required this.minimumSupportedVersion,
  });

  final int oldVersion;
  final int newVersion;
  final int minimumSupportedVersion;

  @override
  String toString() {
    return 'UnsupportedDatabaseVersionException('
        'oldVersion: $oldVersion, '
        'newVersion: $newVersion, '
        'minimumSupportedVersion: $minimumSupportedVersion'
        ')';
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  static const int _minimumSupportedUpgradeVersion = 2;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Database is not supported on web platform');
    }

    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Database is not supported on web platform');
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, EnvConfig.databaseName);

    return openDatabase(
      path,
      version: EnvConfig.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DatabaseTables.targets} (
        ${DatabaseTables.targetId} TEXT PRIMARY KEY,
        ${DatabaseTables.ownerUserId} TEXT,
        ${DatabaseTables.targetType} TEXT NOT NULL,
        ${DatabaseTables.targetCategoryKey} TEXT NOT NULL,
        ${DatabaseTables.targetValue} REAL NOT NULL,
        ${DatabaseTables.targetUnit} TEXT NOT NULL,
        ${DatabaseTables.targetPeriod} TEXT NOT NULL,
        ${DatabaseTables.targetCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.targetUpdatedAt} TEXT NOT NULL,
        ${DatabaseTables.targetServerId} TEXT,
        ${DatabaseTables.targetSyncStatus} TEXT NOT NULL DEFAULT 'localOnly',
        ${DatabaseTables.targetLastSyncedAt} TEXT,
        ${DatabaseTables.targetLastSyncError} TEXT,
        UNIQUE(
          ${DatabaseTables.targetType},
          ${DatabaseTables.targetCategoryKey},
          ${DatabaseTables.targetPeriod}
        )
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseTables.workoutSets} (
        ${DatabaseTables.setId} TEXT PRIMARY KEY,
        ${DatabaseTables.ownerUserId} TEXT,
        ${DatabaseTables.setExerciseId} TEXT NOT NULL,
        ${DatabaseTables.setReps} INTEGER NOT NULL,
        ${DatabaseTables.setWeight} REAL NOT NULL,
        ${DatabaseTables.setIntensity} INTEGER NOT NULL DEFAULT ${MuscleStimulus.defaultIntensity},
        ${DatabaseTables.setDate} TEXT NOT NULL,
        ${DatabaseTables.setCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.setUpdatedAt} TEXT NOT NULL,
        ${DatabaseTables.setServerId} TEXT,
        ${DatabaseTables.setSyncStatus} TEXT NOT NULL DEFAULT 'localOnly',
        ${DatabaseTables.setLastSyncedAt} TEXT,
        ${DatabaseTables.setLastSyncError} TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseTables.exercises} (
        ${DatabaseTables.exerciseId} TEXT PRIMARY KEY,
        ${DatabaseTables.ownerUserId} TEXT,
        ${DatabaseTables.exerciseName} TEXT NOT NULL UNIQUE,
        ${DatabaseTables.exerciseMuscleGroups} TEXT NOT NULL,
        ${DatabaseTables.exerciseCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.exerciseUpdatedAt} TEXT NOT NULL,
        ${DatabaseTables.exerciseServerId} TEXT,
        ${DatabaseTables.exerciseSyncStatus} TEXT NOT NULL DEFAULT 'localOnly',
        ${DatabaseTables.exerciseLastSyncedAt} TEXT,
        ${DatabaseTables.exerciseLastSyncError} TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseTables.meals} (
        ${DatabaseTables.mealId} TEXT PRIMARY KEY,
        ${DatabaseTables.ownerUserId} TEXT,
        ${DatabaseTables.mealName} TEXT NOT NULL UNIQUE,
        ${DatabaseTables.mealServingSize} REAL NOT NULL DEFAULT 100.0,
        ${DatabaseTables.mealCarbsPer100g} REAL NOT NULL,
        ${DatabaseTables.mealProteinPer100g} REAL NOT NULL,
        ${DatabaseTables.mealFatPer100g} REAL NOT NULL,
        ${DatabaseTables.mealCaloriesPer100g} REAL NOT NULL,
        ${DatabaseTables.mealCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.mealUpdatedAt} TEXT NOT NULL,
        ${DatabaseTables.mealServerId} TEXT,
        ${DatabaseTables.mealSyncStatus} TEXT NOT NULL DEFAULT 'localOnly',
        ${DatabaseTables.mealLastSyncedAt} TEXT,
        ${DatabaseTables.mealLastSyncError} TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseTables.nutritionLogs} (
        ${DatabaseTables.nutritionLogId} TEXT PRIMARY KEY,
        ${DatabaseTables.ownerUserId} TEXT,
        ${DatabaseTables.nutritionLogMealId} TEXT,
        ${DatabaseTables.nutritionLogMealName} TEXT NOT NULL DEFAULT '',
        ${DatabaseTables.nutritionLogGrams} REAL,
        ${DatabaseTables.nutritionLogCarbs} REAL NOT NULL,
        ${DatabaseTables.nutritionLogProtein} REAL NOT NULL,
        ${DatabaseTables.nutritionLogFat} REAL NOT NULL,
        ${DatabaseTables.nutritionLogCalories} REAL NOT NULL,
        ${DatabaseTables.nutritionLogDate} TEXT NOT NULL,
        ${DatabaseTables.nutritionLogCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.nutritionLogUpdatedAt} TEXT NOT NULL,
        ${DatabaseTables.nutritionLogServerId} TEXT,
        ${DatabaseTables.nutritionLogSyncStatus} TEXT NOT NULL DEFAULT 'localOnly',
        ${DatabaseTables.nutritionLogLastSyncedAt} TEXT,
        ${DatabaseTables.nutritionLogLastSyncError} TEXT,
        FOREIGN KEY (${DatabaseTables.nutritionLogMealId})
          REFERENCES ${DatabaseTables.meals}(${DatabaseTables.mealId})
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseTables.exerciseMuscleFactors} (
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

    await db.execute('''
      CREATE TABLE ${DatabaseTables.muscleStimulus} (
        ${DatabaseTables.stimulusId} TEXT PRIMARY KEY,
        ${DatabaseTables.ownerUserId} TEXT NOT NULL DEFAULT '',
        ${DatabaseTables.stimulusMuscleGroup} TEXT NOT NULL,
        ${DatabaseTables.stimulusDate} TEXT NOT NULL,
        ${DatabaseTables.stimulusDailyStimulus} REAL NOT NULL DEFAULT 0.0,
        ${DatabaseTables.stimulusRollingWeeklyLoad} REAL NOT NULL DEFAULT 0.0,
        ${DatabaseTables.stimulusLastSetTimestamp} INTEGER,
        ${DatabaseTables.stimulusLastSetStimulus} REAL,
        ${DatabaseTables.stimulusCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.stimulusUpdatedAt} TEXT NOT NULL,
        UNIQUE(${DatabaseTables.ownerUserId}, ${DatabaseTables.stimulusMuscleGroup}, ${DatabaseTables.stimulusDate})
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseTables.pendingSyncDeletes} (
        ${DatabaseTables.pendingDeleteId} TEXT PRIMARY KEY,
        ${DatabaseTables.pendingDeleteEntityType} TEXT NOT NULL,
        ${DatabaseTables.pendingDeleteLocalEntityId} TEXT NOT NULL,
        ${DatabaseTables.pendingDeleteServerEntityId} TEXT,
        ${DatabaseTables.pendingDeleteCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.pendingDeleteLastAttemptAt} TEXT,
        ${DatabaseTables.pendingDeleteErrorMessage} TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DatabaseTables.appMetadata} (
        ${DatabaseTables.metadataKey} TEXT PRIMARY KEY,
        ${DatabaseTables.metadataValue} TEXT,
        ${DatabaseTables.metadataUpdatedAt} TEXT NOT NULL
      )
    ''');

    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _ensureSupportedUpgradePath(oldVersion, newVersion);

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

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseTables.meals} (
          ${DatabaseTables.mealId} TEXT PRIMARY KEY,
          ${DatabaseTables.mealName} TEXT NOT NULL UNIQUE,
          ${DatabaseTables.mealServingSize} REAL NOT NULL DEFAULT 100.0,
          ${DatabaseTables.mealCarbsPer100g} REAL NOT NULL,
          ${DatabaseTables.mealProteinPer100g} REAL NOT NULL,
          ${DatabaseTables.mealFatPer100g} REAL NOT NULL,
          ${DatabaseTables.mealCaloriesPer100g} REAL NOT NULL,
          ${DatabaseTables.mealCreatedAt} TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseTables.nutritionLogs} (
          ${DatabaseTables.nutritionLogId} TEXT PRIMARY KEY,
          ${DatabaseTables.nutritionLogMealId} TEXT,
          ${DatabaseTables.nutritionLogMealName} TEXT NOT NULL DEFAULT '',
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

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_meals_name
        ON ${DatabaseTables.meals}(${DatabaseTables.mealName})
      ''');

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

    if (oldVersion < 5) {
      await db.execute('''
        ALTER TABLE ${DatabaseTables.workoutSets}
        ADD COLUMN ${DatabaseTables.setIntensity} INTEGER NOT NULL
        DEFAULT ${MuscleStimulus.defaultIntensity}
      ''');

      await db.execute('''
        CREATE TABLE ${DatabaseTables.exerciseMuscleFactors} (
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

      await db.execute('''
        CREATE INDEX idx_exercise_muscle_factors_exercise_id
        ON ${DatabaseTables.exerciseMuscleFactors}(${DatabaseTables.factorExerciseId})
      ''');

      await db.execute('''
        CREATE INDEX idx_exercise_muscle_factors_muscle_group
        ON ${DatabaseTables.exerciseMuscleFactors}(${DatabaseTables.factorMuscleGroup})
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
        ON ${DatabaseTables.muscleStimulus}(
          ${DatabaseTables.stimulusMuscleGroup},
          ${DatabaseTables.stimulusDate}
        )
      ''');
    }

    if (oldVersion < 6) {
      await db.execute('''
        ALTER TABLE ${DatabaseTables.nutritionLogs}
        ADD COLUMN ${DatabaseTables.nutritionLogMealName} TEXT NOT NULL DEFAULT ''
      ''');
    }

    if (oldVersion < 7) {
      await db.execute('''
        ALTER TABLE ${DatabaseTables.meals}
        ADD COLUMN ${DatabaseTables.mealServingSize} REAL NOT NULL DEFAULT 100.0
      ''');
    }

    if (oldVersion < 8) {
      await _migrateTargetsToTypedGoals(db);
    }

    if (oldVersion < 9) {
      await _migrateWorkoutSetsForRemoteReadiness(db);
    }

    if (oldVersion < 10) {
      await _createPendingSyncDeletesTable(db);
    }

    if (oldVersion < 11) {
      await _migrateTargetsForRemoteReadiness(db);
    }

    if (oldVersion < 12) {
      await _migrateExercisesForRemoteReadiness(db);
    }

    if (oldVersion < 13) {
      await _migrateMealsAndNutritionLogsForRemoteReadiness(db);
    }

    if (oldVersion < 14) {
      await _createAppMetadataTable(db);
    }

    if (oldVersion < 15) {
      await _migrateOwnershipColumns(db);
    }

    if (oldVersion < 16) {
      // Clear stale muscle factor and stimulus data so the seeder re-runs
      // with the corrected exercise name mappings from exercise_muscle_factors_data.dart.
      // muscle_stimulus will be rebuilt from workout history by AppDataSeeder after reseeding.
      await db.delete(DatabaseTables.exerciseMuscleFactors);
      await db.delete(DatabaseTables.muscleStimulus);
    }

    if (oldVersion < 17) {
      // Add owner_user_id to muscle_stimulus and update the unique constraint
      // from (muscle_group, date) to (owner_user_id, muscle_group, date).
      // SQLite does not support DROP CONSTRAINT, so the table must be recreated.
      await db.execute('''
        CREATE TABLE muscle_stimulus_v17 (
          ${DatabaseTables.stimulusId} TEXT PRIMARY KEY,
          ${DatabaseTables.ownerUserId} TEXT NOT NULL DEFAULT '',
          ${DatabaseTables.stimulusMuscleGroup} TEXT NOT NULL,
          ${DatabaseTables.stimulusDate} TEXT NOT NULL,
          ${DatabaseTables.stimulusDailyStimulus} REAL NOT NULL DEFAULT 0.0,
          ${DatabaseTables.stimulusRollingWeeklyLoad} REAL NOT NULL DEFAULT 0.0,
          ${DatabaseTables.stimulusLastSetTimestamp} INTEGER,
          ${DatabaseTables.stimulusLastSetStimulus} REAL,
          ${DatabaseTables.stimulusCreatedAt} TEXT NOT NULL,
          ${DatabaseTables.stimulusUpdatedAt} TEXT NOT NULL,
          UNIQUE(${DatabaseTables.ownerUserId}, ${DatabaseTables.stimulusMuscleGroup}, ${DatabaseTables.stimulusDate})
        )
      ''');

      // Copy existing rows; pre-auth records receive owner_user_id = ''
      // so they remain accessible to the guest/unauthenticated state.
      await db.execute('''
        INSERT INTO muscle_stimulus_v17 (
          ${DatabaseTables.stimulusId},
          ${DatabaseTables.ownerUserId},
          ${DatabaseTables.stimulusMuscleGroup},
          ${DatabaseTables.stimulusDate},
          ${DatabaseTables.stimulusDailyStimulus},
          ${DatabaseTables.stimulusRollingWeeklyLoad},
          ${DatabaseTables.stimulusLastSetTimestamp},
          ${DatabaseTables.stimulusLastSetStimulus},
          ${DatabaseTables.stimulusCreatedAt},
          ${DatabaseTables.stimulusUpdatedAt}
        )
        SELECT
          ${DatabaseTables.stimulusId},
          '',
          ${DatabaseTables.stimulusMuscleGroup},
          ${DatabaseTables.stimulusDate},
          ${DatabaseTables.stimulusDailyStimulus},
          ${DatabaseTables.stimulusRollingWeeklyLoad},
          ${DatabaseTables.stimulusLastSetTimestamp},
          ${DatabaseTables.stimulusLastSetStimulus},
          ${DatabaseTables.stimulusCreatedAt},
          ${DatabaseTables.stimulusUpdatedAt}
        FROM ${DatabaseTables.muscleStimulus}
      ''');

      await db.execute('DROP TABLE ${DatabaseTables.muscleStimulus}');
      await db.execute(
        'ALTER TABLE muscle_stimulus_v17 RENAME TO ${DatabaseTables.muscleStimulus}',
      );
    }

    await _createIndexes(db);
  }

  void _ensureSupportedUpgradePath(int oldVersion, int newVersion) {
    if (oldVersion >= _minimumSupportedUpgradeVersion) {
      return;
    }

    throw UnsupportedDatabaseVersionException(
      oldVersion: oldVersion,
      newVersion: newVersion,
      minimumSupportedVersion: _minimumSupportedUpgradeVersion,
    );
  }

  Future<void> _migrateTargetsToTypedGoals(Database db) async {
    await db.execute(
      'ALTER TABLE ${DatabaseTables.targets} RENAME TO targets_legacy',
    );

    await db.execute('''
      CREATE TABLE ${DatabaseTables.targets} (
        ${DatabaseTables.targetId} TEXT PRIMARY KEY,
        ${DatabaseTables.ownerUserId} TEXT,
        ${DatabaseTables.targetType} TEXT NOT NULL,
        ${DatabaseTables.targetCategoryKey} TEXT NOT NULL,
        ${DatabaseTables.targetValue} REAL NOT NULL,
        ${DatabaseTables.targetUnit} TEXT NOT NULL,
        ${DatabaseTables.targetPeriod} TEXT NOT NULL,
        ${DatabaseTables.targetCreatedAt} TEXT NOT NULL,
        UNIQUE(
          ${DatabaseTables.targetType},
          ${DatabaseTables.targetCategoryKey},
          ${DatabaseTables.targetPeriod}
        )
      )
    ''');

    final legacyTargets = await db.query('targets_legacy');

    for (final legacyTarget in legacyTargets) {
      await db.insert(
        DatabaseTables.targets,
        <String, Object?>{
          DatabaseTables.targetId:
              legacyTarget[DatabaseTables.targetId] as String,
          DatabaseTables.ownerUserId: null,
          DatabaseTables.targetType: 'muscle_sets',
          DatabaseTables.targetCategoryKey:
              legacyTarget[DatabaseTables.legacyTargetMuscleGroup] as String,
          DatabaseTables.targetValue:
              (legacyTarget[DatabaseTables.legacyTargetWeeklyGoal] as num)
                  .toDouble(),
          DatabaseTables.targetUnit: 'sets',
          DatabaseTables.targetPeriod: 'weekly',
          DatabaseTables.targetCreatedAt:
              legacyTarget[DatabaseTables.targetCreatedAt] as String,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await db.execute('DROP TABLE targets_legacy');
  }

  Future<void> _migrateWorkoutSetsForRemoteReadiness(Database db) async {
    await db.execute('''
      ALTER TABLE ${DatabaseTables.workoutSets}
      ADD COLUMN ${DatabaseTables.setUpdatedAt} TEXT
    ''');

    await db.execute('''
      UPDATE ${DatabaseTables.workoutSets}
      SET ${DatabaseTables.setUpdatedAt} = ${DatabaseTables.setCreatedAt}
      WHERE ${DatabaseTables.setUpdatedAt} IS NULL
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.workoutSets}
      ADD COLUMN ${DatabaseTables.setServerId} TEXT
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.workoutSets}
      ADD COLUMN ${DatabaseTables.setSyncStatus} TEXT NOT NULL DEFAULT 'localOnly'
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.workoutSets}
      ADD COLUMN ${DatabaseTables.setLastSyncedAt} TEXT
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.workoutSets}
      ADD COLUMN ${DatabaseTables.setLastSyncError} TEXT
    ''');
  }

  Future<void> _createPendingSyncDeletesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.pendingSyncDeletes} (
        ${DatabaseTables.pendingDeleteId} TEXT PRIMARY KEY,
        ${DatabaseTables.pendingDeleteEntityType} TEXT NOT NULL,
        ${DatabaseTables.pendingDeleteLocalEntityId} TEXT NOT NULL,
        ${DatabaseTables.pendingDeleteServerEntityId} TEXT,
        ${DatabaseTables.pendingDeleteCreatedAt} TEXT NOT NULL,
        ${DatabaseTables.pendingDeleteLastAttemptAt} TEXT,
        ${DatabaseTables.pendingDeleteErrorMessage} TEXT
      )
    ''');
  }

  Future<void> _migrateTargetsForRemoteReadiness(Database db) async {
    await db.execute('''
      ALTER TABLE ${DatabaseTables.targets}
      ADD COLUMN ${DatabaseTables.targetUpdatedAt} TEXT
    ''');

    await db.execute('''
      UPDATE ${DatabaseTables.targets}
      SET ${DatabaseTables.targetUpdatedAt} = ${DatabaseTables.targetCreatedAt}
      WHERE ${DatabaseTables.targetUpdatedAt} IS NULL
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.targets}
      ADD COLUMN ${DatabaseTables.targetServerId} TEXT
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.targets}
      ADD COLUMN ${DatabaseTables.targetSyncStatus} TEXT NOT NULL DEFAULT 'localOnly'
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.targets}
      ADD COLUMN ${DatabaseTables.targetLastSyncedAt} TEXT
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.targets}
      ADD COLUMN ${DatabaseTables.targetLastSyncError} TEXT
    ''');
  }

  Future<void> _migrateExercisesForRemoteReadiness(Database db) async {
    await db.execute('''
      ALTER TABLE ${DatabaseTables.exercises}
      ADD COLUMN ${DatabaseTables.exerciseUpdatedAt} TEXT
    ''');

    await db.execute('''
      UPDATE ${DatabaseTables.exercises}
      SET ${DatabaseTables.exerciseUpdatedAt} = ${DatabaseTables.exerciseCreatedAt}
      WHERE ${DatabaseTables.exerciseUpdatedAt} IS NULL
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.exercises}
      ADD COLUMN ${DatabaseTables.exerciseServerId} TEXT
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.exercises}
      ADD COLUMN ${DatabaseTables.exerciseSyncStatus} TEXT NOT NULL DEFAULT 'localOnly'
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.exercises}
      ADD COLUMN ${DatabaseTables.exerciseLastSyncedAt} TEXT
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.exercises}
      ADD COLUMN ${DatabaseTables.exerciseLastSyncError} TEXT
    ''');
  }

  Future<void> _migrateMealsAndNutritionLogsForRemoteReadiness(
    Database db,
  ) async {
    await db.execute('''
      ALTER TABLE ${DatabaseTables.meals}
      ADD COLUMN ${DatabaseTables.mealUpdatedAt} TEXT
    ''');

    await db.execute('''
      UPDATE ${DatabaseTables.meals}
      SET ${DatabaseTables.mealUpdatedAt} = ${DatabaseTables.mealCreatedAt}
      WHERE ${DatabaseTables.mealUpdatedAt} IS NULL
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.meals}
      ADD COLUMN ${DatabaseTables.mealServerId} TEXT
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.meals}
      ADD COLUMN ${DatabaseTables.mealSyncStatus} TEXT NOT NULL DEFAULT 'localOnly'
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.meals}
      ADD COLUMN ${DatabaseTables.mealLastSyncedAt} TEXT
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.meals}
      ADD COLUMN ${DatabaseTables.mealLastSyncError} TEXT
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.nutritionLogs}
      ADD COLUMN ${DatabaseTables.nutritionLogUpdatedAt} TEXT
    ''');

    await db.execute('''
      UPDATE ${DatabaseTables.nutritionLogs}
      SET ${DatabaseTables.nutritionLogUpdatedAt} = ${DatabaseTables.nutritionLogCreatedAt}
      WHERE ${DatabaseTables.nutritionLogUpdatedAt} IS NULL
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.nutritionLogs}
      ADD COLUMN ${DatabaseTables.nutritionLogServerId} TEXT
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.nutritionLogs}
      ADD COLUMN ${DatabaseTables.nutritionLogSyncStatus} TEXT NOT NULL DEFAULT 'localOnly'
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.nutritionLogs}
      ADD COLUMN ${DatabaseTables.nutritionLogLastSyncedAt} TEXT
    ''');

    await db.execute('''
      ALTER TABLE ${DatabaseTables.nutritionLogs}
      ADD COLUMN ${DatabaseTables.nutritionLogLastSyncError} TEXT
    ''');
  }

  Future<void> _createAppMetadataTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.appMetadata} (
        ${DatabaseTables.metadataKey} TEXT PRIMARY KEY,
        ${DatabaseTables.metadataValue} TEXT,
        ${DatabaseTables.metadataUpdatedAt} TEXT NOT NULL
      )
    ''');
  }

  Future<void> _migrateOwnershipColumns(Database db) async {
    await _addNullableTextColumnIfMissing(
      db,
      tableName: DatabaseTables.targets,
      columnName: DatabaseTables.ownerUserId,
    );
    await _addNullableTextColumnIfMissing(
      db,
      tableName: DatabaseTables.workoutSets,
      columnName: DatabaseTables.ownerUserId,
    );
    await _addNullableTextColumnIfMissing(
      db,
      tableName: DatabaseTables.exercises,
      columnName: DatabaseTables.ownerUserId,
    );
    await _addNullableTextColumnIfMissing(
      db,
      tableName: DatabaseTables.meals,
      columnName: DatabaseTables.ownerUserId,
    );
    await _addNullableTextColumnIfMissing(
      db,
      tableName: DatabaseTables.nutritionLogs,
      columnName: DatabaseTables.ownerUserId,
    );
  }

  Future<void> _addNullableTextColumnIfMissing(
    Database db, {
    required String tableName,
    required String columnName,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final exists = columns.any(
      (row) => row['name'] == columnName,
    );

    if (exists) {
      return;
    }

    await db.execute(
      'ALTER TABLE $tableName ADD COLUMN $columnName TEXT',
    );
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_targets_type_period
      ON ${DatabaseTables.targets}(
        ${DatabaseTables.targetType},
        ${DatabaseTables.targetPeriod}
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_targets_category_key
      ON ${DatabaseTables.targets}(${DatabaseTables.targetCategoryKey})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_targets_updated_at
      ON ${DatabaseTables.targets}(${DatabaseTables.targetUpdatedAt})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_targets_sync_status
      ON ${DatabaseTables.targets}(${DatabaseTables.targetSyncStatus})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_targets_server_id
      ON ${DatabaseTables.targets}(${DatabaseTables.targetServerId})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_targets_owner_user_id
      ON ${DatabaseTables.targets}(${DatabaseTables.ownerUserId})
    ''');

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

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_sets_updated_at
      ON ${DatabaseTables.workoutSets}(${DatabaseTables.setUpdatedAt})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_sets_sync_status
      ON ${DatabaseTables.workoutSets}(${DatabaseTables.setSyncStatus})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_sets_server_id
      ON ${DatabaseTables.workoutSets}(${DatabaseTables.setServerId})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_sets_owner_user_id
      ON ${DatabaseTables.workoutSets}(${DatabaseTables.ownerUserId})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_exercises_name
      ON ${DatabaseTables.exercises}(${DatabaseTables.exerciseName})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_exercises_updated_at
      ON ${DatabaseTables.exercises}(${DatabaseTables.exerciseUpdatedAt})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_exercises_sync_status
      ON ${DatabaseTables.exercises}(${DatabaseTables.exerciseSyncStatus})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_exercises_server_id
      ON ${DatabaseTables.exercises}(${DatabaseTables.exerciseServerId})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_exercises_owner_user_id
      ON ${DatabaseTables.exercises}(${DatabaseTables.ownerUserId})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_meals_name
      ON ${DatabaseTables.meals}(${DatabaseTables.mealName})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_meals_updated_at
      ON ${DatabaseTables.meals}(${DatabaseTables.mealUpdatedAt})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_meals_sync_status
      ON ${DatabaseTables.meals}(${DatabaseTables.mealSyncStatus})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_meals_server_id
      ON ${DatabaseTables.meals}(${DatabaseTables.mealServerId})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_meals_owner_user_id
      ON ${DatabaseTables.meals}(${DatabaseTables.ownerUserId})
    ''');

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

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_nutrition_logs_updated_at
      ON ${DatabaseTables.nutritionLogs}(${DatabaseTables.nutritionLogUpdatedAt})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_nutrition_logs_sync_status
      ON ${DatabaseTables.nutritionLogs}(${DatabaseTables.nutritionLogSyncStatus})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_nutrition_logs_server_id
      ON ${DatabaseTables.nutritionLogs}(${DatabaseTables.nutritionLogServerId})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_nutrition_logs_owner_user_id
      ON ${DatabaseTables.nutritionLogs}(${DatabaseTables.ownerUserId})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_exercise_muscle_factors_exercise_id
      ON ${DatabaseTables.exerciseMuscleFactors}(${DatabaseTables.factorExerciseId})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_exercise_muscle_factors_muscle_group
      ON ${DatabaseTables.exerciseMuscleFactors}(${DatabaseTables.factorMuscleGroup})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_muscle_stimulus_owner_user_id
      ON ${DatabaseTables.muscleStimulus}(${DatabaseTables.ownerUserId})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_muscle_stimulus_muscle_group
      ON ${DatabaseTables.muscleStimulus}(${DatabaseTables.stimulusMuscleGroup})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_muscle_stimulus_date
      ON ${DatabaseTables.muscleStimulus}(${DatabaseTables.stimulusDate})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_muscle_stimulus_owner_muscle_date
      ON ${DatabaseTables.muscleStimulus}(
        ${DatabaseTables.ownerUserId},
        ${DatabaseTables.stimulusMuscleGroup},
        ${DatabaseTables.stimulusDate}
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_pending_sync_deletes_entity_type
      ON ${DatabaseTables.pendingSyncDeletes}(${DatabaseTables.pendingDeleteEntityType})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_pending_sync_deletes_created_at
      ON ${DatabaseTables.pendingSyncDeletes}(${DatabaseTables.pendingDeleteCreatedAt})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_pending_sync_deletes_local_entity_id
      ON ${DatabaseTables.pendingSyncDeletes}(${DatabaseTables.pendingDeleteLocalEntityId})
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_app_metadata_updated_at
      ON ${DatabaseTables.appMetadata}(${DatabaseTables.metadataUpdatedAt})
    ''');
  }

  Future<void> close() async {
    if (kIsWeb) return;

    final db = await database;
    await db.close();
    _database = null;
  }
}