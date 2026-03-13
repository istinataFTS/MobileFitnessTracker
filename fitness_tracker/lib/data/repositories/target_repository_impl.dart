import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
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
  Future<Either<Failure, List<Target>>> getAllTargets() {
    return RepositoryGuard.run(() async {
      return localDataSource.getAllTargets();
    });
  }

  @override
  Future<Either<Failure, Target?>> getTargetById(String id) {
    return RepositoryGuard.run(() async {
      return localDataSource.getTargetById(id);
    });
  }

  @override
  Future<Either<Failure, Target?>> getTargetByTypeAndCategory(
    TargetType type,
    String categoryKey,
    TargetPeriod period,
  ) {
    return RepositoryGuard.run(() async {
      return localDataSource.getTargetByTypeAndCategory(
        type,
        categoryKey,
        period,
      );
    });
  }

  @override
  Future<Either<Failure, void>> addTarget(Target target) {
    return RepositoryGuard.run(() async {
      final model = TargetModel.fromEntity(target);
      await localDataSource.insertTarget(model);
    });
  }

  @override
  Future<Either<Failure, void>> updateTarget(Target target) {
    return RepositoryGuard.run(() async {
      final model = TargetModel.fromEntity(target);
      await localDataSource.updateTarget(model);
    });
  }

  @override
  Future<Either<Failure, void>> deleteTarget(String targetId) {
    return RepositoryGuard.run(() async {
      await localDataSource.deleteTarget(targetId);
    });
  }

  @override
  Future<Either<Failure, void>> clearAllTargets() {
    return RepositoryGuard.run(() async {
      await localDataSource.clearAllTargets();
    });
  }
}