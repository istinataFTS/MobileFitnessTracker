import '../../core/enums/sync_entity_type.dart';
import '../../core/enums/sync_status.dart';
import '../../domain/entities/entity_sync_metadata.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/pending_sync_delete.dart';
import '../datasources/local/exercise_local_datasource.dart';
import '../datasources/local/pending_sync_delete_local_datasource.dart';
import '../datasources/remote/exercise_remote_datasource.dart';
import '../models/exercise_model.dart';
import 'exercise_sync_coordinator.dart';

class ExerciseSyncCoordinatorImpl implements ExerciseSyncCoordinator {
  final ExerciseLocalDataSource localDataSource;
  final ExerciseRemoteDataSource remoteDataSource;
  final PendingSyncDeleteLocalDataSource pendingSyncDeleteLocalDataSource;

  const ExerciseSyncCoordinatorImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.pendingSyncDeleteLocalDataSource,
  });

  @override
  bool get isRemoteSyncEnabled => remoteDataSource.isConfigured;

  @override
  Future<void> persistAddedExercise(Exercise exercise) async {
    final now = DateTime.now();

    final localExercise = exercise.copyWith(
      updatedAt: now,
      syncMetadata: exercise.syncMetadata.copyWith(
        status: isRemoteSyncEnabled
            ? SyncStatus.pendingUpload
            : SyncStatus.localOnly,
        clearLastSyncError: true,
      ),
    );

    await localDataSource.insertExercise(
      ExerciseModel.fromEntity(localExercise),
    );

    if (!isRemoteSyncEnabled) {
      return;
    }

    try {
      final remoteExercise = await remoteDataSource.upsertExercise(localExercise);
      await localDataSource.markAsSynced(
        localId: localExercise.id,
        serverId: remoteExercise.syncMetadata.serverId ?? remoteExercise.id,
        syncedAt: DateTime.now(),
      );
    } catch (error) {
      await localDataSource.markAsPendingUpload(
        localExercise.id,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<void> persistUpdatedExercise(Exercise exercise) async {
    final existingLocal = await localDataSource.getExerciseById(exercise.id);
    final wasPreviouslySynced = existingLocal?.syncMetadata.isSynced ?? false;

    final localExercise = exercise.copyWith(
      updatedAt: DateTime.now(),
      syncMetadata: EntitySyncMetadata(
        serverId: existingLocal?.syncMetadata.serverId ??
            exercise.syncMetadata.serverId,
        status: isRemoteSyncEnabled
            ? (wasPreviouslySynced
                ? SyncStatus.pendingUpdate
                : SyncStatus.pendingUpload)
            : SyncStatus.localOnly,
        lastSyncedAt: existingLocal?.syncMetadata.lastSyncedAt,
      ),
    );

    await localDataSource.updateExercise(
      ExerciseModel.fromEntity(localExercise),
    );

    if (!isRemoteSyncEnabled) {
      return;
    }

    try {
      final remoteExercise = await remoteDataSource.upsertExercise(localExercise);
      await localDataSource.markAsSynced(
        localId: localExercise.id,
        serverId: remoteExercise.syncMetadata.serverId ?? remoteExercise.id,
        syncedAt: DateTime.now(),
      );
    } catch (error) {
      if (wasPreviouslySynced) {
        await localDataSource.markAsPendingUpdate(
          localExercise.id,
          errorMessage: error.toString(),
        );
      } else {
        await localDataSource.markAsPendingUpload(
          localExercise.id,
          errorMessage: error.toString(),
        );
      }
    }
  }

  @override
  Future<void> persistDeletedExercise(String id) async {
    final existingLocal = await localDataSource.getExerciseById(id);
    if (existingLocal == null) {
      return;
    }

    if (_shouldQueueRemoteDelete(existingLocal)) {
      await pendingSyncDeleteLocalDataSource.enqueue(
        PendingSyncDelete(
          id: _buildDeleteOperationId(existingLocal.id),
          entityType: SyncEntityType.exercise,
          localEntityId: existingLocal.id,
          serverEntityId: existingLocal.syncMetadata.serverId,
          createdAt: DateTime.now(),
        ),
      );
    }

    await localDataSource.deleteExercise(id);

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

    final pendingExercises = await localDataSource.getPendingSyncExercises();

    for (final exercise in pendingExercises) {
      final remoteExercise = await remoteDataSource.upsertExercise(exercise);
      await localDataSource.markAsSynced(
        localId: exercise.id,
        serverId: remoteExercise.syncMetadata.serverId ?? remoteExercise.id,
        syncedAt: DateTime.now(),
      );
    }

    await _flushPendingDeletes();
  }

  Future<void> _flushPendingDeletes() async {
    final operations = await pendingSyncDeleteLocalDataSource
        .getPendingByEntityType(SyncEntityType.exercise);

    for (final operation in operations) {
      try {
        await remoteDataSource.deleteExercise(
          localId: operation.localEntityId,
          serverId: operation.serverEntityId,
        );
        await pendingSyncDeleteLocalDataSource.remove(operation.id);
      } catch (error) {
        await pendingSyncDeleteLocalDataSource.markAttempted(
          operation.id,
          attemptedAt: DateTime.now(),
          errorMessage: error.toString(),
        );
      }
    }
  }

  bool _shouldQueueRemoteDelete(Exercise exercise) {
    return exercise.syncMetadata.serverId != null ||
        exercise.syncMetadata.isSynced ||
        exercise.syncMetadata.hasPendingSync;
  }

  String _buildDeleteOperationId(String localEntityId) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'exercise_delete_${localEntityId}_$timestamp';
  }
}