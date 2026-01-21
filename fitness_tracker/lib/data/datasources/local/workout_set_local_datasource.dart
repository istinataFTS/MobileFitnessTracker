import '../../../domain/entities/workout_set.dart';

/// Abstract interface for WorkoutSet local data operations
abstract class WorkoutSetLocalDataSource {
  Future<List<WorkoutSet>> getAllSets();
  
  Future<List<WorkoutSet>> getSetsByExerciseId(String exerciseId);
  
  Future<List<WorkoutSet>> getSetsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  
  Future<void> addSet(WorkoutSet set);
  
  Future<void> updateSet(WorkoutSet set);
  
  Future<void> deleteSet(String id);
  
  Future<void> clearAllSets();
}