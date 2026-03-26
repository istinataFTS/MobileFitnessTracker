import 'package:sqflite/sqflite.dart';

import '../../../core/constants/database_tables.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/enums/sync_status.dart';
import '../../../core/sync/local_remote_merge.dart';
import '../../../domain/entities/target.dart';
import '../../models/target_model.dart';
import 'database_helper.dart';

abstract class TargetLocalDataSource {
  Future<List<TargetModel>> getAllTargets();
  Future<TargetModel?> getTargetById(String id);
  Future<TargetModel?> getTargetByTypeAndCategory(
    TargetType type,
    String categoryKey,
    TargetPeriod period,
  );
  Future<List<TargetModel>> getPendingSyncTargets();
  Future<void> insertTarget(TargetModel target);
  Future<void> updateTarget(TargetModel target);
  Future<void> upsertTarget(TargetModel target);
  Future<void> mergeRemoteTargets(List<TargetModel> targets);
  Future<void> markAsSynced({
    required String localId,
    required String serverId,
    required DateTime syncedAt,
  });
  Future<void> markAsPendingUpload(String localId, {String? errorMessage});
  Future<void> markAsPendingUpdate(String localId, {String? errorMessage});
  Future<void> markAsPendingDelete(String localId, {String? errorMessage});
  Future<void> replaceAllTargets(List<TargetModel> targets);
  Future<void> deleteTarget(String id);
  Future<void> clearAllTargets();
}

class TargetLocalDataSourceImpl implements TargetLocalDataSource {
  final DatabaseHelper databaseHelper;

  static final LocalRemoteMerge<TargetModel> _merge =
      LocalRemoteMerge<TargetModel>(
        getId: (target) => target.id,
        getUpdatedAt: (target) => target.updatedAt,
        getSyncMetadata: (target) => target.syncMetadata,
      );

  const TargetLocalDataSourceImpl({
    required this.databaseHelper,
  });

  @override
  Future<List<TargetModel>> getAllTargets() async {
    try {
      return await _getVisibleTargets();
    } catch (e) {
      throw CacheDatabaseException('Failed to get targets: $e');
    }
  }

  @override
  Future<TargetModel?> getTargetById(String id) async {
    try {
      return await _getVisibleTargetById(id);
    } catch (e) {
      throw CacheDatabaseException('Failed to get target by id: $e');
    }
  }

  @override
  Future<TargetModel?> getTargetByTypeAndCategory(
    TargetType type,
    String categoryKey,
    TargetPeriod period,
  ) async {
    try {
      final db = await databaseHelper.database;
      final typeValue = _targetTypeToString(type);
      final periodValue = _targetPeriodToString(period);

      final maps = await db.query(
        DatabaseTables.targets,
        where: '''
          ${DatabaseTables.targetType} = ? AND
          ${DatabaseTables.targetCategoryKey} = ? AND
          ${DatabaseTables.targetPeriod} = ? AND
          (${DatabaseTables.targetSyncStatus} IS NULL OR ${DatabaseTables.targetSyncStatus} != ?)
        ''',
        whereArgs: [
          typeValue,
          categoryKey,
          periodValue,
          SyncStatus.pendingDelete.name,
        ],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return TargetModel.fromMap(maps.first);
    } catch (e) {
      throw CacheDatabaseException('Failed to get target: $e');
    }
  }

  @override
  Future<List<TargetModel>> getPendingSyncTargets() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.targets,
        where:
            '${DatabaseTables.targetSyncStatus} = ? OR ${DatabaseTables.targetSyncStatus} = ?',
        whereArgs: [
          SyncStatus.pendingUpload.name,
          SyncStatus.pendingUpdate.name,
        ],
        orderBy: '${DatabaseTables.targetUpdatedAt} ASC',
      );

      return maps.map(TargetModel.fromMap).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get pending sync targets: $e');
    }
  }

  @override
  Future<void> insertTarget(TargetModel target) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseTables.targets,
        target.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to insert target: $e');
    }
  }

  @override
  Future<void> updateTarget(TargetModel target) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseTables.targets,
        target.toMap(),
        where: '${DatabaseTables.targetId} = ?',
        whereArgs: [target.id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to update target: $e');
    }
  }

  @override
  Future<void> upsertTarget(TargetModel target) async {
    final existing = await _getStoredTargetById(target.id);
    if (existing == null) {
      await insertTarget(target);
      return;
    }

    if (existing.syncMetadata.isPendingDelete &&
        !target.syncMetadata.isPendingDelete) {
      return;
    }

    await updateTarget(target);
  }

  @override
  Future<void> mergeRemoteTargets(List<TargetModel> targets) async {
    try {
      final storedLocalTargets = await _getStoredTargets();
      final mergedVisibleTargets = _merge.mergeLists(
        localItems: storedLocalTargets,
        remoteItems: targets,
      );

      final Map<String, TargetModel> mergedById = <String, TargetModel>{
        for (final target in mergedVisibleTargets) target.id: target,
      };

      for (final localTarget in storedLocalTargets) {
        if (localTarget.syncMetadata.isPendingDelete) {
          mergedById.putIfAbsent(localTarget.id, () => localTarget);
        }
      }

      await _replaceStoredTargets(mergedById.values.toList());
    } catch (e) {
      throw CacheDatabaseException('Failed to merge remote targets: $e');
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
        DatabaseTables.targets,
        <String, Object?>{
          DatabaseTables.targetServerId: serverId,
          DatabaseTables.targetSyncStatus: SyncStatus.synced.name,
          DatabaseTables.targetLastSyncedAt: syncedAt.toIso8601String(),
          DatabaseTables.targetLastSyncError: null,
        },
        where: '${DatabaseTables.targetId} = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to mark target as synced: $e');
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
        DatabaseTables.targets,
        <String, Object?>{
          DatabaseTables.targetSyncStatus: SyncStatus.pendingUpload.name,
          DatabaseTables.targetLastSyncError: errorMessage,
        },
        where: '${DatabaseTables.targetId} = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw CacheDatabaseException(
        'Failed to mark target as pending upload: $e',
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
        DatabaseTables.targets,
        <String, Object?>{
          DatabaseTables.targetSyncStatus: SyncStatus.pendingUpdate.name,
          DatabaseTables.targetLastSyncError: errorMessage,
        },
        where: '${DatabaseTables.targetId} = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw CacheDatabaseException(
        'Failed to mark target as pending update: $e',
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
        DatabaseTables.targets,
        <String, Object?>{
          DatabaseTables.targetSyncStatus: SyncStatus.pendingDelete.name,
          DatabaseTables.targetLastSyncError: errorMessage,
        },
        where: '${DatabaseTables.targetId} = ?',
        whereArgs: [localId],
      );
    } catch (e) {
      throw CacheDatabaseException(
        'Failed to mark target as pending delete: $e',
      );
    }
  }

  @override
  Future<void> replaceAllTargets(List<TargetModel> targets) async {
    try {
      await _replaceStoredTargets(targets);
    } catch (e) {
      throw CacheDatabaseException('Failed to replace all targets: $e');
    }
  }

  @override
  Future<void> deleteTarget(String id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        DatabaseTables.targets,
        where: '${DatabaseTables.targetId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to delete target: $e');
    }
  }

  @override
  Future<void> clearAllTargets() async {
    try {
      final db = await databaseHelper.database;
      await db.delete(DatabaseTables.targets);
    } catch (e) {
      throw CacheDatabaseException('Failed to clear targets: $e');
    }
  }

  Future<List<TargetModel>> _getVisibleTargets() async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseTables.targets,
      where:
          '${DatabaseTables.targetSyncStatus} IS NULL OR ${DatabaseTables.targetSyncStatus} != ?',
      whereArgs: <Object?>[SyncStatus.pendingDelete.name],
      orderBy: '''
        ${DatabaseTables.targetType} ASC,
        ${DatabaseTables.targetPeriod} ASC,
        ${DatabaseTables.targetCreatedAt} DESC
      ''',
    );

    return maps.map(TargetModel.fromMap).toList();
  }

  Future<TargetModel?> _getVisibleTargetById(String id) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseTables.targets,
      where:
          '${DatabaseTables.targetId} = ? AND (${DatabaseTables.targetSyncStatus} IS NULL OR ${DatabaseTables.targetSyncStatus} != ?)',
      whereArgs: <Object?>[id, SyncStatus.pendingDelete.name],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return TargetModel.fromMap(maps.first);
  }

  Future<List<TargetModel>> _getStoredTargets() async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseTables.targets,
      orderBy: '''
        ${DatabaseTables.targetType} ASC,
        ${DatabaseTables.targetPeriod} ASC,
        ${DatabaseTables.targetCreatedAt} DESC
      ''',
    );

    return maps.map(TargetModel.fromMap).toList();
  }

  Future<TargetModel?> _getStoredTargetById(String id) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseTables.targets,
      where: '${DatabaseTables.targetId} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return TargetModel.fromMap(maps.first);
  }

  Future<void> _replaceStoredTargets(List<TargetModel> targets) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      await txn.delete(DatabaseTables.targets);

      final batch = txn.batch();
      for (final target in targets) {
        batch.insert(
          DatabaseTables.targets,
          target.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  String _targetTypeToString(TargetType type) {
    switch (type) {
      case TargetType.muscleSets:
        return 'muscle_sets';
      case TargetType.macro:
        return 'macro';
    }
  }

  String _targetPeriodToString(TargetPeriod period) {
    switch (period) {
      case TargetPeriod.daily:
        return 'daily';
      case TargetPeriod.weekly:
        return 'weekly';
    }
  }
}
