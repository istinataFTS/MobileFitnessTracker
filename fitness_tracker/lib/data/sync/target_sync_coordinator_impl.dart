import '../../core/enums/sync_entity_type.dart';
import '../../domain/entities/entity_sync_metadata.dart';
import '../../domain/entities/target.dart';
import '../datasources/local/target_local_datasource.dart';
import '../datasources/remote/target_remote_datasource.dart';
import '../models/target_model.dart';
import 'base_entity_sync_coordinator.dart';
import 'entity_sync_descriptor.dart';
import 'target_sync_coordinator.dart';

class TargetSyncCoordinatorImpl extends BaseEntitySyncCoordinator<Target>
    implements TargetSyncCoordinator {
  static const EntitySyncDescriptor _descriptor = EntitySyncDescriptor(
    entityType: SyncEntityType.target,
    operationKey: 'target',
    entityLabel: 'target',
  );

  final TargetLocalDataSource localDataSource;
  final TargetRemoteDataSource remoteDataSource;

  const TargetSyncCoordinatorImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required super.pendingSyncDeleteLocalDataSource,
  });

  @override
  bool get isRemoteSyncEnabled => remoteDataSource.isConfigured;

  @override
  Future<void> prepareForInitialCloudMigration(String userId) {
    return localDataSource.prepareForInitialCloudMigration(userId: userId);
  }

  @override
  EntitySyncDescriptor get descriptor => _descriptor;

  @override
  String getEntityId(Target entity) => entity.id;

  @override
  EntitySyncMetadata getSyncMetadata(Target entity) => entity.syncMetadata;

  @override
  Target buildAddedLocalEntity(Target entity, DateTime now) {
    return entity.copyWith(
      updatedAt: now,
      syncMetadata: buildAddedSyncMetadata(entity.syncMetadata),
    );
  }

  @override
  Target buildUpdatedLocalEntity({
    required Target entity,
    required Target? existingLocal,
    required DateTime now,
  }) {
    return entity.copyWith(
      updatedAt: now,
      syncMetadata: buildUpdatedSyncMetadata(
        incomingMetadata: entity.syncMetadata,
        existingLocalMetadata: existingLocal?.syncMetadata,
      ),
    );
  }

  @override
  Future<void> insertLocal(Target entity) {
    return localDataSource.insertTarget(TargetModel.fromEntity(entity));
  }

  @override
  Future<void> updateLocal(Target entity) {
    return localDataSource.updateTarget(TargetModel.fromEntity(entity));
  }

  @override
  Future<Target?> getLocalById(String id) {
    return localDataSource.getTargetById(id);
  }

  @override
  Future<void> deleteLocal(String id) {
    return localDataSource.deleteTarget(id);
  }

  @override
  Future<List<Target>> getPendingSyncEntities() {
    return localDataSource.getPendingSyncTargets();
  }

  @override
  Future<Target> upsertRemote(Target entity) {
    return remoteDataSource.upsertTarget(entity);
  }

  @override
  Future<void> deleteRemote({
    required String localId,
    required String? serverId,
  }) {
    return remoteDataSource.deleteTarget(
      localId: localId,
      serverId: serverId,
    );
  }

  @override
  Future<void> markAsSynced({
    required String localId,
    required String serverId,
    required DateTime syncedAt,
  }) {
    return localDataSource.markAsSynced(
      localId: localId,
      serverId: serverId,
      syncedAt: syncedAt,
    );
  }

  @override
  Future<void> markAsPendingUpload(
    String localId, {
    required String errorMessage,
  }) {
    return localDataSource.markAsPendingUpload(
      localId,
      errorMessage: errorMessage,
    );
  }

  @override
  Future<void> markAsPendingUpdate(
    String localId, {
    required String errorMessage,
  }) {
    return localDataSource.markAsPendingUpdate(
      localId,
      errorMessage: errorMessage,
    );
  }

  @override
  Future<void> markAsPendingDelete(String localId) {
    return localDataSource.markAsPendingDelete(localId);
  }

  @override
  Future<void> persistAddedTarget(Target target) {
    return persistAdded(target);
  }

  @override
  Future<void> persistUpdatedTarget(Target target) {
    return persistUpdated(target);
  }

  @override
  Future<void> persistDeletedTarget(String id) {
    return persistDeleted(id);
  }
}
