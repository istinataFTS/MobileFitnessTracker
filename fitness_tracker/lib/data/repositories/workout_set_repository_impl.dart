import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/workout_set.dart';
import '../../domain/repositories/workout_set_repository.dart';
import '../datasources/local/workout_set_local_datasource.dart';
import '../models/workout_set_model.dart';

class WorkoutSetRepositoryImpl implements WorkoutSetRepository {
  final WorkoutSetLocalDataSource localDataSource;

  const WorkoutSetRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<WorkoutSet>>> getAllSets() async {
    try {
      final sets = await localDataSource.getAllSets();
      return Right(sets);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<WorkoutSet>>> getSetsByMuscleGroup(
    String muscleGroup,
  ) async {
    try {
      final sets = await localDataSource.getSetsByMuscleGroup(muscleGroup);
      return Right(sets);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<WorkoutSet>>> getSetsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final sets = await localDataSource.getSetsByDateRange(startDate, endDate);
      return Right(sets);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addSet(WorkoutSet set) async {
    try {
      final model = WorkoutSetModel.fromEntity(set);
      await localDataSource.insertSet(model);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSet(String id) async {
    try {
      await localDataSource.deleteSet(id);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllSets() async {
    try {
      await localDataSource.clearAllSets();
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }
}