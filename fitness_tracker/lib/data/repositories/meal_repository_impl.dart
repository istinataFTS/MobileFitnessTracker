import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
import '../../domain/entities/meal.dart';
import '../../domain/repositories/meal_repository.dart';
import '../datasources/local/meal_local_datasource.dart';
import '../models/meal_model.dart';

/// Repository implementation for Meal operations.
/// Converts datasource/model exceptions into domain failures.
class MealRepositoryImpl implements MealRepository {
  final MealLocalDataSource localDataSource;

  const MealRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Meal>>> getAllMeals() {
    return RepositoryGuard.run(() async {
      return localDataSource.getAllMeals();
    });
  }

  @override
  Future<Either<Failure, Meal?>> getMealById(String id) {
    return RepositoryGuard.run(() async {
      return localDataSource.getMealById(id);
    });
  }

  @override
  Future<Either<Failure, Meal?>> getMealByName(String name) {
    return RepositoryGuard.run(() async {
      return localDataSource.getMealByName(name);
    });
  }

  @override
  Future<Either<Failure, List<Meal>>> searchMealsByName(
    String searchTerm,
  ) {
    return RepositoryGuard.run(() async {
      return localDataSource.searchMealsByName(searchTerm);
    });
  }

  @override
  Future<Either<Failure, List<Meal>>> getRecentMeals({
    int limit = 10,
  }) {
    return RepositoryGuard.run(() async {
      return localDataSource.getRecentMeals(limit: limit);
    });
  }

  @override
  Future<Either<Failure, List<Meal>>> getFrequentMeals({
    int limit = 10,
  }) {
    return RepositoryGuard.run(() async {
      return localDataSource.getFrequentMeals(limit: limit);
    });
  }

  @override
  Future<Either<Failure, void>> addMeal(Meal meal) {
    return RepositoryGuard.run(() async {
      final model = MealModel.fromEntity(meal);
      model.validateMacros();
      model.validateAndLogCalories();

      await localDataSource.insertMeal(model);
    });
  }

  @override
  Future<Either<Failure, void>> updateMeal(Meal meal) {
    return RepositoryGuard.run(() async {
      final model = MealModel.fromEntity(meal);
      model.validateMacros();
      model.validateAndLogCalories();

      await localDataSource.updateMeal(model);
    });
  }

  @override
  Future<Either<Failure, void>> deleteMeal(String id) {
    return RepositoryGuard.run(() async {
      await localDataSource.deleteMeal(id);
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
    return RepositoryGuard.run(() async {
      return localDataSource.getMealsCount();
    });
  }
}