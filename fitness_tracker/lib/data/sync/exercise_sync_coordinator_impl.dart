import '../../core/enums/sync_entity_type.dart';
import '../../core/enums/sync_status.dart';
import '../../domain/entities/entity_sync_metadata.dart';
import '../../domain/entities/exercise.dart';
import '../datasources/local/exercise_local_datasource.dart';
import '../datasources/local/pending_sync_delete_local_datasource.dart';
import '../datasources/remote/exercise_remote_datasource.dart';
import '../models/exercise_model.dart';
import 'base_entity_sync_coordinator.dart';
import 'exercise_sync_coordinator.dart';

class ExerciseSyncCoordinatorImpl extends BaseEntitySyncCoordinator<Exercise>
    implements ExerciseSyncCoordinator {
  final ExerciseLocalDataSource localDataSource;
  final ExerciseRemoteDataSource remoteDataSource;

  const ExerciseSyncCoordinatorImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required super.pendingSyncDeleteLocalDataSource,
  });

  @override
  bool get isRemoteSyncEnabled => remoteDataSource.isConfigured;

  @override
  SyncEntityType get entityType => SyncEntityType.exercise;

  @override
  String get deleteOperationPrefix => 'exercise';

  @override
  String getEntityId(Exercise entity) => entity.id;

  @override
  EntitySyncMetadata getSyncMetadata(Exercise entity) => entity.syncMetadata;

  @override
  Exercise buildAddedLocalEntity(Exercise entity, DateTime now) {
    return entity.copyWith(
      updatedAt: now,
      syncMetadata: entity.syncMetadata.copyWith(
        status: isRemoteSyncEnabled
            ? SyncStatus.pendingUpload
            : SyncStatus.localOnly,
        clearLastSyncError: true,
      ),
    );
  }

  @override
  Exercise buildUpdatedLocalEntity({
    required Exercise entity,
    required Exercise? existingLocal,
    required DateTime now,
  }) {
    final wasPreviouslySynced = existingLocal?.syncMetadata.isSynced ?? false;

    return entity.copyWith(
      updatedAt: now,
      syncMetadata: EntitySyncMetadata(
        serverId:
            existingLocal?.syncMetadata.serverId ?? entity.syncMetadata.serverId,
        status: isRemoteSyncEnabled
            ? (wasPreviouslySynced
                ? SyncStatus.pendingUpdate
                : SyncStatus.pendingUpload)
            : SyncStatus.localOnly,
        lastSyncedAt: existingLocal?.syncMetadata.lastSyncedAt,
      ),
    );
  }

  @override
  Future<void> insertLocal(Exercise entity) {
    return localDataSource.insertExercise(
      ExerciseModel.fromEntity(entity),
    );
  }

  @override
  Future<void> updateLocal(Exercise entity) {
    return localDataSource.updateExercise(
      ExerciseModel.fromEntity(entity),
    );
  }

  @override
  Future<Exercise?> getLocalById(String id) {
    return localDataSource.getExerciseById(id);
  }

  @override
  Future<void> deleteLocal(String id) {
    return localDataSource.deleteExercise(id);
  }

  @override
  Future<List<Exercise>> getPendingSyncEntities() {
    return localDataSource.getPendingSyncExercises();
  }

  @override
  Future<Exercise> upsertRemote(Exercise entity) {
    return remoteDataSource.upsertExercise(entity);
  }

  @override
  Future<void> deleteRemote({
    required String localId,
    required String? serverId,
  }) {
    return remoteDataSource.deleteExercise(
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
  Future<void> persistAddedExercise(Exercise exercise) {
    return persistAdded(exercise);
  }

  @override
  Future<void> persistUpdatedExercise(Exercise exercise) {
    return persistUpdated(exercise);
  }

  @override
  Future<void> persistDeletedExercise(String id) {
    return persistDeleted(id);
  }
}