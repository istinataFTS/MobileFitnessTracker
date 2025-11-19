import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/workout_set.dart';

abstract class WorkoutSetRepository {
  Future<Either<Failure, List<WorkoutSet>>> getAllSets();
  Future<Either<Failure, List<WorkoutSet>>> getSetsByExerciseId(
    String exerciseId,
  );
  Future<Either<Failure, List<WorkoutSet>>> getSetsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, void>> addSet(WorkoutSet set);
  Future<Either<Failure, void>> updateSet(WorkoutSet set); 
  Future<Either<Failure, void>> deleteSet(String id);
  Future<Either<Failure, void>> clearAllSets();
}