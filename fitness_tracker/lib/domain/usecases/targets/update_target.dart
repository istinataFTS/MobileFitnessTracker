import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/target.dart';
import '../../repositories/target_repository.dart';

class UpdateTarget {
  final TargetRepository repository;

  const UpdateTarget(this.repository);

  Future<Either<Failure, void>> call(Target target) async {
    return await repository.updateTarget(target);
  }
}