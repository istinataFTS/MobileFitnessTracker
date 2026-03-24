import 'package:dartz/dartz.dart';

import '../../core/enums/data_source_preference.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
import '../../core/sync/local_remote_merge.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../datasources/local/exercise_local_datasource.dart';
import '../datasources/remote/exercise_remote_datasource.dart';
import '../models/exercise_model.dart';
import '../sync/exercise_sync_coordinator.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  final ExerciseLocalDataSource localDataSource;
  final ExerciseRemoteDataSource remoteDataSource;
  final ExerciseSyncCoordinator syncCoordinator;

  static final LocalRemoteMerge<Exercise> _merge =
      LocalRemoteMerge<Exercise>(
    getId: (exercise) => exercise.id,
    getUpdatedAt: (exercise) => exercise.updatedAt,
    getSyncMetadata: (exercise) => exercise.syncMetadata,
  );

  const ExerciseRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.syncCoordinator,
  });

  @override
  Future<Either<Failure, List<Exercise>>> getAllExercises({
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      switch (sourcePreference) {
        case DataSourcePreference.localOnly:
          return localDataSource.getAllExercises();

        case DataSourcePreference.remoteOnly:
          if (!remoteDataSource.isConfigured) {
            return const <Exercise>[];
          }
          return remoteDataSource.getAllExercises();

        case DataSourcePreference.localThenRemote:
          final localExercises = await localDataSource.getAllExercises();
          if (localExercises.isNotEmpty || !remoteDataSource.isConfigured) {
            return localExercises;
          }

          final remoteExercises = await remoteDataSource.getAllExercises();
          if (remoteExercises.isNotEmpty) {
            await localDataSource.mergeRemoteExercises(
              remoteExercises.map(ExerciseModel.fromEntity).toList(),
            );
          }
          return localDataSource.getAllExercises();

        case DataSourcePreference.remoteThenLocal:
          if (!remoteDataSource.isConfigured) {
            return localDataSource.getAllExercises();
          }

          final localExercises = await localDataSource.getAllExercises();
          final remoteExercises = await remoteDataSource.getAllExercises();

          if (remoteExercises.isEmpty) {
            return localExercises;
          }

          final merged = _merge.mergeLists(
            localItems: localExercises,
            remoteItems: remoteExercises,
          );

          await localDataSource.mergeRemoteExercises(
            merged.map(ExerciseModel.fromEntity).toList(),
          );

          return localDataSource.getAllExercises();
      }
    });
  }

  @override
  Future<Either<Failure, Exercise?>> getExerciseById(
    String id, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      switch (sourcePreference) {
        case DataSourcePreference.localOnly:
          return localDataSource.getExerciseById(id);

        case DataSourcePreference.remoteOnly:
          if (!remoteDataSource.isConfigured) {
            return null;
          }
          return remoteDataSource.getExerciseById(id);

        case DataSourcePreference.localThenRemote:
          final localExercise = await localDataSource.getExerciseById(id);
          if (localExercise != null) {
            return localExercise.syncMetadata.isPendingDelete
                ? null
                : localExercise;
          }

          if (!remoteDataSource.isConfigured) {
            return null;
          }

          final remoteExercise = await remoteDataSource.getExerciseById(id);
          if (remoteExercise != null) {
            await localDataSource.upsertExercise(
              ExerciseModel.fromEntity(remoteExercise),
            );
          }
          return remoteExercise;

        case DataSourcePreference.remoteThenLocal:
          if (!remoteDataSource.isConfigured) {
            return localDataSource.getExerciseById(id);
          }

          final localExercise = await localDataSource.getExerciseById(id);
          final remoteExercise = await remoteDataSource.getExerciseById(id);

          if (remoteExercise == null) {
            if (localExercise == null ||
                localExercise.syncMetadata.isPendingDelete) {
              return null;
            }
            return localExercise;
          }

          if (localExercise == null) {
            await localDataSource.upsertExercise(
              ExerciseModel.fromEntity(remoteExercise),
            );
            return remoteExercise;
          }

          final merged = _merge.chooseWinner(
            local: localExercise,
            remote: remoteExercise,
          );

          await localDataSource.upsertExercise(
            ExerciseModel.fromEntity(merged),
          );

          return merged.syncMetadata.isPendingDelete ? null : merged;
      }
    });
  }

  @override
  Future<Either<Failure, Exercise?>> getExerciseByName(
    String name, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      switch (sourcePreference) {
        case DataSourcePreference.localOnly:
          return localDataSource.getExerciseByName(name);

        case DataSourcePreference.remoteOnly:
          if (!remoteDataSource.isConfigured) {
            return null;
          }
          return remoteDataSource.getExerciseByName(name);

        case DataSourcePreference.localThenRemote:
          final localExercise = await localDataSource.getExerciseByName(name);
          if (localExercise != null) {
            return localExercise.syncMetadata.isPendingDelete
                ? null
                : localExercise;
          }

          if (!remoteDataSource.isConfigured) {
            return null;
          }

          final remoteExercise = await remoteDataSource.getExerciseByName(name);
          if (remoteExercise != null) {
            await localDataSource.upsertExercise(
              ExerciseModel.fromEntity(remoteExercise),
            );
          }
          return remoteExercise;

        case DataSourcePreference.remoteThenLocal:
          if (!remoteDataSource.isConfigured) {
            return localDataSource.getExerciseByName(name);
          }

          final localExercise = await localDataSource.getExerciseByName(name);
          final remoteExercise = await remoteDataSource.getExerciseByName(name);

          if (remoteExercise == null) {
            if (localExercise == null ||
                localExercise.syncMetadata.isPendingDelete) {
              return null;
            }
            return localExercise;
          }

          if (localExercise == null) {
            await localDataSource.upsertExercise(
              ExerciseModel.fromEntity(remoteExercise),
            );
            return remoteExercise;
          }

          final merged = _merge.chooseWinner(
            local: localExercise,
            remote: remoteExercise,
          );

          await localDataSource.upsertExercise(
            ExerciseModel.fromEntity(merged),
          );

          return merged.syncMetadata.isPendingDelete ? null : merged;
      }
    });
  }

  @override
  Future<Either<Failure, List<Exercise>>> getExercisesForMuscle(
    String muscleGroup, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      if (sourcePreference == DataSourcePreference.localOnly ||
          !remoteDataSource.isConfigured) {
        return localDataSource.getExercisesForMuscle(muscleGroup);
      }

      final exercises = await getAllExercises(sourcePreference: sourcePreference);
      return exercises.fold(
        (_) => const <Exercise>[],
        (items) => items
            .where((exercise) => exercise.muscleGroups.contains(muscleGroup))
            .toList(),
      );
    });
  }

  @override
  Future<Either<Failure, void>> addExercise(Exercise exercise) {
    return RepositoryGuard.run(() async {
      await syncCoordinator.persistAddedExercise(exercise);
    });
  }

  @override
  Future<Either<Failure, void>> updateExercise(Exercise exercise) {
    return RepositoryGuard.run(() async {
      await syncCoordinator.persistUpdatedExercise(exercise);
    });
  }

  @override
  Future<Either<Failure, void>> deleteExercise(String id) {
    return RepositoryGuard.run(() async {
      await syncCoordinator.persistDeletedExercise(id);
    });
  }

  @override
  Future<Either<Failure, void>> clearAllExercises() {
    return RepositoryGuard.run(() async {
      await localDataSource.clearAllExercises();
    });
  }

  @override
  Future<Either<Failure, void>> syncPendingExercises() {
    return RepositoryGuard.run(() async {
      await syncCoordinator.syncPendingChanges();
    });
  }
}