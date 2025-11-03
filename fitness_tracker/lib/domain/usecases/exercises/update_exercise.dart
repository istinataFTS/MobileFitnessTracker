import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/exercise.dart';
import '../../repositories/exercise_repository.dart';

class UpdateExercise {
  final ExerciseRepository repository;

  const UpdateExercise(this.repository);

  Future<Either<Failure, void>> call(Exercise exercise) async {
    return await repository.updateExercise(exercise);
  }
}