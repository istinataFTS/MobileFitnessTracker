import '../../../core/constants/database_tables.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/workout_set_model.dart';
import '../../../domain/entities/workout_set.dart';
import 'database_helper.dart';
import 'workout_set_local_datasource.dart';

/// Implementation of WorkoutSetLocalDataSource using SQLite
class WorkoutSetLocalDataSourceImpl implements WorkoutSetLocalDataSource {
  final DatabaseHelper databaseHelper;

  WorkoutSetLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<WorkoutSet>> getAllSets() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(DatabaseTables.workoutSets);
      return maps.map((map) => WorkoutSetModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get all sets: $e');
    }
  }

  @override
  Future<List<WorkoutSet>> getSetsByExerciseId(String exerciseId) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.workoutSets,
        where: '${DatabaseTables.setExerciseId} = ?',
        whereArgs: [exerciseId],
      );
      return maps.map((map) => WorkoutSetModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get sets by exercise ID: $e');
    }
  }

  @override
  Future<List<WorkoutSet>> getSetsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseTables.workoutSets,
        where: '${DatabaseTables.setDate} >= ? AND ${DatabaseTables.setDate} <= ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
      );
      return maps.map((map) => WorkoutSetModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get sets by date range: $e');
    }
  }

  @override
  Future<void> addSet(WorkoutSet set) async {
    try {
      final db = await databaseHelper.database;
      final model = WorkoutSetModel.fromEntity(set);
      await db.insert(DatabaseTables.workoutSets, model.toMap());
    } catch (e) {
      throw CacheDatabaseException('Failed to add set: $e');
    }
  }

  @override
  Future<void> updateSet(WorkoutSet set) async {
    try {
      final db = await databaseHelper.database;
      final model = WorkoutSetModel.fromEntity(set);
      await db.update(
        DatabaseTables.workoutSets,
        model.toMap(),
        where: '${DatabaseTables.setId} = ?',
        whereArgs: [model.id],
      );
    } catch (e) {
      throw CacheDatabaseException('Failed to update set: $e');
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
      throw CacheDatabaseException('Failed to clear all sets: $e');
    }
  }
}