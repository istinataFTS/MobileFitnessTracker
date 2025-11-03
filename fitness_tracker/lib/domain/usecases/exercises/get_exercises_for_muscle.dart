import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/exercise.dart';
import '../../repositories/exercise_repository.dart';

class GetExercisesForMuscle {
  final ExerciseRepository repository;

  const GetExercisesForMuscle(this.repository);

  Future<Either<Failure, List<Exercise>>> call(String muscleGroup) async {
    return await repository.getExercisesForMuscle(muscleGroup);
  }
}