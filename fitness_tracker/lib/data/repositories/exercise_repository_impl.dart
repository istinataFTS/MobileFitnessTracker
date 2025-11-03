import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../datasources/local/exercise_local_datasource.dart';
import '../models/exercise_model.dart';

/// Repository implementation for Exercise operations
/// Implements domain layer interface using data layer datasources
class ExerciseRepositoryImpl implements ExerciseRepository {
  final ExerciseLocalDataSource localDataSource;

  const ExerciseRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Exercise>>> getAllExercises() async {
    try {
      final exercises = await localDataSource.getAllExercises();
      return Right(exercises);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Exercise?>> getExerciseById(String id) async {
    try {
      final exercise = await localDataSource.getExerciseById(id);
      return Right(exercise);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Exercise?>> getExerciseByName(String name) async {
    try {
      final exercise = await localDataSource.getExerciseByName(name);
      return Right(exercise);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Exercise>>> getExercisesForMuscle(
    String muscleGroup,
  ) async {
    try {
      final exercises = await localDataSource.getExercisesForMuscle(muscleGroup);
      return Right(exercises);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addExercise(Exercise exercise) async {
    try {
      final model = ExerciseModel.fromEntity(exercise);
      await localDataSource.insertExercise(model);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateExercise(Exercise exercise) async {
    try {
      final model = ExerciseModel.fromEntity(exercise);
      await localDataSource.updateExercise(model);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExercise(String id) async {
    try {
      await localDataSource.deleteExercise(id);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllExercises() async {
    try {
      await localDataSource.clearAllExercises();
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }
}
