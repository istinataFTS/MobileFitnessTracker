import '../../core/enums/sync_entity_type.dart';
import '../../core/enums/sync_status.dart';
import '../../domain/entities/entity_sync_metadata.dart';
import '../../domain/entities/nutrition_log.dart';
import '../../domain/entities/pending_sync_delete.dart';
import '../datasources/local/nutrition_log_local_datasource.dart';
import '../datasources/local/pending_sync_delete_local_datasource.dart';
import '../datasources/remote/nutrition_log_remote_datasource.dart';
import '../models/nutrition_log_model.dart';
import 'nutrition_log_sync_coordinator.dart';

class NutritionLogSyncCoordinatorImpl implements NutritionLogSyncCoordinator {
  final NutritionLogLocalDataSource localDataSource;
  final NutritionLogRemoteDataSource remoteDataSource;
  final PendingSyncDeleteLocalDataSource pendingSyncDeleteLocalDataSource;

  const NutritionLogSyncCoordinatorImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.pendingSyncDeleteLocalDataSource,
  });

  @override
  bool get isRemoteSyncEnabled => remoteDataSource.isConfigured;

  @override
  Future<void> persistAddedLog(NutritionLog log) async {
    final now = DateTime.now();

    final localLog = log.copyWith(
      updatedAt: now,
      syncMetadata: log.syncMetadata.copyWith(
        status: isRemoteSyncEnabled
            ? SyncStatus.pendingUpload
            : SyncStatus.localOnly,
        clearLastSyncError: true,
      ),
    );

    final model = NutritionLogModel.fromEntity(localLog);
    model.validate();
    await localDataSource.insertLog(model);

    if (!isRemoteSyncEnabled) {
      return;
    }

    try {
      final remoteLog = await remoteDataSource.upsertLog(localLog);
      await localDataSource.markAsSynced(
        localId: localLog.id,
        serverId: remoteLog.syncMetadata.serverId ?? remoteLog.id,
        syncedAt: DateTime.now(),
      );
    } catch (error) {
      await localDataSource.markAsPendingUpload(
        localLog.id,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<void> persistUpdatedLog(NutritionLog log) async {
    final existingLocal = await localDataSource.getLogById(log.id);
    final wasPreviouslySynced = existingLocal?.syncMetadata.isSynced ?? false;

    final localLog = log.copyWith(
      updatedAt: DateTime.now(),
      syncMetadata: EntitySyncMetadata(
        serverId:
            existingLocal?.syncMetadata.serverId ?? log.syncMetadata.serverId,
        status: isRemoteSyncEnabled
            ? (wasPreviouslySynced
                ? SyncStatus.pendingUpdate
                : SyncStatus.pendingUpload)
            : SyncStatus.localOnly,
        lastSyncedAt: existingLocal?.syncMetadata.lastSyncedAt,
      ),
    );

    final model = NutritionLogModel.fromEntity(localLog);
    model.validate();
    await localDataSource.updateLog(model);

    if (!isRemoteSyncEnabled) {
      return;
    }

    try {
      final remoteLog = await remoteDataSource.upsertLog(localLog);
      await localDataSource.markAsSynced(
        localId: localLog.id,
        serverId: remoteLog.syncMetadata.serverId ?? remoteLog.id,
        syncedAt: DateTime.now(),
      );
    } catch (error) {
      if (wasPreviouslySynced) {
        await localDataSource.markAsPendingUpdate(
          localLog.id,
          errorMessage: error.toString(),
        );
      } else {
        await localDataSource.markAsPendingUpload(
          localLog.id,
          errorMessage: error.toString(),
        );
      }
    }
  }

  @override
  Future<void> persistDeletedLog(String id) async {
    final existingLocal = await localDataSource.getLogById(id);
    if (existingLocal == null) {
      return;
    }

    final shouldQueueDelete = _shouldQueueRemoteDelete(existingLocal);

    if (shouldQueueDelete) {
      await pendingSyncDeleteLocalDataSource.enqueue(
        PendingSyncDelete(
          id: _buildDeleteOperationId(existingLocal.id),
          entityType: SyncEntityType.nutritionLog,
          localEntityId: existingLocal.id,
          serverEntityId: existingLocal.syncMetadata.serverId,
          createdAt: DateTime.now(),
        ),
      );

      await localDataSource.markAsPendingDelete(existingLocal.id);
    } else {
      await localDataSource.deleteLog(id);
    }

    if (!isRemoteSyncEnabled) {
      return;
    }

    await _flushPendingDeletes();
  }

  @override
  Future<void> syncPendingChanges() async {
    if (!isRemoteSyncEnabled) {
      return;
    }

    final pendingLogs = await localDataSource.getPendingSyncLogs();

    for (final log in pendingLogs) {
      if (log.syncMetadata.status == SyncStatus.pendingDelete) {
        continue;
      }

      final remoteLog = await remoteDataSource.upsertLog(log);
      await localDataSource.markAsSynced(
        localId: log.id,
        serverId: remoteLog.syncMetadata.serverId ?? remoteLog.id,
        syncedAt: DateTime.now(),
      );
    }

    await _flushPendingDeletes();
  }

  Future<void> _flushPendingDeletes() async {
    final operations = await pendingSyncDeleteLocalDataSource
        .getPendingByEntityType(SyncEntityType.nutritionLog);

    for (final operation in operations) {
      try {
        await remoteDataSource.deleteLog(
          localId: operation.localEntityId,
          serverId: operation.serverEntityId,
        );
        await pendingSyncDeleteLocalDataSource.remove(operation.id);
        await localDataSource.deleteLog(operation.localEntityId);
      } catch (error) {
        await pendingSyncDeleteLocalDataSource.markAttempted(
          operation.id,
          attemptedAt: DateTime.now(),
          errorMessage: error.toString(),
        );
      }
    }
  }

  bool _shouldQueueRemoteDelete(NutritionLog log) {
    return log.syncMetadata.serverId != null ||
        log.syncMetadata.isSynced ||
        log.syncMetadata.hasPendingSync;
  }

  String _buildDeleteOperationId(String localEntityId) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'nutrition_log_delete_${localEntityId}_$timestamp';
  }
}