import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/exercise.dart';
import '../../repositories/exercise_repository.dart';

class GetAllExercises {
  final ExerciseRepository repository;

  const GetAllExercises(this.repository);

  Future<Either<Failure, List<Exercise>>> call() async {
    return await repository.getAllExercises();
  }
}