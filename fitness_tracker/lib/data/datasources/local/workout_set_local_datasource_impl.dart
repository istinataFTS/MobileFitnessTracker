import '../../core/errors/exceptions.dart';
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
      final maps = await databaseHelper.getAllWorkoutSets();
      return maps.map((map) => WorkoutSetModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get all sets: $e');
    }
  }

  @override
  Future<List<WorkoutSet>> getSetsByExerciseId(String exerciseId) async {
    try {
      final maps = await databaseHelper.getWorkoutSetsByExerciseId(exerciseId);
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
      final maps = await databaseHelper.getWorkoutSetsByDateRange(
        startDate,
        endDate,
      );
      return maps.map((map) => WorkoutSetModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheDatabaseException('Failed to get sets by date range: $e');
    }
  }

  @override
  Future<void> addSet(WorkoutSet set) async {
    try {
      final model = WorkoutSetModel.fromEntity(set);
      await databaseHelper.insertWorkoutSet(model.toMap());
    } catch (e) {
      throw CacheDatabaseException('Failed to add set: $e');
    }
  }

  @override
  Future<void> updateSet(WorkoutSet set) async {
    try {
      final model = WorkoutSetModel.fromEntity(set);
      await databaseHelper.updateWorkoutSet(model.toMap());
    } catch (e) {
      throw CacheDatabaseException('Failed to update set: $e');
    }
  }

  @override
  Future<void> deleteSet(String id) async {
    try {
      await databaseHelper.deleteWorkoutSet(id);
    } catch (e) {
      throw CacheDatabaseException('Failed to delete set: $e');
    }
  }

  @override
  Future<void> clearAllSets() async {
    try {
      await databaseHelper.clearAllWorkoutSets();
    } catch (e) {
      throw CacheDatabaseException('Failed to clear all sets: $e');
    }
  }
}