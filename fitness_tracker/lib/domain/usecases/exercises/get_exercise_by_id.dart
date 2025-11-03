import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/exercise.dart';
import '../../repositories/exercise_repository.dart';

class GetExerciseById {
  final ExerciseRepository repository;

  const GetExerciseById(this.repository);

  Future<Either<Failure, Exercise?>> call(String id) async {
    return await repository.getExerciseById(id);
  }
}