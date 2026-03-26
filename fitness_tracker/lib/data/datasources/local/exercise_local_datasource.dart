import 'package:sqflite/sqflite.dart';

import '../../../core/constants/database_tables.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/enums/sync_status.dart';
import '../../../core/sync/local_remote_merge.dart';
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
  Future<void> upsertExercise(ExerciseModel exercise);
  Future<void> prepareForInitialCloudMigration({
    required String userId,
  });
  Future<void> mergeRemoteExercises(List<ExerciseModel> exercises);
  Future<void> markAsSynced({
    required String localId,
    required String serverId,
    required DateTime syncedAt,
  });
  Future<void> markAsPendingUpload(String localId, {String? errorMessage});
  Future<void> markAsPendingUpdate(String localId, {String? errorMessage});
  Future<void> markAsPendingDelete(String localId, {String? errorMessage});
  Future<void> replaceAllExercises(List<ExerciseModel> exercises);
  Future<void> deleteExercise(String id);
  Future<void> clearAllExercises();
}

class ExerciseLocalDataSourceImpl implements ExerciseLocalDataSource {
  final DatabaseHelper databaseHelper;

  static final LocalRemoteMerge<ExerciseModel> _merge =
      LocalRemoteMerge<ExerciseModel>(
        getId: (exercise) => exercise.id,
        getUpdatedAt: (exercise) => exercise.updatedAt,
        getSyncMetadata: (exercise) => exercise.syncMetadata,
      );

  const ExerciseLocalDataSourceImpl({
    required this.databaseHelper,
  });

  @override
  Future<List<ExerciseModel>> getAllExercises() async {
    try {
      return await _getVisibleExercises();
    } catch (e) {
      throw CacheDatabaseException('Failed to get exercises: $e');
    }
  }

  @override
  Future<ExerciseModel?> getExerciseById(String id) async {
    try {
      return await _getVisibleExerciseById(id);
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
        where:
            'LOWER(${DatabaseTables.exerciseName}) = LOWER(?) AND '
            '(${DatabaseTables.exerciseSyncStatus} IS NULL OR '
            '${DatabaseTables.exerciseSyncStatus} != ?)',
        whereArgs: [name, SyncStatus.pendingDelete.name],
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
        where:
            '${DatabaseTables.exerciseMuscleGroups} LIKE ? AND '
            '(${DatabaseTables.exerciseSyncStatus} IS NULL OR '
            '${DatabaseTables.exerciseSyncStatus} != ?)',
        whereArgs: ['%"$muscleGroup"%', SyncStatus.pendingDelete.name],
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
            '${DatabaseTables.exerciseSyncStatus} = ? OR '
            '${DatabaseTables.exerciseSyncStatus} = ?',
        whereArgs: [
          SyncStatus.pendingUpload.name,
          SyncStatus.pendingUpdate.name,
        ],
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
  Future<void> upsertExercise(ExerciseModel exercise) async {
    final existing = await _getStoredExerciseById(exercise.id);
    if (existing == null) {
      await insertExercise(exercise);
      return;
    }

    if (existing.syncMetadata.isPendingDelete &&
        !exercise.syncMetadata.isPendingDelete) {
      return;
    }

    await updateExercise(exercise);
  }

  @override
  Future<void> prepareForInitialCloudMigration({
    required String userId,
  }) async {
    try {
      final storedExercises = await _getStoredExercises();
      final preparedExercises = storedExercises
          .map(
            (exercise) =>
                _prepareExerciseForInitialCloudMigration(exercise, userId),
          )
          .toList();

      await _replaceStoredExercises(preparedExercises);
    } catch (e) {
      throw CacheDatabaseException(
        'Failed to prepare exercises for initial cloud migration: $e',
      );
    }
  }

  @override
  Future<void> mergeRemoteExercises(List<ExerciseModel> exercises) async {
    try {
      final storedLocalExercises = await _getStoredExercises();
      final mergedVisibleExercises = _merge.mergeLists(
        localItems: storedLocalExercises,
        remoteItems: exercises,
      );

      final Map<String, ExerciseModel> mergedById = <String, ExerciseModel>{
        for (final exercise in mergedVisibleExercises) exercise.id: exercise,
      };

      for (final localExercise in storedLocalExercises) {
        if (localExercise.syncMetadata.isPendingDelete) {
          mergedById.putIfAbsent(localExercise.id, () => localExercise);
        }
      }

      await _replaceStoredExercises(mergedById.values.toList());
    } catch (e) {
      throw CacheDatabaseException('Failed to merge remote exercises: $e');
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
          DatabaseTables.exerciseSyncStatus: SyncStatus.synced.name,
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
          DatabaseTables.exerciseSyncStatus: SyncStatus.pendingUpload.name,
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
          DatabaseTables.exerciseSyncStatus: SyncStatus.pendingUpdate.name,
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
  Future<void> markAsPendingDelete(
    String localId, {
    String? errorMessage,
  }) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseTables.exercises,
        <String, Object?>{
          DatabaseTables.exerciseSyncStatus: SyncStatus.pendingDelete.name,
          DatabaseTables.exerciseLastSyncError: errorMessage,
        },
        where: '${DatabaseTables.exerciseId} = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw CacheDatabaseException(
        'Failed to mark exercise as pending delete: $e',
      );
    }
  }

  @override
  Future<void> replaceAllExercises(List<ExerciseModel> exercises) async {
    try {
      await _replaceStoredExercises(exercises);
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

  Future<List<ExerciseModel>> _getVisibleExercises() async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseTables.exercises,
      where:
          '${DatabaseTables.exerciseSyncStatus} IS NULL OR '
          '${DatabaseTables.exerciseSyncStatus} != ?',
      whereArgs: <Object?>[SyncStatus.pendingDelete.name],
      orderBy: '${DatabaseTables.exerciseName} ASC',
    );
    return maps.map(ExerciseModel.fromMap).toList();
  }

  Future<ExerciseModel?> _getVisibleExerciseById(String id) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseTables.exercises,
      where:
          '${DatabaseTables.exerciseId} = ? AND '
          '(${DatabaseTables.exerciseSyncStatus} IS NULL OR '
          '${DatabaseTables.exerciseSyncStatus} != ?)',
      whereArgs: <Object?>[id, SyncStatus.pendingDelete.name],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return ExerciseModel.fromMap(maps.first);
  }

  Future<List<ExerciseModel>> _getStoredExercises() async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseTables.exercises,
      orderBy: '${DatabaseTables.exerciseName} ASC',
    );
    return maps.map(ExerciseModel.fromMap).toList();
  }

  Future<ExerciseModel?> _getStoredExerciseById(String id) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseTables.exercises,
      where: '${DatabaseTables.exerciseId} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return ExerciseModel.fromMap(maps.first);
  }

  Future<void> _replaceStoredExercises(List<ExerciseModel> exercises) async {
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
  }

  ExerciseModel _prepareExerciseForInitialCloudMigration(
    ExerciseModel exercise,
    String userId,
  ) {
    final ownerUserId = exercise.ownerUserId;
    if (ownerUserId != null && ownerUserId.isNotEmpty && ownerUserId != userId) {
      return exercise;
    }

    final currentMetadata = exercise.syncMetadata;
    final updatedMetadata = switch (currentMetadata.status) {
      SyncStatus.localOnly => currentMetadata.copyWith(
          status: SyncStatus.pendingUpload,
          clearLastSyncError: true,
        ),
      SyncStatus.pendingUpload => currentMetadata.copyWith(
          clearLastSyncError: true,
        ),
      SyncStatus.pendingUpdate ||
      SyncStatus.synced ||
      SyncStatus.pendingDelete => currentMetadata,
    };

    return ExerciseModel.fromEntity(
      exercise.copyWith(
        ownerUserId:
            ownerUserId == null || ownerUserId.isEmpty ? userId : null,
        syncMetadata: updatedMetadata,
      ),
    );
  }
}
