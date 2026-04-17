import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/exercise.dart';
import '../../repositories/app_session_repository.dart';
import '../../repositories/exercise_repository.dart';
import '../muscle_factors/sync_exercise_muscle_factors.dart';

class AddExercise {
  final ExerciseRepository repository;
  final AppSessionRepository appSessionRepository;
  final SyncExerciseMuscleFactors syncExerciseMuscleFactors;

  const AddExercise(
    this.repository, {
    required this.appSessionRepository,
    required this.syncExerciseMuscleFactors,
  });

  Future<Either<Failure, void>> call(Exercise exercise) async {
    // Muscle-group canonicalisation (lowercase + trim) is handled at the
    // model boundary in `ExerciseModel` and inside `SyncExerciseMuscleFactors`,
    // so we do not pre-normalise here.  Adding the user id is the only
    // decoration this use case owns.
    final sessionResult = await appSessionRepository.getCurrentSession();

    final preparedExercise = sessionResult.fold(
      (_) => exercise,
      (session) {
        if (!session.isAuthenticated || session.user == null) {
          return exercise;
        }

        return exercise.copyWith(ownerUserId: session.user!.id);
      },
    );

    final addResult = await repository.addExercise(preparedExercise);

    return addResult.fold(
      (failure) async => Left(failure),
      (_) async => syncExerciseMuscleFactors(preparedExercise),
    );
  }
}
