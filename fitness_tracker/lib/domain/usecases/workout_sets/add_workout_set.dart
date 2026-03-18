import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/workout_set.dart';
import '../../repositories/app_session_repository.dart';
import '../../repositories/workout_set_repository.dart';

class AddWorkoutSet {
  final WorkoutSetRepository repository;
  final AppSessionRepository appSessionRepository;

  const AddWorkoutSet(
    this.repository, {
    required this.appSessionRepository,
  });

  Future<Either<Failure, void>> call(WorkoutSet set) async {
    final sessionResult = await appSessionRepository.getCurrentSession();

    final preparedSet = sessionResult.fold(
      (_) => set,
      (session) {
        if (!session.isAuthenticated || session.user == null) {
          return set;
        }

        return set.copyWith(ownerUserId: session.user!.id);
      },
    );

    return repository.addSet(preparedSet);
  }
}