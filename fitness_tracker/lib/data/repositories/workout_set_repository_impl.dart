import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/workout_set.dart';

/// Repository interface for WorkoutSet operations
/// Follows Repository Pattern for clean architecture
abstract class WorkoutSetRepository {
  /// Get all workout sets
  Future<Either<Failure, List<WorkoutSet>>> getAllSets();
  
  /// Get sets for a specific exercise
  Future<Either<Failure, List<WorkoutSet>>> getSetsByExerciseId(
    String exerciseId,
  );
  
  /// Get sets within a date range
  Future<Either<Failure, List<WorkoutSet>>> getSetsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  
  /// Add a new set
  Future<Either<Failure, void>> addSet(WorkoutSet set);
  
  /// Delete a set by ID
  Future<Either<Failure, void>> deleteSet(String id);
  
  /// Clear all sets
  Future<Either<Failure, void>> clearAllSets();
}