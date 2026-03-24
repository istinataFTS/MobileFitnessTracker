import '../../core/enums/sync_entity_type.dart';
import '../../core/enums/sync_status.dart';
import '../../domain/entities/entity_sync_metadata.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/pending_sync_delete.dart';
import '../datasources/local/meal_local_datasource.dart';
import '../datasources/local/pending_sync_delete_local_datasource.dart';
import '../datasources/remote/meal_remote_datasource.dart';
import '../models/meal_model.dart';
import 'meal_sync_coordinator.dart';

class MealSyncCoordinatorImpl implements MealSyncCoordinator {
  final MealLocalDataSource localDataSource;
  final MealRemoteDataSource remoteDataSource;
  final PendingSyncDeleteLocalDataSource pendingSyncDeleteLocalDataSource;

  const MealSyncCoordinatorImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.pendingSyncDeleteLocalDataSource,
  });

  @override
  bool get isRemoteSyncEnabled => remoteDataSource.isConfigured;

  @override
  Future<void> persistAddedMeal(Meal meal) async {
    final now = DateTime.now();

    final localMeal = meal.copyWith(
      updatedAt: now,
      syncMetadata: meal.syncMetadata.copyWith(
        status: isRemoteSyncEnabled
            ? SyncStatus.pendingUpload
            : SyncStatus.localOnly,
        clearLastSyncError: true,
      ),
    );

    final model = MealModel.fromEntity(localMeal);
    model.validateMacros();
    model.validateAndLogCalories();
    await localDataSource.insertMeal(model);

    if (!isRemoteSyncEnabled) {
      return;
    }

    try {
      final remoteMeal = await remoteDataSource.upsertMeal(localMeal);
      await localDataSource.markAsSynced(
        localId: localMeal.id,
        serverId: remoteMeal.syncMetadata.serverId ?? remoteMeal.id,
        syncedAt: DateTime.now(),
      );
    } catch (error) {
      await localDataSource.markAsPendingUpload(
        localMeal.id,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<void> persistUpdatedMeal(Meal meal) async {
    final existingLocal = await localDataSource.getMealById(meal.id);
    final wasPreviouslySynced = existingLocal?.syncMetadata.isSynced ?? false;

    final localMeal = meal.copyWith(
      updatedAt: DateTime.now(),
      syncMetadata: EntitySyncMetadata(
        serverId: existingLocal?.syncMetadata.serverId ??
            meal.syncMetadata.serverId,
        status: isRemoteSyncEnabled
            ? (wasPreviouslySynced
                ? SyncStatus.pendingUpdate
                : SyncStatus.pendingUpload)
            : SyncStatus.localOnly,
        lastSyncedAt: existingLocal?.syncMetadata.lastSyncedAt,
      ),
    );

    final model = MealModel.fromEntity(localMeal);
    model.validateMacros();
    model.validateAndLogCalories();
    await localDataSource.updateMeal(model);

    if (!isRemoteSyncEnabled) {
      return;
    }

    try {
      final remoteMeal = await remoteDataSource.upsertMeal(localMeal);
      await localDataSource.markAsSynced(
        localId: localMeal.id,
        serverId: remoteMeal.syncMetadata.serverId ?? remoteMeal.id,
        syncedAt: DateTime.now(),
      );
    } catch (error) {
      if (wasPreviouslySynced) {
        await localDataSource.markAsPendingUpdate(
          localMeal.id,
          errorMessage: error.toString(),
        );
      } else {
        await localDataSource.markAsPendingUpload(
          localMeal.id,
          errorMessage: error.toString(),
        );
      }
    }
  }

  @override
  Future<void> persistDeletedMeal(String id) async {
    final existingLocal = await localDataSource.getMealById(id);
    if (existingLocal == null) {
      return;
    }

    final shouldQueueDelete = _shouldQueueRemoteDelete(existingLocal);

    if (shouldQueueDelete) {
      await pendingSyncDeleteLocalDataSource.enqueue(
        PendingSyncDelete(
          id: _buildDeleteOperationId(existingLocal.id),
          entityType: SyncEntityType.meal,
          localEntityId: existingLocal.id,
          serverEntityId: existingLocal.syncMetadata.serverId,
          createdAt: DateTime.now(),
        ),
      );

      await localDataSource.markAsPendingDelete(existingLocal.id);
    } else {
      await localDataSource.deleteMeal(id);
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

    final pendingMeals = await localDataSource.getPendingSyncMeals();

    for (final meal in pendingMeals) {
      if (meal.syncMetadata.status == SyncStatus.pendingDelete) {
        continue;
      }

      final remoteMeal = await remoteDataSource.upsertMeal(meal);
      await localDataSource.markAsSynced(
        localId: meal.id,
        serverId: remoteMeal.syncMetadata.serverId ?? remoteMeal.id,
        syncedAt: DateTime.now(),
      );
    }

    await _flushPendingDeletes();
  }

  Future<void> _flushPendingDeletes() async {
    final operations = await pendingSyncDeleteLocalDataSource
        .getPendingByEntityType(SyncEntityType.meal);

    for (final operation in operations) {
      try {
        await remoteDataSource.deleteMeal(
          localId: operation.localEntityId,
          serverId: operation.serverEntityId,
        );
        await pendingSyncDeleteLocalDataSource.remove(operation.id);
        await localDataSource.deleteMeal(operation.localEntityId);
      } catch (error) {
        await pendingSyncDeleteLocalDataSource.markAttempted(
          operation.id,
          attemptedAt: DateTime.now(),
          errorMessage: error.toString(),
        );
      }
    }
  }

  bool _shouldQueueRemoteDelete(Meal meal) {
    return meal.syncMetadata.serverId != null ||
        meal.syncMetadata.isSynced ||
        meal.syncMetadata.hasPendingSync;
  }

  String _buildDeleteOperationId(String localEntityId) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'meal_delete_${localEntityId}_$timestamp';
  }
}