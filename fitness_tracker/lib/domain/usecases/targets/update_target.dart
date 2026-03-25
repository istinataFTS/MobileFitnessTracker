import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/target.dart';
import '../../repositories/app_session_repository.dart';
import '../../repositories/target_repository.dart';

class UpdateTarget {
  final TargetRepository repository;
  final AppSessionRepository appSessionRepository;

  const UpdateTarget(
    this.repository, {
    required this.appSessionRepository,
  });

  Future<Either<Failure, void>> call(Target target) async {
    final sessionResult = await appSessionRepository.getCurrentSession();

    final preparedTarget = sessionResult.fold(
      (_) => target,
      (session) {
        if (!session.isAuthenticated || session.user == null) {
          return target;
        }

        return target.copyWith(ownerUserId: session.user!.id);
      },
    );

    return repository.updateTarget(preparedTarget);
  }
}