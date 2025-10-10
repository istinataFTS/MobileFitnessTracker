import 'package:sqflite/sqflite.dart';
import '../../../core/constants/database_tables.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/workout_set_model.dart';
import 'database_helper.dart';

abstract class WorkoutSetLocalDataSource {
  Future<List<WorkoutSetModel>> getAllSets();
  Future<List<WorkoutSetModel>> getSetsByExerciseId(String exerciseId);
  Future<List<WorkoutSetModel>> getSetsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<void> insertSet(WorkoutSetModel set);
  Future<void> deleteSet(String id);
  Future<void> clearAllSets();
}

class WorkoutSetLocalDataSourceImpl implements WorkoutSetLocalDataSource {
  final DatabaseHelper databaseHelper;

  const WorkoutSetLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<WorkoutSetModel>> getAllSets() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.workoutSets,
        orderBy: '${DatabaseTables.setDate} DESC, ${DatabaseTables.setCreatedAt} DESC',
      );
      return maps.map((map) => WorkoutSetModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get sets: $e');
    }
  }

  @override
  Future<List<WorkoutSetModel>> getSetsByExerciseId(String exerciseId) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.workoutSets,
        where: '${DatabaseTables.setExerciseId} = ?',
        whereArgs: [exerciseId],
        orderBy: '${DatabaseTables.setDate} DESC',
      );
      return maps.map((map) => WorkoutSetModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get sets by exercise: $e');
    }
  }

  @override
  Future<List<WorkoutSetModel>> getSetsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.workoutSets,
        where: '${DatabaseTables.setDate} BETWEEN ? AND ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy: '${DatabaseTables.setDate} DESC',
      );
      return maps.map((map) => WorkoutSetModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get sets by date range: $e');
    }
  }

  @override
  Future<void> insertSet(WorkoutSetModel set) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseTables.workoutSets,
        set.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to insert set: $e');
    }
  }

  @override
  Future<void> deleteSet(String id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        DatabaseTables.workoutSets,
        where: '${DatabaseTables.setId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to delete set: $e');
    }
  }

  @override
  Future<void> clearAllSets() async {
    try {
      final db = await databaseHelper.database;
      await db.delete(DatabaseTables.workoutSets);
    } catch (e) {
      throw CacheDatabaseException('Failed to clear sets: $e');
    }
  }
}