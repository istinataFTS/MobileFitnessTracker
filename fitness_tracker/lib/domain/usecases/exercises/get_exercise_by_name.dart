import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/exercise.dart';
import '../../repositories/exercise_repository.dart';

class GetExerciseByName {
  final ExerciseRepository repository;

  const GetExerciseByName(this.repository);

  Future<Either<Failure, Exercise?>> call(String name) async {
    return await repository.getExerciseByName(name);
  }
}