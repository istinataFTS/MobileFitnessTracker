import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/workout_set.dart';
import '../../repositories/workout_set_repository.dart';

/// Use case for updating an existing workout set
/// This allows users to edit past workout logs
class UpdateWorkoutSet {
  final WorkoutSetRepository repository;

  const UpdateWorkoutSet(this.repository);

  /// Update a workout set
  /// 
  /// Parameters:
  /// - [set]: The updated WorkoutSet entity
  /// 
  /// Returns: Either a Failure or void on success
  Future<Either<Failure, void>> call(WorkoutSet set) async {
    return await repository.updateSet(set);
  }
}


