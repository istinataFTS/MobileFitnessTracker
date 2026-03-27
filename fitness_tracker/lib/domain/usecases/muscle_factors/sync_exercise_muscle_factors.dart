import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/muscle_stimulus_constants.dart';
import '../../../core/errors/failures.dart';
import '../../entities/exercise.dart';
import '../../entities/muscle_factor.dart';
import '../../repositories/muscle_factor_repository.dart';

class SyncExerciseMuscleFactors {
  SyncExerciseMuscleFactors(this.muscleFactorRepository);

  final MuscleFactorRepository muscleFactorRepository;
  final Uuid _uuid = const Uuid();

  Future<Either<Failure, void>> call(Exercise exercise) async {
    final deleteResult = await muscleFactorRepository
        .deleteMuscleFactorsByExerciseId(exercise.id);

    return deleteResult.fold((failure) async => Left(failure), (_) async {
      final normalizedMuscles = exercise.muscleGroups
          .map((muscle) => muscle.trim().toLowerCase())
          .where(MuscleStimulus.isValidMuscleGroup)
          .toSet()
          .toList();

      if (normalizedMuscles.isEmpty) {
        return const Right(null);
      }

      // Custom exercises currently only capture selected muscle groups, not
      // primary/secondary weighting, so we treat each selected group as a
      // fully engaged muscle for stimulus purposes.
      final factors = normalizedMuscles
          .map(
            (muscleGroup) => MuscleFactor(
              id: _uuid.v4(),
              exerciseId: exercise.id,
              muscleGroup: muscleGroup,
              factor: 1.0,
            ),
          )
          .toList();

      return muscleFactorRepository.addMuscleFactorsBatch(factors);
    });
  }
}
