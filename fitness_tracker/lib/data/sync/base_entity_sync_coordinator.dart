import '../../core/enums/sync_status.dart';
import '../../domain/entities/entity_sync_metadata.dart';
import '../../domain/entities/pending_sync_delete.dart';
import '../datasources/local/pending_sync_delete_local_datasource.dart';
import 'entity_sync_batch_failure.dart';
import 'entity_sync_descriptor.dart';

abstract class BaseEntitySyncCoordinator<T> {
  final PendingSyncDeleteLocalDataSource pendingSyncDeleteLocalDataSource;

  const BaseEntitySyncCoordinator({
    required this.pendingSyncDeleteLocalDataSource,
  });

  bool get isRemoteSyncEnabled;

  EntitySyncDescriptor get descriptor;

  String getEntityId(T entity);

  EntitySyncMetadata getSyncMetadata(T entity);

  T buildAddedLocalEntity(T entity, DateTime now);

  T buildUpdatedLocalEntity({
    required T entity,
    required T? existingLocal,
    required DateTime now,
  });

  Future<void> insertLocal(T entity);

  Future<void> updateLocal(T entity);

  Future<T?> getLocalById(String id);

  Future<void> deleteLocal(String id);

  Future<List<T>> getPendingSyncEntities();

  Future<T> upsertRemote(T entity);

  Future<void> deleteRemote({
    required String localId,
    required String? serverId,
  });

  Future<void> markAsSynced({
    required String localId,
    required String serverId,
    required DateTime syncedAt,
  });

  Future<void> markAsPendingUpload(
    String localId, {
    required String errorMessage,
  });

  Future<void> markAsPendingUpdate(
    String localId, {
    required String errorMessage,
  });

  Future<void> markAsPendingDelete(String localId);

  Future<void> persistAdded(T entity) async {
    final localEntity = buildAddedLocalEntity(entity, DateTime.now());

    await insertLocal(localEntity);

    if (!isRemoteSyncEnabled) {
      return;
    }

    try {
      final remoteEntity = await upsertRemote(localEntity);
      final remoteMetadata = getSyncMetadata(remoteEntity);

      await markAsSynced(
        localId: getEntityId(localEntity),
        serverId: remoteMetadata.serverId ?? getEntityId(remoteEntity),
        syncedAt: DateTime.now(),
      );
    } catch (error) {
      await markAsPendingUpload(
        getEntityId(localEntity),
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> persistUpdated(T entity) async {
    final existingLocal = await getLocalById(getEntityId(entity));
    final wasPreviouslySynced = existingLocal != null
        ? getSyncMetadata(existingLocal).isSynced
        : false;

    final localEntity = buildUpdatedLocalEntity(
      entity: entity,
      existingLocal: existingLocal,
      now: DateTime.now(),
    );

    await updateLocal(localEntity);

    if (!isRemoteSyncEnabled) {
      return;
    }

    try {
      final remoteEntity = await upsertRemote(localEntity);
      final remoteMetadata = getSyncMetadata(remoteEntity);

      await markAsSynced(
        localId: getEntityId(localEntity),
        serverId: remoteMetadata.serverId ?? getEntityId(remoteEntity),
        syncedAt: DateTime.now(),
      );
    } catch (error) {
      if (wasPreviouslySynced) {
        await markAsPendingUpdate(
          getEntityId(localEntity),
          errorMessage: error.toString(),
        );
      } else {
        await markAsPendingUpload(
          getEntityId(localEntity),
          errorMessage: error.toString(),
        );
      }
    }
  }

  Future<void> persistDeleted(String id) async {
    final existingLocal = await getLocalById(id);
    if (existingLocal == null) {
      return;
    }

    if (_shouldQueueRemoteDelete(existingLocal)) {
      await pendingSyncDeleteLocalDataSource.enqueue(
        PendingSyncDelete(
          id: _buildDeleteOperationId(id),
          entityType: descriptor.entityType,
          localEntityId: id,
          serverEntityId: getSyncMetadata(existingLocal).serverId,
          createdAt: DateTime.now(),
        ),
      );

      await markAsPendingDelete(id);
    } else {
      await deleteLocal(id);
    }

    if (!isRemoteSyncEnabled) {
      return;
    }

    await flushPendingDeletes();
  }

  Future<void> syncPendingChanges() async {
    if (!isRemoteSyncEnabled) {
      return;
    }

    final pendingEntities = await getPendingSyncEntities();
    final List<String> failedUpsertEntityIds = <String>[];

    for (final entity in pendingEntities) {
      if (getSyncMetadata(entity).status == SyncStatus.pendingDelete) {
        continue;
      }

      try {
        final remoteEntity = await upsertRemote(entity);
        final remoteMetadata = getSyncMetadata(remoteEntity);

        await markAsSynced(
          localId: getEntityId(entity),
          serverId: remoteMetadata.serverId ?? getEntityId(remoteEntity),
          syncedAt: DateTime.now(),
        );
      } catch (error) {
        failedUpsertEntityIds.add(getEntityId(entity));

        await _markEntitySyncFailure(
          entity,
          errorMessage: error.toString(),
        );
      }
    }

    final List<String> failedDeleteEntityIds = await flushPendingDeletes();

    if (failedUpsertEntityIds.isNotEmpty || failedDeleteEntityIds.isNotEmpty) {
      throw EntitySyncBatchFailure(
        entityLabel: descriptor.entityLabel,
        failedUpsertEntityIds: failedUpsertEntityIds,
        failedDeleteEntityIds: failedDeleteEntityIds,
      );
    }
  }

  Future<List<String>> flushPendingDeletes() async {
    final operations = await pendingSyncDeleteLocalDataSource
        .getPendingByEntityType(descriptor.entityType);
    final List<String> failedDeleteEntityIds = <String>[];

    for (final operation in operations) {
      try {
        await deleteRemote(
          localId: operation.localEntityId,
          serverId: operation.serverEntityId,
        );

        await pendingSyncDeleteLocalDataSource.remove(operation.id);
        await deleteLocal(operation.localEntityId);
      } catch (error) {
        failedDeleteEntityIds.add(operation.localEntityId);

        await pendingSyncDeleteLocalDataSource.markAttempted(
          operation.id,
          attemptedAt: DateTime.now(),
          errorMessage: error.toString(),
        );
      }
    }

    return failedDeleteEntityIds;
  }

  Future<void> _markEntitySyncFailure(
    T entity, {
    required String errorMessage,
  }) async {
    final localId = getEntityId(entity);
    final status = getSyncMetadata(entity).status;

    if (status == SyncStatus.pendingUpdate) {
      await markAsPendingUpdate(
        localId,
        errorMessage: errorMessage,
      );
      return;
    }

    await markAsPendingUpload(
      localId,
      errorMessage: errorMessage,
    );
  }

  bool _shouldQueueRemoteDelete(T entity) {
    final metadata = getSyncMetadata(entity);

    return metadata.serverId != null ||
        metadata.isSynced ||
        metadata.hasPendingSync;
  }

  String _buildDeleteOperationId(String localEntityId) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return '${descriptor.operationKey}_delete_${localEntityId}_$timestamp';
  }
}