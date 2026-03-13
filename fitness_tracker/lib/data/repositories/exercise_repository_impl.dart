import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../datasources/local/exercise_local_datasource.dart';
import '../models/exercise_model.dart';

/// Repository implementation for Exercise operations.
/// Keeps error handling consistent via RepositoryGuard and stays storage-agnostic.
class ExerciseRepositoryImpl implements ExerciseRepository {
  final ExerciseLocalDataSource localDataSource;

  const ExerciseRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Exercise>>> getAllExercises() {
    return RepositoryGuard.run(() async {
      return localDataSource.getAllExercises();
    });
  }

  @override
  Future<Either<Failure, Exercise?>> getExerciseById(String id) {
    return RepositoryGuard.run(() async {
      return localDataSource.getExerciseById(id);
    });
  }

  @override
  Future<Either<Failure, Exercise?>> getExerciseByName(String name) {
    return RepositoryGuard.run(() async {
      return localDataSource.getExerciseByName(name);
    });
  }

  @override
  Future<Either<Failure, List<Exercise>>> getExercisesForMuscle(
    String muscleGroup,
  ) {
    return RepositoryGuard.run(() async {
      return localDataSource.getExercisesForMuscle(muscleGroup);
    });
  }

  @override
  Future<Either<Failure, void>> addExercise(Exercise exercise) {
    return RepositoryGuard.run(() async {
      final model = ExerciseModel.fromEntity(exercise);
      await localDataSource.insertExercise(model);
    });
  }

  @override
  Future<Either<Failure, void>> updateExercise(Exercise exercise) {
    return RepositoryGuard.run(() async {
      final model = ExerciseModel.fromEntity(exercise);
      await localDataSource.updateExercise(model);
    });
  }

  @override
  Future<Either<Failure, void>> deleteExercise(String id) {
    return RepositoryGuard.run(() async {
      await localDataSource.deleteExercise(id);
    });
  }

  @override
  Future<Either<Failure, void>> clearAllExercises() {
    return RepositoryGuard.run(() async {
      await localDataSource.clearAllExercises();
    });
  }
}