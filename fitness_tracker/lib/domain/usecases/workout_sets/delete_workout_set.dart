import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/workout_set_repository.dart';
import '../muscle_stimulus/rebuild_muscle_stimulus_from_workout_history.dart';

/// Use case for deleting a workout set
/// This encapsulates the business logic for removing a set from history
class DeleteWorkoutSet {
  final WorkoutSetRepository repository;
  final RebuildMuscleStimulusFromWorkoutHistory
  rebuildMuscleStimulusFromWorkoutHistory;

  const DeleteWorkoutSet(
    this.repository, {
    required this.rebuildMuscleStimulusFromWorkoutHistory,
  });

  /// Delete a workout set by ID
  ///
  /// Parameters:
  /// - [id]: The ID of the workout set to delete
  ///
  /// Returns: Either a Failure or void on success
  Future<Either<Failure, void>> call(String id) async {
    final deleteResult = await repository.deleteSet(id);

    return deleteResult.fold(
      (failure) async => Left(failure),
      (_) async => rebuildMuscleStimulusFromWorkoutHistory(),
    );
  }
}
