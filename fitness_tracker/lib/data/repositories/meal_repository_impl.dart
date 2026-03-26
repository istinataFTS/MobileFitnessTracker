import 'package:dartz/dartz.dart';

import '../../core/enums/data_source_preference.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
import '../../core/sync/local_remote_merge.dart';
import '../../domain/entities/meal.dart';
import '../../domain/repositories/meal_repository.dart';
import '../datasources/local/meal_local_datasource.dart';
import '../datasources/remote/meal_remote_datasource.dart';
import '../models/meal_model.dart';
import '../sync/meal_sync_coordinator.dart';

class MealRepositoryImpl implements MealRepository {
  final MealLocalDataSource localDataSource;
  final MealRemoteDataSource remoteDataSource;
  final MealSyncCoordinator syncCoordinator;

  static final LocalRemoteMerge<Meal> _merge = LocalRemoteMerge<Meal>(
    getId: (meal) => meal.id,
    getUpdatedAt: (meal) => meal.updatedAt,
    getSyncMetadata: (meal) => meal.syncMetadata,
  );

  const MealRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.syncCoordinator,
  });

  @override
  Future<Either<Failure, List<Meal>>> getAllMeals({
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      switch (sourcePreference) {
        case DataSourcePreference.localOnly:
          return localDataSource.getAllMeals();

        case DataSourcePreference.remoteOnly:
          if (!remoteDataSource.isConfigured) {
            return const <Meal>[];
          }
          return remoteDataSource.getAllMeals();

        case DataSourcePreference.localThenRemote:
          final localMeals = await localDataSource.getAllMeals();
          if (localMeals.isNotEmpty || !remoteDataSource.isConfigured) {
            return localMeals;
          }

          final remoteMeals = await remoteDataSource.getAllMeals();
          if (remoteMeals.isNotEmpty) {
            await localDataSource.mergeRemoteMeals(
              remoteMeals.map(MealModel.fromEntity).toList(),
            );
          }
          return localDataSource.getAllMeals();

        case DataSourcePreference.remoteThenLocal:
          if (!remoteDataSource.isConfigured) {
            return localDataSource.getAllMeals();
          }

          final localMeals = await localDataSource.getAllMeals();
          final remoteMeals = await remoteDataSource.getAllMeals();

          if (remoteMeals.isEmpty) {
            return localMeals;
          }

          final merged = _merge.mergeLists(
            localItems: localMeals,
            remoteItems: remoteMeals,
          );

          await localDataSource.mergeRemoteMeals(
            merged.map(MealModel.fromEntity).toList(),
          );

          return localDataSource.getAllMeals();
      }
    });
  }

  @override
  Future<Either<Failure, Meal?>> getMealById(
    String id, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      switch (sourcePreference) {
        case DataSourcePreference.localOnly:
          return localDataSource.getMealById(id);

        case DataSourcePreference.remoteOnly:
          if (!remoteDataSource.isConfigured) {
            return null;
          }
          return remoteDataSource.getMealById(id);

        case DataSourcePreference.localThenRemote:
          final localMeal = await localDataSource.getMealById(id);
          if (localMeal != null) {
            return localMeal;
          }

          if (!remoteDataSource.isConfigured) {
            return null;
          }

          final remoteMeal = await remoteDataSource.getMealById(id);
          if (remoteMeal != null) {
            await localDataSource.upsertMeal(MealModel.fromEntity(remoteMeal));
          }
          return localDataSource.getMealById(id);

        case DataSourcePreference.remoteThenLocal:
          if (!remoteDataSource.isConfigured) {
            return localDataSource.getMealById(id);
          }

          final localMeal = await localDataSource.getMealById(id);
          final remoteMeal = await remoteDataSource.getMealById(id);

          if (remoteMeal == null) {
            return localMeal;
          }

          if (localMeal == null) {
            await localDataSource.upsertMeal(MealModel.fromEntity(remoteMeal));
            return localDataSource.getMealById(id);
          }

          final merged = _merge.chooseWinner(
            local: localMeal,
            remote: remoteMeal,
          );

          await localDataSource.upsertMeal(MealModel.fromEntity(merged));
          return localDataSource.getMealById(id);
      }
    });
  }

  @override
  Future<Either<Failure, Meal?>> getMealByName(
    String name, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      switch (sourcePreference) {
        case DataSourcePreference.localOnly:
          return localDataSource.getMealByName(name);

        case DataSourcePreference.remoteOnly:
          if (!remoteDataSource.isConfigured) {
            return null;
          }
          return remoteDataSource.getMealByName(name);

        case DataSourcePreference.localThenRemote:
          final localMeal = await localDataSource.getMealByName(name);
          if (localMeal != null) {
            return localMeal;
          }

          if (!remoteDataSource.isConfigured) {
            return null;
          }

          final remoteMeal = await remoteDataSource.getMealByName(name);
          if (remoteMeal != null) {
            await localDataSource.upsertMeal(MealModel.fromEntity(remoteMeal));
          }
          return localDataSource.getMealByName(name);

        case DataSourcePreference.remoteThenLocal:
          if (!remoteDataSource.isConfigured) {
            return localDataSource.getMealByName(name);
          }

          final localMeal = await localDataSource.getMealByName(name);
          final remoteMeal = await remoteDataSource.getMealByName(name);

          if (remoteMeal == null) {
            return localMeal;
          }

          if (localMeal == null) {
            await localDataSource.upsertMeal(MealModel.fromEntity(remoteMeal));
            return localDataSource.getMealByName(name);
          }

          final merged = _merge.chooseWinner(
            local: localMeal,
            remote: remoteMeal,
          );

          await localDataSource.upsertMeal(MealModel.fromEntity(merged));
          return localDataSource.getMealByName(name);
      }
    });
  }

  @override
  Future<Either<Failure, List<Meal>>> searchMealsByName(
    String query, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      if (sourcePreference == DataSourcePreference.localOnly ||
          !remoteDataSource.isConfigured) {
        return localDataSource.searchMealsByName(query);
      }

      final meals = await getAllMeals(sourcePreference: sourcePreference);
      return meals.fold(
        (_) => const <Meal>[],
        (items) => items
            .where(
              (meal) => meal.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList(),
      );
    });
  }

  @override
  Future<Either<Failure, List<Meal>>> getRecentMeals({
    int limit = 5,
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      if (sourcePreference == DataSourcePreference.localOnly ||
          !remoteDataSource.isConfigured) {
        return localDataSource.getRecentMeals(limit: limit);
      }

      final meals = await getAllMeals(sourcePreference: sourcePreference);
      return meals.fold(
        (_) => const <Meal>[],
        (items) => items.take(limit).toList(),
      );
    });
  }

  @override
  Future<Either<Failure, List<Meal>>> getFrequentMeals({
    int limit = 10,
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      if (sourcePreference == DataSourcePreference.localOnly ||
          !remoteDataSource.isConfigured) {
        return localDataSource.getFrequentMeals(limit: limit);
      }

      final meals = await getAllMeals(sourcePreference: sourcePreference);
      return meals.fold(
        (_) => const <Meal>[],
        (items) => items.take(limit).toList(),
      );
    });
  }

  @override
  Future<Either<Failure, void>> addMeal(Meal meal) {
    return RepositoryGuard.run(() async {
      await syncCoordinator.persistAddedMeal(meal);
    });
  }

  @override
  Future<Either<Failure, void>> updateMeal(Meal meal) {
    return RepositoryGuard.run(() async {
      await syncCoordinator.persistUpdatedMeal(meal);
    });
  }

  @override
  Future<Either<Failure, void>> deleteMeal(String id) {
    return RepositoryGuard.run(() async {
      await syncCoordinator.persistDeletedMeal(id);
    });
  }

  @override
  Future<Either<Failure, void>> clearAllMeals() {
    return RepositoryGuard.run(() async {
      await localDataSource.clearAllMeals();
    });
  }

  @override
  Future<Either<Failure, int>> getMealsCount() {
    return RepositoryGuard.run(() => localDataSource.getMealsCount());
  }

  @override
  Future<Either<Failure, void>> syncPendingMeals() {
    return RepositoryGuard.run(() async {
      await syncCoordinator.syncPendingChanges();
    });
  }
}
