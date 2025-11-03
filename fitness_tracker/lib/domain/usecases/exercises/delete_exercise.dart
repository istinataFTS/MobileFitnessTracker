import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/exercise_repository.dart';

class DeleteExercise {
  final ExerciseRepository repository;

  const DeleteExercise(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteExercise(id);
  }
}