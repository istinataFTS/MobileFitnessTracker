import 'package:sqflite/sqflite.dart';
import '../../../core/constants/database_tables.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/nutrition_log_model.dart';
import 'database_helper.dart';

/// Local data source interface for NutritionLog operations
abstract class NutritionLogLocalDataSource {
  Future<List<NutritionLogModel>> getAllLogs();
  Future<NutritionLogModel?> getLogById(String id);
  Future<List<NutritionLogModel>> getLogsByDate(DateTime date);
  Future<List<NutritionLogModel>> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<List<NutritionLogModel>> getLogsByMealId(String mealId);
  Future<List<NutritionLogModel>> getTodayLogs();
  Future<List<NutritionLogModel>> getWeeklyLogs();
  Future<List<NutritionLogModel>> getMealLogs();
  Future<List<NutritionLogModel>> getDirectMacroLogs();
  Future<void> insertLog(NutritionLogModel log);
  Future<void> updateLog(NutritionLogModel log);
  Future<void> deleteLog(String id);
  Future<void> deleteLogsByDate(DateTime date);
  Future<void> deleteLogsByMealId(String mealId);
  Future<void> clearAllLogs();
  Future<Map<String, double>> getDailyMacros(DateTime date);
}

/// SQLite implementation of NutritionLog local data source
class NutritionLogLocalDataSourceImpl implements NutritionLogLocalDataSource {
  final DatabaseHelper databaseHelper;

  const NutritionLogLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<NutritionLogModel>> getAllLogs() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.nutritionLogs,
        orderBy: '${DatabaseTables.nutritionLogCreatedAt} DESC',
      );
      return maps.map((map) => NutritionLogModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get nutrition logs: $e');
    }
  }

  @override
  Future<NutritionLogModel?> getLogById(String id) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.nutritionLogs,
        where: '${DatabaseTables.nutritionLogId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return NutritionLogModel.fromMap(maps.first);
    } catch (e) {
      throw CacheDatabaseException('Failed to get nutrition log: $e');
    }
  }

  @override
  Future<List<NutritionLogModel>> getLogsByDate(DateTime date) async {
    try {
      final db = await databaseHelper.database;
      
      // Normalize date to start of day for comparison
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final maps = await db.query(
        DatabaseTables.nutritionLogs,
        where: '${DatabaseTables.nutritionLogDate} >= ? AND ${DatabaseTables.nutritionLogDate} <= ?',
        whereArgs: [
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String(),
        ],
        orderBy: '${DatabaseTables.nutritionLogCreatedAt} DESC',
      );
      
      return maps.map((map) => NutritionLogModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get logs by date: $e');
    }
  }

  @override
  Future<List<NutritionLogModel>> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await databaseHelper.database;
      
      // Normalize dates
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      final maps = await db.query(
        DatabaseTables.nutritionLogs,
        where: '${DatabaseTables.nutritionLogDate} >= ? AND ${DatabaseTables.nutritionLogDate} <= ?',
        whereArgs: [
          start.toIso8601String(),
          end.toIso8601String(),
        ],
        orderBy: '${DatabaseTables.nutritionLogCreatedAt} DESC',
      );
      
      return maps.map((map) => NutritionLogModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get logs by date range: $e');
    }
  }

  @override
  Future<List<NutritionLogModel>> getLogsByMealId(String mealId) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.nutritionLogs,
        where: '${DatabaseTables.nutritionLogMealId} = ?',
        whereArgs: [mealId],
        orderBy: '${DatabaseTables.nutritionLogCreatedAt} DESC',
      );
      return maps.map((map) => NutritionLogModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get logs by meal: $e');
    }
  }

  @override
  Future<List<NutritionLogModel>> getTodayLogs() async {
    try {
      return await getLogsByDate(DateTime.now());
    } catch (e) {
      throw CacheDatabaseException('Failed to get today logs: $e');
    }
  }

  @override
  Future<List<NutritionLogModel>> getWeeklyLogs() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final endDate = DateTime.now();
      
      return await getLogsByDateRange(startDate, endDate);
    } catch (e) {
      throw CacheDatabaseException('Failed to get weekly logs: $e');
    }
  }

  @override
  Future<List<NutritionLogModel>> getMealLogs() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.nutritionLogs,
        where: '${DatabaseTables.nutritionLogMealId} IS NOT NULL',
        orderBy: '${DatabaseTables.nutritionLogCreatedAt} DESC',
      );
      return maps.map((map) => NutritionLogModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get meal logs: $e');
    }
  }

  @override
  Future<List<NutritionLogModel>> getDirectMacroLogs() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.nutritionLogs,
        where: '${DatabaseTables.nutritionLogMealId} IS NULL',
        orderBy: '${DatabaseTables.nutritionLogCreatedAt} DESC',
      );
      return maps.map((map) => NutritionLogModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get direct macro logs: $e');
    }
  }

  @override
  Future<void> insertLog(NutritionLogModel log) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseTables.nutritionLogs,
        log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to insert nutrition log: $e');
    }
  }

  @override
  Future<void> updateLog(NutritionLogModel log) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseTables.nutritionLogs,
        log.toMap(),
        where: '${DatabaseTables.nutritionLogId} = ?',
        whereArgs: [log.id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to update nutrition log: $e');
    }
  }

  @override
  Future<void> deleteLog(String id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        DatabaseTables.nutritionLogs,
        where: '${DatabaseTables.nutritionLogId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to delete nutrition log: $e');
    }
  }

  @override
  Future<void> deleteLogsByDate(DateTime date) async {
    try {
      final db = await databaseHelper.database;
      
      // Normalize date to start and end of day
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      await db.delete(
        DatabaseTables.nutritionLogs,
        where: '${DatabaseTables.nutritionLogDate} >= ? AND ${DatabaseTables.nutritionLogDate} <= ?',
        whereArgs: [
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String(),
        ],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to delete logs by date: $e');
    }
  }

  @override
  Future<void> deleteLogsByMealId(String mealId) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        DatabaseTables.nutritionLogs,
        where: '${DatabaseTables.nutritionLogMealId} = ?',
        whereArgs: [mealId],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to delete logs by meal: $e');
    }
  }

  @override
  Future<void> clearAllLogs() async {
    try {
      final db = await databaseHelper.database;
      await db.delete(DatabaseTables.nutritionLogs);
    } catch (e) {
      throw CacheDatabaseException('Failed to clear nutrition logs: $e');
    }
  }

  @override
  Future<Map<String, double>> getDailyMacros(DateTime date) async {
    try {
      final db = await databaseHelper.database;
      
      // Normalize date to start and end of day
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final result = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(${DatabaseTables.nutritionLogCarbs}), 0) as totalCarbs,
          COALESCE(SUM(${DatabaseTables.nutritionLogProtein}), 0) as totalProtein,
          COALESCE(SUM(${DatabaseTables.nutritionLogFat}), 0) as totalFat,
          COALESCE(SUM(${DatabaseTables.nutritionLogCalories}), 0) as totalCalories,
          COUNT(*) as logsCount
        FROM ${DatabaseTables.nutritionLogs}
        WHERE ${DatabaseTables.nutritionLogDate} >= ? 
          AND ${DatabaseTables.nutritionLogDate} <= ?
      ''', [
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ]);

      if (result.isEmpty) {
        return {
          'totalCarbs': 0.0,
          'totalProtein': 0.0,
          'totalFat': 0.0,
          'totalCalories': 0.0,
          'logsCount': 0.0,
        };
      }

      final row = result.first;
      return {
        'totalCarbs': (row['totalCarbs'] as num).toDouble(),
        'totalProtein': (row['totalProtein'] as num).toDouble(),
        'totalFat': (row['totalFat'] as num).toDouble(),
        'totalCalories': (row['totalCalories'] as num).toDouble(),
        'logsCount': (row['logsCount'] as num).toDouble(),
      };
    } catch (e) {
      throw CacheDatabaseException('Failed to get daily macros: $e');
    }
  }
}