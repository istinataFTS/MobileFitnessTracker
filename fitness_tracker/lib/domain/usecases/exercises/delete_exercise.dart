import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../repositories/exercise_repository.dart';
import '../../repositories/muscle_factor_repository.dart';
import '../muscle_stimulus/rebuild_muscle_stimulus_from_workout_history.dart';

class DeleteExercise {
  final ExerciseRepository repository;
  final MuscleFactorRepository muscleFactorRepository;
  final RebuildMuscleStimulusFromWorkoutHistory
  rebuildMuscleStimulusFromWorkoutHistory;

  const DeleteExercise(
    this.repository, {
    required this.muscleFactorRepository,
    required this.rebuildMuscleStimulusFromWorkoutHistory,
  });

  Future<Either<Failure, void>> call(String id) async {
    final deleteResult = await repository.deleteExercise(id);

    return deleteResult.fold((failure) async => Left(failure), (_) async {
      final deleteFactorsResult = await muscleFactorRepository
          .deleteMuscleFactorsByExerciseId(id);

      return deleteFactorsResult.fold(
        (failure) async => Left(failure),
        (_) async => rebuildMuscleStimulusFromWorkoutHistory(),
      );
    });
  }
}
