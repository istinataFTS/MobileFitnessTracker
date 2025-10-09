import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/target.dart';

abstract class TargetRepository {
  Future<Either<Failure, List<Target>>> getAllTargets();
  Future<Either<Failure, Target>> getTargetByMuscleGroup(String muscleGroup);
  Future<Either<Failure, void>> addTarget(Target target);
  Future<Either<Failure, void>> updateTarget(Target target);
  Future<Either<Failure, void>> deleteTarget(String muscleGroup);
  Future<Either<Failure, void>> clearAllTargets();
}