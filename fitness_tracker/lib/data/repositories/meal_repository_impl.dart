import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/meal.dart';
import '../../domain/repositories/meal_repository.dart';
import '../datasources/local/meal_local_datasource.dart';
import '../models/meal_model.dart';

/// Repository implementation for Meal operations
/// Implements domain layer interface using data layer datasources
/// Converts exceptions to failures for clean error handling
class MealRepositoryImpl implements MealRepository {
  final MealLocalDataSource localDataSource;

  const MealRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Meal>>> getAllMeals() async {
    try {
      final meals = await localDataSource.getAllMeals();
      return Right(meals);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Meal?>> getMealById(String id) async {
    try {
      final meal = await localDataSource.getMealById(id);
      return Right(meal);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Meal?>> getMealByName(String name) async {
    try {
      final meal = await localDataSource.getMealByName(name);
      return Right(meal);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Meal>>> searchMealsByName(String searchTerm) async {
    try {
      final meals = await localDataSource.searchMealsByName(searchTerm);
      return Right(meals);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Meal>>> getRecentMeals({int limit = 10}) async {
    try {
      final meals = await localDataSource.getRecentMeals(limit: limit);
      return Right(meals);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Meal>>> getFrequentMeals({int limit = 10}) async {
    try {
      final meals = await localDataSource.getFrequentMeals(limit: limit);
      return Right(meals);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addMeal(Meal meal) async {
    try {
      final model = MealModel.fromEntity(meal);
      
      // Validate macros before inserting
      model.validateMacros();
      
      await localDataSource.insertMeal(model);
      return const Right(null);
    } on ArgumentError catch (e) {
      return Left(ValidationFailure(e.message));
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateMeal(Meal meal) async {
    try {
      final model = MealModel.fromEntity(meal);
      
      // Validate macros before updating
      model.validateMacros();
      
      await localDataSource.updateMeal(model);
      return const Right(null);
    } on ArgumentError catch (e) {
      return Left(ValidationFailure(e.message));
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMeal(String id) async {
    try {
      await localDataSource.deleteMeal(id);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllMeals() async {
    try {
      await localDataSource.clearAllMeals();
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getMealsCount() async {
    try {
      final count = await localDataSource.getMealsCount();
      return Right(count);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }
}