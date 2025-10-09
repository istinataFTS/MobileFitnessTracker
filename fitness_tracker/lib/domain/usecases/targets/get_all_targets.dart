import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/target.dart';
import '../../repositories/target_repository.dart';

class GetAllTargets {
  final TargetRepository repository;

  const GetAllTargets(this.repository);

  Future<Either<Failure, List<Target>>> call() async {
    return await repository.getAllTargets();
  }
}