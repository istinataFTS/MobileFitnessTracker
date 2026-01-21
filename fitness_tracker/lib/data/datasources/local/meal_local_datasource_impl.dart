import '../../core/errors/exceptions.dart';
import '../../models/meal_model.dart';
import '../../../domain/entities/meal.dart';
import 'database_helper.dart';
import 'meal_local_datasource.dart';

/// Implementation of MealLocalDataSource using SQLite
class MealLocalDataSourceImpl implements MealLocalDataSource {
  final DatabaseHelper databaseHelper;

  MealLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<Meal>> getAllMeals() async {
    try {
      final maps = await databaseHelper.getAllMeals();
      return maps.map((map) => MealModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get all meals: $e');
    }
  }

  @override
  Future<Meal?> getMealById(String id) async {
    try {
      final map = await databaseHelper.getMealById(id);
      if (map == null) return null;
      return MealModel.fromMap(map);
    } catch (e) {
      throw CacheDatabaseException('Failed to get meal by ID: $e');
    }
  }

  @override
  Future<void> addMeal(Meal meal) async {
    try {
      final model = MealModel.fromEntity(meal);
      await databaseHelper.insertMeal(model.toMap());
    } catch (e) {
      throw CacheDatabaseException('Failed to add meal: $e');
    }
  }

  @override
  Future<void> updateMeal(Meal meal) async {
    try {
      final model = MealModel.fromEntity(meal);
      await databaseHelper.updateMeal(model.toMap());
    } catch (e) {
      throw CacheDatabaseException('Failed to update meal: $e');
    }
  }

  @override
  Future<void> deleteMeal(String id) async {
    try {
      await databaseHelper.deleteMeal(id);
    } catch (e) {
      throw CacheDatabaseException('Failed to delete meal: $e');
    }
  }

  @override
  Future<void> clearAllMeals() async {
    try {
      await databaseHelper.clearAllMeals();
    } catch (e) {
      throw CacheDatabaseException('Failed to clear all meals: $e');
    }
  }
}