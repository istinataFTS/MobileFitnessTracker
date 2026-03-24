import 'package:dartz/dartz.dart';

import '../../core/enums/data_source_preference.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
import '../../core/sync/local_remote_merge.dart';
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

  static final LocalRemoteMerge<Target> _merge = LocalRemoteMerge<Target>(
    getId: (target) => target.id,
    getUpdatedAt: (target) => target.updatedAt,
    getSyncMetadata: (target) => target.syncMetadata,
  );

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
            await localDataSource.mergeRemoteTargets(
              remoteTargets.map(TargetModel.fromEntity).toList(),
            );
          }
          return localDataSource.getAllTargets();

        case DataSourcePreference.remoteThenLocal:
          if (!remoteDataSource.isConfigured) {
            return localDataSource.getAllTargets();
          }

          final localTargets = await localDataSource.getAllTargets();
          final remoteTargets = await remoteDataSource.getAllTargets();

          if (remoteTargets.isEmpty) {
            return localTargets;
          }

          final merged = _merge.mergeLists(
            localItems: localTargets,
            remoteItems: remoteTargets,
          );

          await localDataSource.mergeRemoteTargets(
            merged.map(TargetModel.fromEntity).toList(),
          );

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
            return localTarget.syncMetadata.isPendingDelete ? null : localTarget;
          }

          if (!remoteDataSource.isConfigured) {
            return null;
          }

          final remoteTarget = await remoteDataSource.getTargetById(id);
          if (remoteTarget != null) {
            await localDataSource.upsertTarget(
              TargetModel.fromEntity(remoteTarget),
            );
          }
          return remoteTarget;

        case DataSourcePreference.remoteThenLocal:
          if (!remoteDataSource.isConfigured) {
            return localDataSource.getTargetById(id);
          }

          final localTarget = await localDataSource.getTargetById(id);
          final remoteTarget = await remoteDataSource.getTargetById(id);

          if (remoteTarget == null) {
            if (localTarget == null || localTarget.syncMetadata.isPendingDelete) {
              return null;
            }
            return localTarget;
          }

          if (localTarget == null) {
            await localDataSource.upsertTarget(
              TargetModel.fromEntity(remoteTarget),
            );
            return remoteTarget;
          }

          final merged = _merge.chooseWinner(
            local: localTarget,
            remote: remoteTarget,
          );

          await localDataSource.upsertTarget(TargetModel.fromEntity(merged));
          return merged.syncMetadata.isPendingDelete ? null : merged;
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
      if (sourcePreference == DataSourcePreference.localOnly ||
          !remoteDataSource.isConfigured) {
        return localDataSource.getTargetByTypeAndCategory(
          type,
          categoryKey,
          period,
        );
      }

      final targets = await getAllTargets(sourcePreference: sourcePreference);
      return targets.fold(
        (_) => null,
        (items) {
          try {
            return items.firstWhere(
              (target) =>
                  target.type == type &&
                  target.categoryKey == categoryKey &&
                  target.period == period,
            );
          } catch (_) {
            return null;
          }
        },
      );
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