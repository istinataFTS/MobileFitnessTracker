import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/target_repository.dart';

class DeleteTarget {
  final TargetRepository repository;

  const DeleteTarget(this.repository);

  Future<Either<Failure, void>> call(String muscleGroup) async {
    return await repository.deleteTarget(muscleGroup);
  }
}