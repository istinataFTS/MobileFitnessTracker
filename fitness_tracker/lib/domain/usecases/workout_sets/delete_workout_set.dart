import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/workout_set_repository.dart';

/// Use case for deleting a workout set
/// This encapsulates the business logic for removing a set from history
class DeleteWorkoutSet {
  final WorkoutSetRepository repository;

  const DeleteWorkoutSet(this.repository);

  /// Delete a workout set by ID
  /// 
  /// Parameters:
  /// - [id]: The ID of the workout set to delete
  /// 
  /// Returns: Either a Failure or void on success
  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteSet(id);
  }
}
