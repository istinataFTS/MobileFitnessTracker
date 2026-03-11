import '../../../domain/entities/meal.dart';

/// Abstract interface for Meal local data operations
abstract class MealLocalDataSource {
  Future<List<Meal>> getAllMeals();
  Future<Meal?> getMealById(String id);
  Future<Meal?> getMealByName(String name);
  Future<List<Meal>> searchMealsByName(String searchTerm);
  Future<List<Meal>> getRecentMeals({int limit = 10});
  Future<List<Meal>> getFrequentMeals({int limit = 10});
  Future<void> insertMeal(covariant dynamic meal);
  Future<void> addMeal(Meal meal);
  Future<void> updateMeal(Meal meal);
  Future<void> deleteMeal(String id);
  Future<void> clearAllMeals();
  Future<int> getMealsCount();
}