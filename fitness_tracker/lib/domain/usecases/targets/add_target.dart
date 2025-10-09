import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/target.dart';
import '../../repositories/target_repository.dart';

class AddTarget {
  final TargetRepository repository;

  const AddTarget(this.repository);

  Future<Either<Failure, void>> call(Target target) async {
    return await repository.addTarget(target);
  }
}