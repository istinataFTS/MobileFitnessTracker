import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/exercise.dart';
import '../../repositories/exercise_repository.dart';

class AddExercise {
  final ExerciseRepository repository;

  const AddExercise(this.repository);

  Future<Either<Failure, void>> call(Exercise exercise) async {
    return await repository.addExercise(exercise);
  }
}