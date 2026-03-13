import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
import '../../domain/entities/workout_set.dart';
import '../../domain/repositories/workout_set_repository.dart';
import '../datasources/local/workout_set_local_datasource.dart';

/// Implementation of WorkoutSetRepository.
/// Keeps repository error handling consistent via RepositoryGuard.
class WorkoutSetRepositoryImpl implements WorkoutSetRepository {
  final WorkoutSetLocalDataSource localDataSource;

  const WorkoutSetRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<WorkoutSet>>> getAllSets() {
    return RepositoryGuard.run(() async {
      return localDataSource.getAllSets();
    });
  }

  @override
  Future<Either<Failure, List<WorkoutSet>>> getSetsByExerciseId(
    String exerciseId,
  ) {
    return RepositoryGuard.run(() async {
      return localDataSource.getSetsByExerciseId(exerciseId);
    });
  }

  @override
  Future<Either<Failure, List<WorkoutSet>>> getSetsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return RepositoryGuard.run(() async {
      return localDataSource.getSetsByDateRange(startDate, endDate);
    });
  }

  @override
  Future<Either<Failure, void>> addSet(WorkoutSet set) {
    return RepositoryGuard.run(() async {
      await localDataSource.addSet(set);
    });
  }

  @override
  Future<Either<Failure, void>> updateSet(WorkoutSet set) {
    return RepositoryGuard.run(() async {
      await localDataSource.updateSet(set);
    });
  }

  @override
  Future<Either<Failure, void>> deleteSet(String id) {
    return RepositoryGuard.run(() async {
      await localDataSource.deleteSet(id);
    });
  }

  @override
  Future<Either<Failure, void>> clearAllSets() {
    return RepositoryGuard.run(() async {
      await localDataSource.clearAllSets();
    });
  }
}