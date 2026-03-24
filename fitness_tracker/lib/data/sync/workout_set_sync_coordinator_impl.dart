import '../../core/enums/sync_entity_type.dart';
import '../../core/enums/sync_status.dart';
import '../../domain/entities/entity_sync_metadata.dart';
import '../../domain/entities/pending_sync_delete.dart';
import '../../domain/entities/workout_set.dart';
import '../datasources/local/pending_sync_delete_local_datasource.dart';
import '../datasources/local/workout_set_local_datasource.dart';
import '../datasources/remote/workout_set_remote_datasource.dart';
import 'workout_set_sync_coordinator.dart';

class WorkoutSetSyncCoordinatorImpl implements WorkoutSetSyncCoordinator {
  final WorkoutSetLocalDataSource localDataSource;
  final WorkoutSetRemoteDataSource remoteDataSource;
  final PendingSyncDeleteLocalDataSource pendingSyncDeleteLocalDataSource;

  const WorkoutSetSyncCoordinatorImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.pendingSyncDeleteLocalDataSource,
  });

  @override
  bool get isRemoteSyncEnabled => remoteDataSource.isConfigured;

  @override
  Future<void> persistAddedSet(WorkoutSet set) async {
    final now = DateTime.now();

    final localSet = set.copyWith(
      updatedAt: now,
      syncMetadata: set.syncMetadata.copyWith(
        status: isRemoteSyncEnabled
            ? SyncStatus.pendingUpload
            : SyncStatus.localOnly,
        clearLastSyncError: true,
      ),
    );

    await localDataSource.addSet(localSet);

    if (!isRemoteSyncEnabled) {
      return;
    }

    try {
      final remoteSet = await remoteDataSource.upsertSet(localSet);
      await localDataSource.markAsSynced(
        localId: localSet.id,
        serverId: remoteSet.syncMetadata.serverId ?? remoteSet.id,
        syncedAt: DateTime.now(),
      );
    } catch (error) {
      await localDataSource.markAsPendingUpload(
        localSet.id,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<void> persistUpdatedSet(WorkoutSet set) async {
    final existingLocal = await localDataSource.getSetById(set.id);
    final wasPreviouslySynced = existingLocal?.syncMetadata.isSynced ?? false;

    final localSet = set.copyWith(
      updatedAt: DateTime.now(),
      syncMetadata: EntitySyncMetadata(
        serverId:
            existingLocal?.syncMetadata.serverId ?? set.syncMetadata.serverId,
        status: isRemoteSyncEnabled
            ? (wasPreviouslySynced
                ? SyncStatus.pendingUpdate
                : SyncStatus.pendingUpload)
            : SyncStatus.localOnly,
        lastSyncedAt: existingLocal?.syncMetadata.lastSyncedAt,
      ),
    );

    await localDataSource.updateSet(localSet);

    if (!isRemoteSyncEnabled) {
      return;
    }

    try {
      final remoteSet = await remoteDataSource.upsertSet(localSet);
      await localDataSource.markAsSynced(
        localId: localSet.id,
        serverId: remoteSet.syncMetadata.serverId ?? remoteSet.id,
        syncedAt: DateTime.now(),
      );
    } catch (error) {
      if (wasPreviouslySynced) {
        await localDataSource.markAsPendingUpdate(
          localSet.id,
          errorMessage: error.toString(),
        );
      } else {
        await localDataSource.markAsPendingUpload(
          localSet.id,
          errorMessage: error.toString(),
        );
      }
    }
  }

  @override
  Future<void> persistDeletedSet(String id) async {
    final existingLocal = await localDataSource.getSetById(id);
    if (existingLocal == null) {
      return;
    }

    final shouldQueueDelete = _shouldQueueRemoteDelete(existingLocal);

    if (shouldQueueDelete) {
      await pendingSyncDeleteLocalDataSource.enqueue(
        PendingSyncDelete(
          id: _buildDeleteOperationId(existingLocal.id),
          entityType: SyncEntityType.workoutSet,
          localEntityId: existingLocal.id,
          serverEntityId: existingLocal.syncMetadata.serverId,
          createdAt: DateTime.now(),
        ),
      );

      await localDataSource.markAsPendingDelete(existingLocal.id);
    } else {
      await localDataSource.deleteSet(id);
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

    final pendingSets = await localDataSource.getPendingSyncSets();

    for (final set in pendingSets) {
      if (set.syncMetadata.status == SyncStatus.pendingDelete) {
        continue;
      }

      final remoteSet = await remoteDataSource.upsertSet(set);
      await localDataSource.markAsSynced(
        localId: set.id,
        serverId: remoteSet.syncMetadata.serverId ?? remoteSet.id,
        syncedAt: DateTime.now(),
      );
    }

    await _flushPendingDeletes();
  }

  Future<void> _flushPendingDeletes() async {
    final operations = await pendingSyncDeleteLocalDataSource
        .getPendingByEntityType(SyncEntityType.workoutSet);

    for (final operation in operations) {
      try {
        await remoteDataSource.deleteSet(
          localId: operation.localEntityId,
          serverId: operation.serverEntityId,
        );
        await pendingSyncDeleteLocalDataSource.remove(operation.id);
        await localDataSource.deleteSet(operation.localEntityId);
      } catch (error) {
        await pendingSyncDeleteLocalDataSource.markAttempted(
          operation.id,
          attemptedAt: DateTime.now(),
          errorMessage: error.toString(),
        );
      }
    }
  }

  bool _shouldQueueRemoteDelete(WorkoutSet set) {
    return set.syncMetadata.serverId != null ||
        set.syncMetadata.isSynced ||
        set.syncMetadata.hasPendingSync;
  }

  String _buildDeleteOperationId(String localEntityId) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'workout_set_delete_${localEntityId}_$timestamp';
  }
}