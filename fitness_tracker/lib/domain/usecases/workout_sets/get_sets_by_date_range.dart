import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/workout_set.dart';
import '../../entities/exercise.dart';
import '../../repositories/workout_set_repository.dart';
import '../../repositories/exercise_repository.dart';

/// Use case for getting workout sets filtered by date range and optionally by muscle group
/// This encapsulates the business logic for history filtering
class GetSetsByDateRange {
  final WorkoutSetRepository workoutSetRepository;
  final ExerciseRepository exerciseRepository;

  const GetSetsByDateRange({
    required this.workoutSetRepository,
    required this.exerciseRepository,
  });

  /// Get sets filtered by date range and optionally by muscle group
  /// 
  /// Parameters:
  /// - [startDate]: Start of date range (inclusive)
  /// - [endDate]: End of date range (inclusive)
  /// - [muscleGroup]: Optional muscle group filter (if null, returns all sets)
  /// 
  /// Returns: Either a Failure or a List of WorkoutSets
  Future<Either<Failure, List<WorkoutSet>>> call({
    required DateTime startDate,
    required DateTime endDate,
    String? muscleGroup,
  }) async {
    // First, get all sets in the date range
    final setsResult = await workoutSetRepository.getSetsByDateRange(
      startDate,
      endDate,
    );

    // If no muscle group filter, return all sets
    if (muscleGroup == null) {
      return setsResult;
    }

    // If muscle group filter is provided, filter by exercises that work that muscle
    return setsResult.fold(
      (failure) => Left(failure),
      (sets) async {
        // Get all exercises to check muscle groups
        final exercisesResult = await exerciseRepository.getAllExercises();

        return exercisesResult.fold(
          (failure) => Left(failure),
          (exercises) {
            // Create a map for quick exercise lookup
            final exerciseMap = <String, Exercise>{
              for (var exercise in exercises) exercise.id: exercise,
            };

            // Filter sets by muscle group
            final filteredSets = sets.where((set) {
              final exercise = exerciseMap[set.exerciseId];
              if (exercise == null) return false;
              return exercise.muscleGroups.contains(muscleGroup);
            }).toList();

            return Right(filteredSets);
          },
        );
      },
    );
  }
}
