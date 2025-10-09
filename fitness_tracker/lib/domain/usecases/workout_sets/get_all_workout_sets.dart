import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/workout_set.dart';
import '../../repositories/workout_set_repository.dart';

class GetAllWorkoutSets {
  final WorkoutSetRepository repository;

  const GetAllWorkoutSets(this.repository);

  Future<Either<Failure, List<WorkoutSet>>> call() async {
    return await repository.getAllSets();
  }
}