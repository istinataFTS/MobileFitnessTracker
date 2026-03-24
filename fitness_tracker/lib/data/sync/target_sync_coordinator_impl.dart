import '../../core/enums/sync_entity_type.dart';
import '../../core/enums/sync_status.dart';
import '../../domain/entities/entity_sync_metadata.dart';
import '../../domain/entities/pending_sync_delete.dart';
import '../../domain/entities/target.dart';
import '../datasources/local/pending_sync_delete_local_datasource.dart';
import '../datasources/local/target_local_datasource.dart';
import '../datasources/remote/target_remote_datasource.dart';
import '../models/target_model.dart';
import 'target_sync_coordinator.dart';

class TargetSyncCoordinatorImpl implements TargetSyncCoordinator {
  final TargetLocalDataSource localDataSource;
  final TargetRemoteDataSource remoteDataSource;
  final PendingSyncDeleteLocalDataSource pendingSyncDeleteLocalDataSource;

  const TargetSyncCoordinatorImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.pendingSyncDeleteLocalDataSource,
  });

  @override
  bool get isRemoteSyncEnabled => remoteDataSource.isConfigured;

  @override
  Future<void> persistAddedTarget(Target target) async {
    final now = DateTime.now();

    final localTarget = target.copyWith(
      updatedAt: now,
      syncMetadata: target.syncMetadata.copyWith(
        status: isRemoteSyncEnabled
            ? SyncStatus.pendingUpload
            : SyncStatus.localOnly,
        clearLastSyncError: true,
      ),
    );

    await localDataSource.insertTarget(TargetModel.fromEntity(localTarget));

    if (!isRemoteSyncEnabled) {
      return;
    }

    try {
      final remoteTarget = await remoteDataSource.upsertTarget(localTarget);
      await localDataSource.markAsSynced(
        localId: localTarget.id,
        serverId: remoteTarget.syncMetadata.serverId ?? remoteTarget.id,
        syncedAt: DateTime.now(),
      );
    } catch (error) {
      await localDataSource.markAsPendingUpload(
        localTarget.id,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<void> persistUpdatedTarget(Target target) async {
    final existingLocal = await localDataSource.getTargetById(target.id);
    final wasPreviouslySynced = existingLocal?.syncMetadata.isSynced ?? false;

    final localTarget = target.copyWith(
      updatedAt: DateTime.now(),
      syncMetadata: EntitySyncMetadata(
        serverId:
            existingLocal?.syncMetadata.serverId ?? target.syncMetadata.serverId,
        status: isRemoteSyncEnabled
            ? (wasPreviouslySynced
                ? SyncStatus.pendingUpdate
                : SyncStatus.pendingUpload)
            : SyncStatus.localOnly,
        lastSyncedAt: existingLocal?.syncMetadata.lastSyncedAt,
      ),
    );

    await localDataSource.updateTarget(TargetModel.fromEntity(localTarget));

    if (!isRemoteSyncEnabled) {
      return;
    }

    try {
      final remoteTarget = await remoteDataSource.upsertTarget(localTarget);
      await localDataSource.markAsSynced(
        localId: localTarget.id,
        serverId: remoteTarget.syncMetadata.serverId ?? remoteTarget.id,
        syncedAt: DateTime.now(),
      );
    } catch (error) {
      if (wasPreviouslySynced) {
        await localDataSource.markAsPendingUpdate(
          localTarget.id,
          errorMessage: error.toString(),
        );
      } else {
        await localDataSource.markAsPendingUpload(
          localTarget.id,
          errorMessage: error.toString(),
        );
      }
    }
  }

  @override
  Future<void> persistDeletedTarget(String id) async {
    final existingLocal = await localDataSource.getTargetById(id);
    if (existingLocal == null) {
      return;
    }

    final shouldQueueDelete = _shouldQueueRemoteDelete(existingLocal);

    if (shouldQueueDelete) {
      await pendingSyncDeleteLocalDataSource.enqueue(
        PendingSyncDelete(
          id: _buildDeleteOperationId(existingLocal.id),
          entityType: SyncEntityType.target,
          localEntityId: existingLocal.id,
          serverEntityId: existingLocal.syncMetadata.serverId,
          createdAt: DateTime.now(),
        ),
      );

      await localDataSource.markAsPendingDelete(existingLocal.id);
    } else {
      await localDataSource.deleteTarget(id);
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

    final pendingTargets = await localDataSource.getPendingSyncTargets();

    for (final target in pendingTargets) {
      if (target.syncMetadata.status == SyncStatus.pendingDelete) {
        continue;
      }

      final remoteTarget = await remoteDataSource.upsertTarget(target);
      await localDataSource.markAsSynced(
        localId: target.id,
        serverId: remoteTarget.syncMetadata.serverId ?? remoteTarget.id,
        syncedAt: DateTime.now(),
      );
    }

    await _flushPendingDeletes();
  }

  Future<void> _flushPendingDeletes() async {
    final operations = await pendingSyncDeleteLocalDataSource
        .getPendingByEntityType(SyncEntityType.target);

    for (final operation in operations) {
      try {
        await remoteDataSource.deleteTarget(
          localId: operation.localEntityId,
          serverId: operation.serverEntityId,
        );
        await pendingSyncDeleteLocalDataSource.remove(operation.id);
        await localDataSource.deleteTarget(operation.localEntityId);
      } catch (error) {
        await pendingSyncDeleteLocalDataSource.markAttempted(
          operation.id,
          attemptedAt: DateTime.now(),
          errorMessage: error.toString(),
        );
      }
    }
  }

  bool _shouldQueueRemoteDelete(Target target) {
    return target.syncMetadata.serverId != null ||
        target.syncMetadata.isSynced ||
        target.syncMetadata.hasPendingSync;
  }

  String _buildDeleteOperationId(String localEntityId) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'target_delete_${localEntityId}_$timestamp';
  }
}