import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/muscle_factor.dart';
import '../../repositories/muscle_factor_repository.dart';

/// Returns the saved [MuscleFactor] rows for a single exercise.
///
/// Used by the Library exercise dialog to pre-populate factor sliders when
/// the user opens an existing exercise for editing.
class GetMuscleFactorsForExercise {
  const GetMuscleFactorsForExercise(this._repository);

  final MuscleFactorRepository _repository;

  Future<Either<Failure, List<MuscleFactor>>> call(String exerciseId) =>
      _repository.getFactorsForExercise(exerciseId);
}
