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
    // Normalize muscle group names to lowercase at save time so the stored
    // data is always consistent, regardless of how the exercise was built
    // (UI chip selection, import, sync, etc.).
    final normalizedExercise = exercise.copyWith(
      muscleGroups: exercise.muscleGroups
          .map((m) => m.toLowerCase().trim())
          .toList(),
    );

    final sessionResult = await appSessionRepository.getCurrentSession();

    final preparedExercise = sessionResult.fold(
      (_) => normalizedExercise,
      (session) {
        if (!session.isAuthenticated || session.user == null) {
          return normalizedExercise;
        }

        return normalizedExercise.copyWith(ownerUserId: session.user!.id);
      },
    );

    final addResult = await repository.addExercise(preparedExercise);

    return addResult.fold(
      (failure) async => Left(failure),
      (_) async => syncExerciseMuscleFactors(preparedExercise),
    );
  }
}
