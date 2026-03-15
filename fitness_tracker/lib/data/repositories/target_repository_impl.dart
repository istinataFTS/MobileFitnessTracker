import 'package:dartz/dartz.dart';

import '../../core/enums/data_source_preference.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
import '../../domain/entities/target.dart';
import '../../domain/repositories/target_repository.dart';
import '../datasources/local/target_local_datasource.dart';
import '../datasources/remote/target_remote_datasource.dart';
import '../models/target_model.dart';
import '../sync/target_sync_coordinator.dart';

class TargetRepositoryImpl implements TargetRepository {
  final TargetLocalDataSource localDataSource;
  final TargetRemoteDataSource remoteDataSource;
  final TargetSyncCoordinator syncCoordinator;

  const TargetRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.syncCoordinator,
  });

  @override
  Future<Either<Failure, List<Target>>> getAllTargets({
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      switch (sourcePreference) {
        case DataSourcePreference.localOnly:
          return localDataSource.getAllTargets();

        case DataSourcePreference.remoteOnly:
          if (!remoteDataSource.isConfigured) {
            return const <Target>[];
          }
          return remoteDataSource.getAllTargets();

        case DataSourcePreference.localThenRemote:
          final localTargets = await localDataSource.getAllTargets();
          if (localTargets.isNotEmpty || !remoteDataSource.isConfigured) {
            return localTargets;
          }

          final remoteTargets = await remoteDataSource.getAllTargets();
          if (remoteTargets.isNotEmpty) {
            await localDataSource.replaceAllTargets(
              remoteTargets.map(TargetModel.fromEntity).toList(),
            );
          }
          return remoteTargets;

        case DataSourcePreference.remoteThenLocal:
          if (remoteDataSource.isConfigured) {
            final remoteTargets = await remoteDataSource.getAllTargets();
            if (remoteTargets.isNotEmpty) {
              await localDataSource.replaceAllTargets(
                remoteTargets.map(TargetModel.fromEntity).toList(),
              );
              return remoteTargets;
            }
          }

          return localDataSource.getAllTargets();
      }
    });
  }

  @override
  Future<Either<Failure, Target?>> getTargetById(
    String id, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      switch (sourcePreference) {
        case DataSourcePreference.localOnly:
          return localDataSource.getTargetById(id);

        case DataSourcePreference.remoteOnly:
          if (!remoteDataSource.isConfigured) {
            return null;
          }
          return remoteDataSource.getTargetById(id);

        case DataSourcePreference.localThenRemote:
          final localTarget = await localDataSource.getTargetById(id);
          if (localTarget != null) {
            return localTarget;
          }

          if (!remoteDataSource.isConfigured) {
            return null;
          }

          final remoteTarget = await remoteDataSource.getTargetById(id);
          if (remoteTarget != null) {
            await localDataSource.insertTarget(
              TargetModel.fromEntity(remoteTarget),
            );
          }
          return remoteTarget;

        case DataSourcePreference.remoteThenLocal:
          if (remoteDataSource.isConfigured) {
            final remoteTarget = await remoteDataSource.getTargetById(id);
            if (remoteTarget != null) {
              final existingLocal = await localDataSource.getTargetById(id);
              if (existingLocal == null) {
                await localDataSource.insertTarget(
                  TargetModel.fromEntity(remoteTarget),
                );
              } else {
                await localDataSource.updateTarget(
                  TargetModel.fromEntity(remoteTarget),
                );
              }
              return remoteTarget;
            }
          }

          return localDataSource.getTargetById(id);
      }
    });
  }

  @override
  Future<Either<Failure, Target?>> getTargetByTypeAndCategory(
    TargetType type,
    String categoryKey,
    TargetPeriod period, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      switch (sourcePreference) {
        case DataSourcePreference.localOnly:
          return localDataSource.getTargetByTypeAndCategory(
            type,
            categoryKey,
            period,
          );

        case DataSourcePreference.remoteOnly:
          if (!remoteDataSource.isConfigured) {
            return null;
          }
          return remoteDataSource.getTargetByTypeAndCategory(
            type,
            categoryKey,
            period,
          );

        case DataSourcePreference.localThenRemote:
          final localTarget = await localDataSource.getTargetByTypeAndCategory(
            type,
            categoryKey,
            period,
          );
          if (localTarget != null) {
            return localTarget;
          }

          if (!remoteDataSource.isConfigured) {
            return null;
          }

          final remoteTarget = await remoteDataSource.getTargetByTypeAndCategory(
            type,
            categoryKey,
            period,
          );
          if (remoteTarget != null) {
            await localDataSource.insertTarget(
              TargetModel.fromEntity(remoteTarget),
            );
          }
          return remoteTarget;

        case DataSourcePreference.remoteThenLocal:
          if (remoteDataSource.isConfigured) {
            final remoteTarget = await remoteDataSource.getTargetByTypeAndCategory(
              type,
              categoryKey,
              period,
            );
            if (remoteTarget != null) {
              final existingLocal = await localDataSource.getTargetById(
                remoteTarget.id,
              );
              if (existingLocal == null) {
                await localDataSource.insertTarget(
                  TargetModel.fromEntity(remoteTarget),
                );
              } else {
                await localDataSource.updateTarget(
                  TargetModel.fromEntity(remoteTarget),
                );
              }
              return remoteTarget;
            }
          }

          return localDataSource.getTargetByTypeAndCategory(
            type,
            categoryKey,
            period,
          );
      }
    });
  }

  @override
  Future<Either<Failure, void>> addTarget(Target target) {
    return RepositoryGuard.run(() async {
      await syncCoordinator.persistAddedTarget(target);
    });
  }

  @override
  Future<Either<Failure, void>> updateTarget(Target target) {
    return RepositoryGuard.run(() async {
      await syncCoordinator.persistUpdatedTarget(target);
    });
  }

  @override
  Future<Either<Failure, void>> deleteTarget(String targetId) {
    return RepositoryGuard.run(() async {
      await syncCoordinator.persistDeletedTarget(targetId);
    });
  }

  @override
  Future<Either<Failure, void>> clearAllTargets() {
    return RepositoryGuard.run(() async {
      await localDataSource.clearAllTargets();
    });
  }

  @override
  Future<Either<Failure, void>> syncPendingTargets() {
    return RepositoryGuard.run(() async {
      await syncCoordinator.syncPendingChanges();
    });
  }
}