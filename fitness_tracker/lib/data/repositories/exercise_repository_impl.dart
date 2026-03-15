import 'package:dartz/dartz.dart';

import '../../core/enums/data_source_preference.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
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
            await localDataSource.replaceAllExercises(
              remoteExercises.map(ExerciseModel.fromEntity).toList(),
            );
          }
          return remoteExercises;

        case DataSourcePreference.remoteThenLocal:
          if (remoteDataSource.isConfigured) {
            final remoteExercises = await remoteDataSource.getAllExercises();
            if (remoteExercises.isNotEmpty) {
              await localDataSource.replaceAllExercises(
                remoteExercises.map(ExerciseModel.fromEntity).toList(),
              );
              return remoteExercises;
            }
          }

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
            return localExercise;
          }

          if (!remoteDataSource.isConfigured) {
            return null;
          }

          final remoteExercise = await remoteDataSource.getExerciseById(id);
          if (remoteExercise != null) {
            await localDataSource.insertExercise(
              ExerciseModel.fromEntity(remoteExercise),
            );
          }
          return remoteExercise;

        case DataSourcePreference.remoteThenLocal:
          if (remoteDataSource.isConfigured) {
            final remoteExercise = await remoteDataSource.getExerciseById(id);
            if (remoteExercise != null) {
              final existingLocal = await localDataSource.getExerciseById(id);
              if (existingLocal == null) {
                await localDataSource.insertExercise(
                  ExerciseModel.fromEntity(remoteExercise),
                );
              } else {
                await localDataSource.updateExercise(
                  ExerciseModel.fromEntity(remoteExercise),
                );
              }
              return remoteExercise;
            }
          }

          return localDataSource.getExerciseById(id);
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
            return localExercise;
          }

          if (!remoteDataSource.isConfigured) {
            return null;
          }

          final remoteExercise = await remoteDataSource.getExerciseByName(name);
          if (remoteExercise != null) {
            await localDataSource.insertExercise(
              ExerciseModel.fromEntity(remoteExercise),
            );
          }
          return remoteExercise;

        case DataSourcePreference.remoteThenLocal:
          if (remoteDataSource.isConfigured) {
            final remoteExercise = await remoteDataSource.getExerciseByName(name);
            if (remoteExercise != null) {
              final existingLocal = await localDataSource.getExerciseById(
                remoteExercise.id,
              );
              if (existingLocal == null) {
                await localDataSource.insertExercise(
                  ExerciseModel.fromEntity(remoteExercise),
                );
              } else {
                await localDataSource.updateExercise(
                  ExerciseModel.fromEntity(remoteExercise),
                );
              }
              return remoteExercise;
            }
          }

          return localDataSource.getExerciseByName(name);
      }
    });
  }

  @override
  Future<Either<Failure, List<Exercise>>> getExercisesForMuscle(
    String muscleGroup, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      switch (sourcePreference) {
        case DataSourcePreference.localOnly:
          return localDataSource.getExercisesForMuscle(muscleGroup);

        case DataSourcePreference.remoteOnly:
          if (!remoteDataSource.isConfigured) {
            return const <Exercise>[];
          }
          return remoteDataSource.getExercisesForMuscle(muscleGroup);

        case DataSourcePreference.localThenRemote:
          final localExercises =
              await localDataSource.getExercisesForMuscle(muscleGroup);
          if (localExercises.isNotEmpty || !remoteDataSource.isConfigured) {
            return localExercises;
          }

          return remoteDataSource.getExercisesForMuscle(muscleGroup);

        case DataSourcePreference.remoteThenLocal:
          if (remoteDataSource.isConfigured) {
            final remoteExercises =
                await remoteDataSource.getExercisesForMuscle(muscleGroup);
            if (remoteExercises.isNotEmpty) {
              return remoteExercises;
            }
          }

          return localDataSource.getExercisesForMuscle(muscleGroup);
      }
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