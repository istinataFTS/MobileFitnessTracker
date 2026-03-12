import 'package:dartz/dartz.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/target.dart';
import '../../domain/repositories/target_repository.dart';
import '../datasources/local/target_local_datasource.dart';
import '../models/target_model.dart';

class TargetRepositoryImpl implements TargetRepository {
  final TargetLocalDataSource localDataSource;

  const TargetRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Target>>> getAllTargets() async {
    try {
      final targets = await localDataSource.getAllTargets();
      return Right(targets);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Target?>> getTargetById(String id) async {
    try {
      final target = await localDataSource.getTargetById(id);
      return Right(target);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Target?>> getTargetByTypeAndCategory(
    TargetType type,
    String categoryKey,
    TargetPeriod period,
  ) async {
    try {
      final target = await localDataSource.getTargetByTypeAndCategory(
        type,
        categoryKey,
        period,
      );
      return Right(target);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addTarget(Target target) async {
    try {
      final model = TargetModel.fromEntity(target);
      await localDataSource.insertTarget(model);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTarget(Target target) async {
    try {
      final model = TargetModel.fromEntity(target);
      await localDataSource.updateTarget(model);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTarget(String targetId) async {
    try {
      await localDataSource.deleteTarget(targetId);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllTargets() async {
    try {
      await localDataSource.clearAllTargets();
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }
}