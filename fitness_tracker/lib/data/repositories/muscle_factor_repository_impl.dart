import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/muscle_factor.dart';
import '../../domain/repositories/muscle_factor_repository.dart';
import '../datasources/local/muscle_factor_local_datasource.dart';
import '../models/muscle_factor_model.dart';

/// Repository implementation for MuscleFactor operations
/// 
/// Converts between domain entities and data models
/// Handles error conversion (exceptions → failures)
class MuscleFactorRepositoryImpl implements MuscleFactorRepository {
  final MuscleFactorLocalDataSource localDataSource;

  const MuscleFactorRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<MuscleFactor>>> getFactorsForExercise(
    String exerciseId,
  ) async {
    try {
      final factors = await localDataSource.getFactorsForExercise(exerciseId);
      return Right(factors);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MuscleFactor>>> getFactorsForMuscle(
    String muscleGroup,
  ) async {
    try {
      final factors = await localDataSource.getFactorsForMuscle(muscleGroup);
      return Right(factors);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MuscleFactor>>> getAllFactors() async {
    try {
      final factors = await localDataSource.getAllFactors();
      return Right(factors);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, MuscleFactor?>> getFactorById(String id) async {
    try {
      final factor = await localDataSource.getFactorById(id);
      return Right(factor);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addMuscleFactor(MuscleFactor factor) async {
    try {
      final model = MuscleFactorModel.fromEntity(factor);
      await localDataSource.insertMuscleFactor(model);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addMuscleFactorsBatch(List<MuscleFactor> factors) async {
    try {
      final models = factors
          .map((factor) => MuscleFactorModel.fromEntity(factor))
          .toList();
      await localDataSource.insertMuscleFactorsBatch(models);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateMuscleFactor(MuscleFactor factor) async {
    try {
      final model = MuscleFactorModel.fromEntity(factor);
      await localDataSource.updateMuscleFactor(model);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMuscleFactor(String id) async {
    try {
      await localDataSource.deleteMuscleFactor(id);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFactorsForExercise(String exerciseId) async {
    try {
      await localDataSource.deleteFactorsForExercise(exerciseId);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllFactors() async {
    try {
      await localDataSource.clearAllFactors();
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }
}