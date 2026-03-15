import '../../../core/constants/database_tables.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/workout_set_model.dart';
import '../../../domain/entities/workout_set.dart';
import 'database_helper.dart';
import 'workout_set_local_datasource.dart';

class WorkoutSetLocalDataSourceImpl implements WorkoutSetLocalDataSource {
  final DatabaseHelper databaseHelper;

  WorkoutSetLocalDataSourceImpl({
    required this.databaseHelper,
  });

  @override
  Future<List<WorkoutSet>> getAllSets() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.workoutSets,
        orderBy:
            '${DatabaseTables.setDate} DESC, ${DatabaseTables.setCreatedAt} DESC',
      );

      return maps.map(WorkoutSetModel.fromMap).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get all sets: $e');
    }
  }

  @override
  Future<WorkoutSet?> getSetById(String id) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.workoutSets,
        where: '${DatabaseTables.setId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return WorkoutSetModel.fromMap(maps.first);
    } catch (e) {
      throw CacheDatabaseException('Failed to get set by ID: $e');
    }
  }

  @override
  Future<List<WorkoutSet>> getSetsByExerciseId(String exerciseId) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.workoutSets,
        where: '${DatabaseTables.setExerciseId} = ?',
        whereArgs: [exerciseId],
        orderBy:
            '${DatabaseTables.setDate} DESC, ${DatabaseTables.setCreatedAt} DESC',
      );

      return maps.map(WorkoutSetModel.fromMap).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get sets by exercise ID: $e');
    }
  }

  @override
  Future<List<WorkoutSet>> getSetsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.workoutSets,
        where: '${DatabaseTables.setDate} >= ? AND ${DatabaseTables.setDate} <= ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy:
            '${DatabaseTables.setDate} DESC, ${DatabaseTables.setCreatedAt} DESC',
      );

      return maps.map(WorkoutSetModel.fromMap).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get sets by date range: $e');
    }
  }

  @override
  Future<List<WorkoutSet>> getPendingSyncSets() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.workoutSets,
        where:
            '${DatabaseTables.setSyncStatus} = ? OR ${DatabaseTables.setSyncStatus} = ?',
        whereArgs: const ['pendingUpload', 'pendingUpdate'],
        orderBy: '${DatabaseTables.setUpdatedAt} ASC',
      );

      return maps.map(WorkoutSetModel.fromMap).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get pending sync sets: $e');
    }
  }

  @override
  Future<void> addSet(WorkoutSet set) async {
    try {
      final db = await databaseHelper.database;
      final model = WorkoutSetModel.fromEntity(set);

      await db.insert(
        DatabaseTables.workoutSets,
        model.toMap(),
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to add set: $e');
    }
  }

  @override
  Future<void> updateSet(WorkoutSet set) async {
    try {
      final db = await databaseHelper.database;
      final model = WorkoutSetModel.fromEntity(set);

      await db.update(
        DatabaseTables.workoutSets,
        model.toMap(),
        where: '${DatabaseTables.setId} = ?',
        whereArgs: [model.id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to update set: $e');
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
        DatabaseTables.workoutSets,
        <String, Object?>{
          DatabaseTables.setServerId: serverId,
          DatabaseTables.setSyncStatus: 'synced',
          DatabaseTables.setLastSyncedAt: syncedAt.toIso8601String(),
          DatabaseTables.setLastSyncError: null,
        },
        where: '${DatabaseTables.setId} = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to mark set as synced: $e');
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
        DatabaseTables.workoutSets,
        <String, Object?>{
          DatabaseTables.setSyncStatus: 'pendingUpload',
          DatabaseTables.setLastSyncError: errorMessage,
        },
        where: '${DatabaseTables.setId} = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to mark set as pending upload: $e');
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
        DatabaseTables.workoutSets,
        <String, Object?>{
          DatabaseTables.setSyncStatus: 'pendingUpdate',
          DatabaseTables.setLastSyncError: errorMessage,
        },
        where: '${DatabaseTables.setId} = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to mark set as pending update: $e');
    }
  }

  @override
  Future<void> replaceAll(List<WorkoutSet> sets) async {
    try {
      final db = await databaseHelper.database;

      await db.transaction((txn) async {
        await txn.delete(DatabaseTables.workoutSets);

        final batch = txn.batch();
        for (final set in sets) {
          final model = WorkoutSetModel.fromEntity(set);
          batch.insert(DatabaseTables.workoutSets, model.toMap());
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      throw CacheDatabaseException('Failed to replace workout sets: $e');
    }
  }

  @override
  Future<void> deleteSet(String id) async {
    try {
      final db = await databaseHelper.database;

      await db.delete(
        DatabaseTables.workoutSets,
        where: '${DatabaseTables.setId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to delete set: $e');
    }
  }

  @override
  Future<void> clearAllSets() async {
    try {
      final db = await databaseHelper.database;
      await db.delete(DatabaseTables.workoutSets);
    } catch (e) {
      throw CacheDatabaseException('Failed to clear all sets: $e');
    }
  }
}