import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/exercise.dart';
import '../../repositories/app_session_repository.dart';
import '../../repositories/exercise_repository.dart';
import '../muscle_factors/sync_exercise_muscle_factors.dart';
import '../muscle_stimulus/rebuild_muscle_stimulus_from_workout_history.dart';

class UpdateExercise {
  final ExerciseRepository repository;
  final AppSessionRepository appSessionRepository;
  final SyncExerciseMuscleFactors syncExerciseMuscleFactors;
  final RebuildMuscleStimulusFromWorkoutHistory
  rebuildMuscleStimulusFromWorkoutHistory;

  const UpdateExercise(
    this.repository, {
    required this.appSessionRepository,
    required this.syncExerciseMuscleFactors,
    required this.rebuildMuscleStimulusFromWorkoutHistory,
  });

  Future<Either<Failure, void>> call(Exercise exercise) async {
    final sessionResult = await appSessionRepository.getCurrentSession();

    final preparedExercise = sessionResult.fold((_) => exercise, (session) {
      if (!session.isAuthenticated || session.user == null) {
        return exercise;
      }

      if (exercise.ownerUserId == session.user!.id) {
        return exercise;
      }

      return exercise.copyWith(ownerUserId: session.user!.id);
    });

    final updateResult = await repository.updateExercise(preparedExercise);

    return updateResult.fold((failure) async => Left(failure), (_) async {
      final syncResult = await syncExerciseMuscleFactors(preparedExercise);
      return syncResult.fold(
        (failure) async => Left(failure),
        (_) async => rebuildMuscleStimulusFromWorkoutHistory(),
      );
    });
  }
}
