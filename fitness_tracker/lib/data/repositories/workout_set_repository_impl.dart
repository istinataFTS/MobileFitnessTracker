import 'package:dartz/dartz.dart';

import '../../core/enums/data_source_preference.dart';
import '../../core/enums/sync_status.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
import '../../domain/entities/entity_sync_metadata.dart';
import '../../domain/entities/workout_set.dart';
import '../../domain/repositories/workout_set_repository.dart';
import '../datasources/local/workout_set_local_datasource.dart';
import '../datasources/remote/workout_set_remote_datasource.dart';

class WorkoutSetRepositoryImpl implements WorkoutSetRepository {
  final WorkoutSetLocalDataSource localDataSource;
  final WorkoutSetRemoteDataSource remoteDataSource;

  const WorkoutSetRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<WorkoutSet>>> getAllSets({
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      return _readAllSets(sourcePreference);
    });
  }

  @override
  Future<Either<Failure, WorkoutSet?>> getSetById(
    String id, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      switch (sourcePreference) {
        case DataSourcePreference.localOnly:
          return localDataSource.getSetById(id);

        case DataSourcePreference.remoteOnly:
          if (!remoteDataSource.isConfigured) {
            return null;
          }
          return remoteDataSource.getSetById(id);

        case DataSourcePreference.localThenRemote:
          final local = await localDataSource.getSetById(id);
          if (local != null) {
            return local;
          }

          if (!remoteDataSource.isConfigured) {
            return null;
          }

          final remote = await remoteDataSource.getSetById(id);
          if (remote != null) {
            await localDataSource.addSet(remote);
          }
          return remote;

        case DataSourcePreference.remoteThenLocal:
          if (remoteDataSource.isConfigured) {
            final remote = await remoteDataSource.getSetById(id);
            if (remote != null) {
              final existingLocal = await localDataSource.getSetById(id);
              if (existingLocal == null) {
                await localDataSource.addSet(remote);
              } else {
                await localDataSource.updateSet(remote);
              }
              return remote;
            }
          }

          return localDataSource.getSetById(id);
      }
    });
  }

  @override
  Future<Either<Failure, List<WorkoutSet>>> getSetsByExerciseId(
    String exerciseId, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      if (sourcePreference == DataSourcePreference.localOnly ||
          !remoteDataSource.isConfigured) {
        return localDataSource.getSetsByExerciseId(exerciseId);
      }

      final sets = await _readAllSets(sourcePreference);
      return sets.where((set) => set.exerciseId == exerciseId).toList();
    });
  }

  @override
  Future<Either<Failure, List<WorkoutSet>>> getSetsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      if (sourcePreference == DataSourcePreference.localOnly ||
          !remoteDataSource.isConfigured) {
        return localDataSource.getSetsByDateRange(startDate, endDate);
      }

      final sets = await _readAllSets(sourcePreference);
      return sets.where((set) {
        return !set.date.isBefore(startDate) && !set.date.isAfter(endDate);
      }).toList();
    });
  }

  @override
  Future<Either<Failure, void>> addSet(WorkoutSet set) {
    return RepositoryGuard.run(() async {
      final now = DateTime.now();

      final localSet = set.copyWith(
        updatedAt: now,
        syncMetadata: set.syncMetadata.copyWith(
          status: remoteDataSource.isConfigured
              ? SyncStatus.pendingUpload
              : SyncStatus.localOnly,
          clearLastSyncError: true,
        ),
      );

      await localDataSource.addSet(localSet);

      if (!remoteDataSource.isConfigured) {
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
    });
  }

  @override
  Future<Either<Failure, void>> updateSet(WorkoutSet set) {
    return RepositoryGuard.run(() async {
      final existingLocal = await localDataSource.getSetById(set.id);
      final wasPreviouslySynced = existingLocal?.syncMetadata.isSynced ?? false;

      final localSet = set.copyWith(
        updatedAt: DateTime.now(),
        syncMetadata: EntitySyncMetadata(
          serverId: existingLocal?.syncMetadata.serverId ?? set.syncMetadata.serverId,
          status: remoteDataSource.isConfigured
              ? (wasPreviouslySynced
                  ? SyncStatus.pendingUpdate
                  : SyncStatus.pendingUpload)
              : SyncStatus.localOnly,
          lastSyncedAt: existingLocal?.syncMetadata.lastSyncedAt,
        ),
      );

      await localDataSource.updateSet(localSet);

      if (!remoteDataSource.isConfigured) {
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
    });
  }

  @override
  Future<Either<Failure, void>> deleteSet(String id) {
    return RepositoryGuard.run(() async {
      await localDataSource.deleteSet(id);

      if (remoteDataSource.isConfigured) {
        try {
          await remoteDataSource.deleteSet(id);
        } catch (_) {
          // Intentionally ignored for now.
          // A later slice should introduce delete tombstones for reliable remote sync.
        }
      }
    });
  }

  @override
  Future<Either<Failure, void>> clearAllSets() {
    return RepositoryGuard.run(() async {
      await localDataSource.clearAllSets();
    });
  }

  @override
  Future<Either<Failure, void>> syncPendingSets() {
    return RepositoryGuard.run(() async {
      if (!remoteDataSource.isConfigured) {
        return;
      }

      final pendingSets = await localDataSource.getPendingSyncSets();

      for (final set in pendingSets) {
        final remoteSet = await remoteDataSource.upsertSet(set);
        await localDataSource.markAsSynced(
          localId: set.id,
          serverId: remoteSet.syncMetadata.serverId ?? remoteSet.id,
          syncedAt: DateTime.now(),
        );
      }
    });
  }

  Future<List<WorkoutSet>> _readAllSets(
    DataSourcePreference sourcePreference,
  ) async {
    switch (sourcePreference) {
      case DataSourcePreference.localOnly:
        return localDataSource.getAllSets();

      case DataSourcePreference.remoteOnly:
        if (!remoteDataSource.isConfigured) {
          return const <WorkoutSet>[];
        }

        return remoteDataSource.getAllSets();

      case DataSourcePreference.localThenRemote:
        final local = await localDataSource.getAllSets();
        if (local.isNotEmpty || !remoteDataSource.isConfigured) {
          return local;
        }

        final remote = await remoteDataSource.getAllSets();
        if (remote.isNotEmpty) {
          await localDataSource.replaceAll(remote);
        }
        return remote;

      case DataSourcePreference.remoteThenLocal:
        if (remoteDataSource.isConfigured) {
          final remote = await remoteDataSource.getAllSets();
          if (remote.isNotEmpty) {
            await localDataSource.replaceAll(remote);
            return remote;
          }
        }

        return localDataSource.getAllSets();
    }
  }
}