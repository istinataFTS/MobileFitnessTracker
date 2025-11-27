import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/nutrition_log.dart';
import '../../repositories/nutrition_log_repository.dart';

class UpdateNutritionLog {
  final NutritionLogRepository repository;

  const UpdateNutritionLog(this.repository);

  Future<Either<Failure, void>> call(NutritionLog log) async {
    return await repository.updateLog(log);
  }
}