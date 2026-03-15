import 'package:sqflite/sqflite.dart';

import '../../../core/constants/database_tables.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/exercise_model.dart';
import 'database_helper.dart';

abstract class ExerciseLocalDataSource {
  Future<List<ExerciseModel>> getAllExercises();
  Future<ExerciseModel?> getExerciseById(String id);
  Future<ExerciseModel?> getExerciseByName(String name);
  Future<List<ExerciseModel>> getExercisesForMuscle(String muscleGroup);
  Future<List<ExerciseModel>> getPendingSyncExercises();
  Future<void> insertExercise(ExerciseModel exercise);
  Future<void> updateExercise(ExerciseModel exercise);
  Future<void> markAsSynced({
    required String localId,
    required String serverId,
    required DateTime syncedAt,
  });
  Future<void> markAsPendingUpload(String localId, {String? errorMessage});
  Future<void> markAsPendingUpdate(String localId, {String? errorMessage});
  Future<void> replaceAllExercises(List<ExerciseModel> exercises);
  Future<void> deleteExercise(String id);
  Future<void> clearAllExercises();
}

class ExerciseLocalDataSourceImpl implements ExerciseLocalDataSource {
  final DatabaseHelper databaseHelper;

  const ExerciseLocalDataSourceImpl({
    required this.databaseHelper,
  });

  @override
  Future<List<ExerciseModel>> getAllExercises() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.exercises,
        orderBy: '${DatabaseTables.exerciseName} ASC',
      );
      return maps.map(ExerciseModel.fromMap).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get exercises: $e');
    }
  }

  @override
  Future<ExerciseModel?> getExerciseById(String id) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.exercises,
        where: '${DatabaseTables.exerciseId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return ExerciseModel.fromMap(maps.first);
    } catch (e) {
      throw CacheDatabaseException('Failed to get exercise: $e');
    }
  }

  @override
  Future<ExerciseModel?> getExerciseByName(String name) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.exercises,
        where: 'LOWER(${DatabaseTables.exerciseName}) = LOWER(?)',
        whereArgs: [name],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return ExerciseModel.fromMap(maps.first);
    } catch (e) {
      throw CacheDatabaseException('Failed to get exercise by name: $e');
    }
  }

  @override
  Future<List<ExerciseModel>> getExercisesForMuscle(String muscleGroup) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.exercises,
        where: '${DatabaseTables.exerciseMuscleGroups} LIKE ?',
        whereArgs: ['%"$muscleGroup"%'],
        orderBy: '${DatabaseTables.exerciseName} ASC',
      );
      return maps.map(ExerciseModel.fromMap).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get exercises for muscle: $e');
    }
  }

  @override
  Future<List<ExerciseModel>> getPendingSyncExercises() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.exercises,
        where:
            '${DatabaseTables.exerciseSyncStatus} = ? OR ${DatabaseTables.exerciseSyncStatus} = ?',
        whereArgs: const ['pendingUpload', 'pendingUpdate'],
        orderBy: '${DatabaseTables.exerciseUpdatedAt} ASC',
      );

      return maps.map(ExerciseModel.fromMap).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get pending sync exercises: $e');
    }
  }

  @override
  Future<void> insertExercise(ExerciseModel exercise) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseTables.exercises,
        exercise.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to insert exercise: $e');
    }
  }

  @override
  Future<void> updateExercise(ExerciseModel exercise) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseTables.exercises,
        exercise.toMap(),
        where: '${DatabaseTables.exerciseId} = ?',
        whereArgs: [exercise.id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to update exercise: $e');
    }
  }

  @override
  Future<void> markAsSynced({
    required String localId,
    required String serverId,
    required DateTime syncedAt,
  }) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseTables.exercises,
        <String, Object?>{
          DatabaseTables.exerciseServerId: serverId,
          DatabaseTables.exerciseSyncStatus: 'synced',
          DatabaseTables.exerciseLastSyncedAt: syncedAt.toIso8601String(),
          DatabaseTables.exerciseLastSyncError: null,
        },
        where: '${DatabaseTables.exerciseId} = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to mark exercise as synced: $e');
    }
  }

  @override
  Future<void> markAsPendingUpload(
    String localId, {
    String? errorMessage,
  }) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseTables.exercises,
        <String, Object?>{
          DatabaseTables.exerciseSyncStatus: 'pendingUpload',
          DatabaseTables.exerciseLastSyncError: errorMessage,
        },
        where: '${DatabaseTables.exerciseId} = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw CacheDatabaseException(
        'Failed to mark exercise as pending upload: $e',
      );
    }
  }

  @override
  Future<void> markAsPendingUpdate(
    String localId, {
    String? errorMessage,
  }) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseTables.exercises,
        <String, Object?>{
          DatabaseTables.exerciseSyncStatus: 'pendingUpdate',
          DatabaseTables.exerciseLastSyncError: errorMessage,
        },
        where: '${DatabaseTables.exerciseId} = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw CacheDatabaseException(
        'Failed to mark exercise as pending update: $e',
      );
    }
  }

  @override
  Future<void> replaceAllExercises(List<ExerciseModel> exercises) async {
    try {
      final db = await databaseHelper.database;

      await db.transaction((txn) async {
        await txn.delete(DatabaseTables.exercises);

        final batch = txn.batch();
        for (final exercise in exercises) {
          batch.insert(
            DatabaseTables.exercises,
            exercise.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      throw CacheDatabaseException('Failed to replace all exercises: $e');
    }
  }

  @override
  Future<void> deleteExercise(String id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        DatabaseTables.exercises,
        where: '${DatabaseTables.exerciseId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to delete exercise: $e');
    }
  }

  @override
  Future<void> clearAllExercises() async {
    try {
      final db = await databaseHelper.database;
      await db.delete(DatabaseTables.exercises);
    } catch (e) {
      throw CacheDatabaseException('Failed to clear exercises: $e');
    }
  }
}