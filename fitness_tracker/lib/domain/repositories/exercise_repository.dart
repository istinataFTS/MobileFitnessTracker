import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/exercise.dart';


abstract class ExerciseRepository {
  /// Get all exercises from storage
  Future<Either<Failure, List<Exercise>>> getAllExercises();
  Future<Either<Failure, Exercise?>> getExerciseById(String id);
  Future<Either<Failure, Exercise?>> getExerciseByName(String name);
  Future<Either<Failure, List<Exercise>>> getExercisesForMuscle(
    String muscleGroup,
  );

  Future<Either<Failure, void>> addExercise(Exercise exercise);
  Future<Either<Failure, void>> updateExercise(Exercise exercise);
  Future<Either<Failure, void>> deleteExercise(String id);
  Future<Either<Failure, void>> clearAllExercises();
}