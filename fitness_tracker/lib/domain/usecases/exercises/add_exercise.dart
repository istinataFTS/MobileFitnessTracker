import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/exercise.dart';
import '../../repositories/app_session_repository.dart';
import '../../repositories/exercise_repository.dart';

class AddExercise {
  final ExerciseRepository repository;
  final AppSessionRepository appSessionRepository;

  const AddExercise(
    this.repository, {
    required this.appSessionRepository,
  });

  Future<Either<Failure, void>> call(Exercise exercise) async {
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

    return repository.addExercise(preparedExercise);
  }
}
