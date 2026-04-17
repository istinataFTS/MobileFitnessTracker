import '../../core/enums/sync_status.dart';
import '../../core/logging/app_logger.dart';
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

  EntitySyncMetadata buildAddedSyncMetadata(
    EntitySyncMetadata currentMetadata,
  ) {
    return currentMetadata.copyWith(
      status: isRemoteSyncEnabled
          ? SyncStatus.pendingUpload
          : SyncStatus.localOnly,
      clearLastSyncError: true,
    );
  }

  EntitySyncMetadata buildUpdatedSyncMetadata({
    required EntitySyncMetadata incomingMetadata,
    required EntitySyncMetadata? existingLocalMetadata,
  }) {
    final wasPreviouslySynced = existingLocalMetadata?.isSynced ?? false;

    return EntitySyncMetadata(
      serverId: existingLocalMetadata?.serverId ?? incomingMetadata.serverId,
      status: isRemoteSyncEnabled
          ? (wasPreviouslySynced
              ? SyncStatus.pendingUpdate
              : SyncStatus.pendingUpload)
          : SyncStatus.localOnly,
      lastSyncedAt: existingLocalMetadata?.lastSyncedAt,
    );
  }

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

  // ---------------------------------------------------------------------------
  // Pull (remote → local)
  // ---------------------------------------------------------------------------

  /// Fetches all remote rows for [userId] modified after [since] (or all rows
  /// when [since] is null) and upserts them into the local store.
  ///
  /// **Conflict rule — local wins when dirty, remote wins otherwise:**
  /// If the local copy of an entity has a pending sync modification
  /// (`hasPendingSync == true`), that offline change is preserved and the
  /// remote version is skipped.  This prevents a concurrent pull from
  /// silently discarding work the user did while offline.
  ///
  /// > **Single-device limitation (pre-GA):** Conflict detection relies on
  /// > matching the remote entity's ID to the local primary key.  When a
  /// > local entity's primary key differs from its server ID (i.e. it was
  /// > created offline and not yet pushed), a remote copy of the same entity
  /// > arriving via pull would be inserted as a new row rather than merged.
  /// > In practice this scenario only occurs during simultaneous multi-device
  /// > edits, which are out of scope for the current release.
  Future<List<T>> fetchSince({
    required String userId,
    DateTime? since,
  });

  Future<void> pullRemoteChanges({
    required String userId,
    DateTime? since,
  }) async {
    if (!isRemoteSyncEnabled) {
      return;
    }

    final remoteEntities = await fetchSince(userId: userId, since: since);

    if (remoteEntities.isEmpty) {
      return;
    }

    AppLogger.info(
      'Pull: fetched ${remoteEntities.length} ${descriptor.entityLabel}(s) '
      'for userId=$userId since=${since?.toIso8601String() ?? 'epoch'}',
      category: 'sync',
    );

    // Build a set of server IDs that have pending local modifications so we
    // can skip them below (local wins over remote for dirty entities).
    final pendingEntities = await getPendingSyncEntities();
    final dirtyServerIds = pendingEntities
        .map((e) => getSyncMetadata(e).serverId)
        .whereType<String>()
        .toSet();

    int inserted = 0;
    int updated = 0;
    int skipped = 0;

    for (final remoteEntity in remoteEntities) {
      final remoteId = getEntityId(remoteEntity);

      // Local wins: preserve pending offline edits.
      if (dirtyServerIds.contains(remoteId)) {
        skipped++;
        continue;
      }

      final existing = await getLocalById(remoteId);

      if (existing != null) {
        await updateLocal(remoteEntity);
        updated++;
      } else {
        await insertLocal(remoteEntity);
        inserted++;
      }
    }

    AppLogger.info(
      'Pull complete for ${descriptor.entityLabel}: '
      'inserted=$inserted updated=$updated skipped=$skipped',
      category: 'sync',
    );
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