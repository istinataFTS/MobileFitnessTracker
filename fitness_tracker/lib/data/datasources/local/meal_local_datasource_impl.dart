import 'package:sqflite/sqflite.dart';
import '../../../core/constants/database_tables.dart';
import '../../../core/errors/exceptions.dart';
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
      final db = await databaseHelper.database;
      final maps = await db.query(DatabaseTables.meals);
      return maps.map((map) => MealModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get all meals: $e');
    }
  }

  @override
  Future<Meal?> getMealByName(String name) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.meals,
        where: 'LOWER(${DatabaseTables.mealName}) = LOWER(?)',
        whereArgs: [name],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return MealModel.fromMap(maps.first);
    } catch (e) {
      throw CacheDatabaseException('Failed to get meal by name: $e');
    }
  }

  @override
  Future<List<Meal>> searchMealsByName(String searchTerm) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.meals,
        where: 'LOWER(${DatabaseTables.mealName}) LIKE LOWER(?)',
        whereArgs: ['%$searchTerm%'],
        orderBy: DatabaseTables.mealName,
      );
      return maps.map((map) => MealModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to search meals: $e');
    }
  }

  @override
  Future<List<Meal>> getRecentMeals({int limit = 10}) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.meals,
        orderBy: '${DatabaseTables.mealCreatedAt} DESC',
        limit: limit,
      );
      return maps.map((map) => MealModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get recent meals: $e');
    }
  }

  @override
  Future<List<Meal>> getFrequentMeals({int limit = 10}) async {
    // Falls back to recent meals — no usage-count tracking in current schema
    return getRecentMeals(limit: limit);
  }

  @override
  Future<void> insertMeal(covariant MealModel meal) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(DatabaseTables.meals, meal.toMap());
    } catch (e) {
      throw CacheDatabaseException('Failed to insert meal: $e');
    }
  }

  @override
  Future<int> getMealsCount() async {
    try {
      final db = await databaseHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.meals}');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw CacheDatabaseException('Failed to get meals count: $e');
    }
  }

  @override
  Future<Meal?> getMealById(String id) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.meals,
        where: '${DatabaseTables.mealId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return MealModel.fromMap(maps.first);
    } catch (e) {
      throw CacheDatabaseException('Failed to get meal by ID: $e');
    }
  }

  @override
  Future<void> addMeal(Meal meal) async {
    try {
      final db = await databaseHelper.database;
      final model = MealModel.fromEntity(meal);
      await db.insert(DatabaseTables.meals, model.toMap());
    } catch (e) {
      throw CacheDatabaseException('Failed to add meal: $e');
    }
  }

  @override
  Future<void> updateMeal(Meal meal) async {
    try {
      final db = await databaseHelper.database;
      final model = MealModel.fromEntity(meal);
      await db.update(
        DatabaseTables.meals,
        model.toMap(),
        where: '${DatabaseTables.mealId} = ?',
        whereArgs: [model.id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to update meal: $e');
    }
  }

  @override
  Future<void> deleteMeal(String id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        DatabaseTables.meals,
        where: '${DatabaseTables.mealId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to delete meal: $e');
    }
  }

  @override
  Future<void> clearAllMeals() async {
    try {
      final db = await databaseHelper.database;
      await db.delete(DatabaseTables.meals);
    } catch (e) {
      throw CacheDatabaseException('Failed to clear all meals: $e');
    }
  }
}