import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/workout_set.dart';
import '../../repositories/workout_set_repository.dart';

class AddWorkoutSet {
  final WorkoutSetRepository repository;

  const AddWorkoutSet(this.repository);

  Future<Either<Failure, void>> call(WorkoutSet set) async {
    return await repository.addSet(set);
  }
}