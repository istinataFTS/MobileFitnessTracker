import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/muscle_factor.dart';
import '../../domain/repositories/muscle_factor_repository.dart';
import '../datasources/local/muscle_factor_local_datasource.dart';
import '../models/muscle_factor_model.dart';

/// Repository implementation for MuscleFactor operations
/// Implements domain layer interface using data layer datasources
/// 
/// MuscleFactor represents the contribution factor of an exercise to a muscle group
/// (e.g., bench press might be 1.0 for chest, 0.6 for triceps, 0.3 for front delts)
class MuscleFactorRepositoryImpl implements MuscleFactorRepository {
  final MuscleFactorLocalDataSource localDataSource;

  const MuscleFactorRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<MuscleFactor>>> getFactorsByExerciseId(
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
  Future<Either<Failure, List<MuscleFactor>>> getFactorsByMuscleGroup(
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
  Future<Either<Failure, void>> addFactor(MuscleFactor factor) async {
    try {
      final model = MuscleFactorModel.fromEntity(factor);
      await localDataSource.addFactor(model);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addFactorsBatch(
    List<MuscleFactor> factors,
  ) async {
    try {
      final models = factors
          .map((factor) => MuscleFactorModel.fromEntity(factor))
          .toList();
      await localDataSource.addFactorsBatch(models);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateFactor(MuscleFactor factor) async {
    try {
      final model = MuscleFactorModel.fromEntity(factor);
      await localDataSource.updateFactor(model);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFactor(String id) async {
    try {
      await localDataSource.deleteFactor(id);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFactorsByExerciseId(
    String exerciseId,
  ) async {
    try {
      await localDataSource.deleteFactorsByExerciseId(exerciseId);
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