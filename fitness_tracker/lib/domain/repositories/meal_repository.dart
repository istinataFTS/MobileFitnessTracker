import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/meal.dart';

/// Repository interface for Meal operations
/// 
/// Defines the contract for meal data access without exposing
/// implementation details. Follows Clean Architecture principles.
abstract class MealRepository {
  /// Get all meals from storage
  /// Typically sorted alphabetically by name
  Future<Either<Failure, List<Meal>>> getAllMeals();

  /// Get a specific meal by ID
  /// Returns null wrapped in Right if meal doesn't exist
  Future<Either<Failure, Meal?>> getMealById(String id);

  /// Get a specific meal by name (case-insensitive)
  /// Returns null wrapped in Right if meal doesn't exist
  /// Useful for preventing duplicate meal names
  Future<Either<Failure, Meal?>> getMealByName(String name);

  /// Search meals by name (case-insensitive partial match)
  /// Returns empty list if no matches found
  Future<Either<Failure, List<Meal>>> searchMealsByName(String query);

  /// Get recently used meals (based on nutrition logs)
  /// Useful for quick access in logging UI
  /// Limit parameter controls how many to return
  Future<Either<Failure, List<Meal>>> getRecentMeals({int limit = 5});

  /// Get most frequently used meals
  /// Useful for "favorites" or "frequent" section in UI
  /// Limit parameter controls how many to return
  Future<Either<Failure, List<Meal>>> getFrequentMeals({int limit = 10});

  /// Add a new meal
  /// Returns error if meal with same name already exists
  Future<Either<Failure, void>> addMeal(Meal meal);

  /// Update an existing meal
  /// Returns error if meal doesn't exist
  Future<Either<Failure, void>> updateMeal(Meal meal);

  /// Delete a meal by ID
  /// Note: Should handle cascade deletion of related nutrition logs
  /// or prevent deletion if logs exist (business logic decision)
  Future<Either<Failure, void>> deleteMeal(String id);

  /// Clear all meals
  /// WARNING: Use with caution - typically for testing or reset functionality
  Future<Either<Failure, void>> clearAllMeals();

  /// Get total count of meals
  /// Useful for analytics or UI display
  Future<Either<Failure, int>> getMealsCount();
}