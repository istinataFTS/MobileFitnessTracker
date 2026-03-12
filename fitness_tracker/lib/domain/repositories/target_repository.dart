import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/target.dart';

abstract class TargetRepository {
  Future<Either<Failure, List<Target>>> getAllTargets();

  Future<Either<Failure, Target?>> getTargetById(String id);

  Future<Either<Failure, Target?>> getTargetByTypeAndCategory(
    TargetType type,
    String categoryKey,
    TargetPeriod period,
  );

  Future<Either<Failure, void>> addTarget(Target target);

  Future<Either<Failure, void>> updateTarget(Target target);

  Future<Either<Failure, void>> deleteTarget(String targetId);

  Future<Either<Failure, void>> clearAllTargets();
}