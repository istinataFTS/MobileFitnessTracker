import 'package:dartz/dartz.dart';

import '../../core/enums/data_source_preference.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
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
            await localDataSource.replaceAllMeals(
              remoteMeals.map(MealModel.fromEntity).toList(),
            );
          }
          return remoteMeals;

        case DataSourcePreference.remoteThenLocal:
          if (remoteDataSource.isConfigured) {
            final remoteMeals = await remoteDataSource.getAllMeals();
            if (remoteMeals.isNotEmpty) {
              await localDataSource.replaceAllMeals(
                remoteMeals.map(MealModel.fromEntity).toList(),
              );
              return remoteMeals;
            }
          }
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
            await localDataSource.insertMeal(MealModel.fromEntity(remoteMeal));
          }
          return remoteMeal;

        case DataSourcePreference.remoteThenLocal:
          if (remoteDataSource.isConfigured) {
            final remoteMeal = await remoteDataSource.getMealById(id);
            if (remoteMeal != null) {
              final existingLocal = await localDataSource.getMealById(id);
              if (existingLocal == null) {
                await localDataSource.insertMeal(
                  MealModel.fromEntity(remoteMeal),
                );
              } else {
                await localDataSource.updateMeal(
                  MealModel.fromEntity(remoteMeal),
                );
              }
              return remoteMeal;
            }
          }
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
            await localDataSource.insertMeal(MealModel.fromEntity(remoteMeal));
          }
          return remoteMeal;

        case DataSourcePreference.remoteThenLocal:
          if (remoteDataSource.isConfigured) {
            final remoteMeal = await remoteDataSource.getMealByName(name);
            if (remoteMeal != null) {
              final existingLocal = await localDataSource.getMealById(
                remoteMeal.id,
              );
              if (existingLocal == null) {
                await localDataSource.insertMeal(
                  MealModel.fromEntity(remoteMeal),
                );
              } else {
                await localDataSource.updateMeal(
                  MealModel.fromEntity(remoteMeal),
                );
              }
              return remoteMeal;
            }
          }
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
      switch (sourcePreference) {
        case DataSourcePreference.localOnly:
          return localDataSource.searchMealsByName(query);

        case DataSourcePreference.remoteOnly:
          if (!remoteDataSource.isConfigured) {
            return const <Meal>[];
          }
          return remoteDataSource.searchMealsByName(query);

        case DataSourcePreference.localThenRemote:
          final localMeals = await localDataSource.searchMealsByName(query);
          if (localMeals.isNotEmpty || !remoteDataSource.isConfigured) {
            return localMeals;
          }
          return remoteDataSource.searchMealsByName(query);

        case DataSourcePreference.remoteThenLocal:
          if (remoteDataSource.isConfigured) {
            final remoteMeals = await remoteDataSource.searchMealsByName(query);
            if (remoteMeals.isNotEmpty) {
              return remoteMeals;
            }
          }
          return localDataSource.searchMealsByName(query);
      }
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