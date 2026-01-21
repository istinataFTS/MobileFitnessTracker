import '../../../domain/entities/meal.dart';

/// Abstract interface for Meal local data operations
abstract class MealLocalDataSource {
  /// Get all meals from local storage
  Future<List<Meal>> getAllMeals();
  
  /// Get a meal by ID
  Future<Meal?> getMealById(String id);
  
  /// Add a new meal to local storage
  Future<void> addMeal(Meal meal);
  
  /// Update an existing meal in local storage
  Future<void> updateMeal(Meal meal);
  
  /// Delete a meal from local storage
  Future<void> deleteMeal(String id);
  
  /// Clear all meals from local storage
  Future<void> clearAllMeals();
}