import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/muscle_factor.dart';
import '../../domain/repositories/muscle_factor_repository.dart';
import '../datasources/local/muscle_factor_local_datasource.dart';
import '../models/muscle_factor_model.dart';

/// Implementation of MuscleFactorRepository
class MuscleFactorRepositoryImpl implements MuscleFactorRepository {
  final MuscleFactorLocalDataSource localDataSource;

  MuscleFactorRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, MuscleFactor?>> getFactorById(String id) async {
    try {
      final factorMap = await localDataSource.getFactorById(id);
      if (factorMap == null) {
        return const Right(null);
      }
      final factor = MuscleFactorModel.fromMap(factorMap);
      return Right(factor);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MuscleFactor>>> getAllFactors() async {
    try {
      final factorMaps = await localDataSource.getAllFactors();
      final factors = factorMaps
          .map((map) => MuscleFactorModel.fromMap(map))
          .toList();
      return Right(factors);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MuscleFactor>>> getFactorsForExercise(
    String exerciseId,
  ) async {
    try {
      final factorMaps = await localDataSource.getFactorsForExercise(exerciseId);
      final factors = factorMaps
          .map((map) => MuscleFactorModel.fromMap(map))
          .toList();
      return Right(factors);
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
      await localDataSource.addFactor(model);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addMuscleFactorsBatch(
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
  Future<Either<Failure, void>> updateMuscleFactor(MuscleFactor factor) async {
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
  Future<Either<Failure, void>> deleteMuscleFactor(String id) async {
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
  Future<Either<Failure, void>> deleteMuscleFactorsByExerciseId(
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
}