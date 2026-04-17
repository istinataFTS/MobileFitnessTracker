import '../../core/enums/sync_entity_type.dart';
import '../../domain/entities/entity_sync_metadata.dart';
import '../../domain/entities/meal.dart';
import '../datasources/local/meal_local_datasource.dart';
import '../datasources/remote/meal_remote_datasource.dart';
import '../models/meal_model.dart';
import 'base_entity_sync_coordinator.dart';
import 'entity_sync_descriptor.dart';
import 'meal_sync_coordinator.dart';

class MealSyncCoordinatorImpl extends BaseEntitySyncCoordinator<Meal>
    implements MealSyncCoordinator {
  static const EntitySyncDescriptor _descriptor = EntitySyncDescriptor(
    entityType: SyncEntityType.meal,
    operationKey: 'meal',
    entityLabel: 'meal',
  );

  final MealLocalDataSource localDataSource;
  final MealRemoteDataSource remoteDataSource;

  const MealSyncCoordinatorImpl({
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
  String getEntityId(Meal entity) => entity.id;

  @override
  EntitySyncMetadata getSyncMetadata(Meal entity) => entity.syncMetadata;

  @override
  Meal buildAddedLocalEntity(Meal entity, DateTime now) {
    return entity.copyWith(
      updatedAt: now,
      syncMetadata: buildAddedSyncMetadata(entity.syncMetadata),
    );
  }

  @override
  Meal buildUpdatedLocalEntity({
    required Meal entity,
    required Meal? existingLocal,
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
  Future<void> insertLocal(Meal entity) {
    final model = MealModel.fromEntity(entity);
    model.validateMacros();
    model.validateAndLogCalories();
    return localDataSource.insertMeal(model);
  }

  @override
  Future<void> updateLocal(Meal entity) {
    final model = MealModel.fromEntity(entity);
    model.validateMacros();
    model.validateAndLogCalories();
    return localDataSource.updateMeal(model);
  }

  @override
  Future<Meal?> getLocalById(String id) {
    return localDataSource.getMealById(id);
  }

  @override
  Future<void> deleteLocal(String id) {
    return localDataSource.deleteMeal(id);
  }

  @override
  Future<List<Meal>> getPendingSyncEntities() {
    return localDataSource.getPendingSyncMeals();
  }

  @override
  Future<Meal> upsertRemote(Meal entity) {
    return remoteDataSource.upsertMeal(entity);
  }

  @override
  Future<void> deleteRemote({
    required String localId,
    required String? serverId,
  }) {
    return remoteDataSource.deleteMeal(
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
  Future<List<Meal>> fetchSince({
    required String userId,
    DateTime? since,
  }) {
    return remoteDataSource.fetchSince(userId: userId, since: since);
  }

  @override
  Future<void> persistAddedMeal(Meal meal) {
    return persistAdded(meal);
  }

  @override
  Future<void> persistUpdatedMeal(Meal meal) {
    return persistUpdated(meal);
  }

  @override
  Future<void> persistDeletedMeal(String id) {
    return persistDeleted(id);
  }
}
