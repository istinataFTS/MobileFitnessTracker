import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/nutrition_log.dart';
import '../../repositories/nutrition_log_repository.dart';

class AddNutritionLog {
  final NutritionLogRepository repository;

  const AddNutritionLog(this.repository);

  Future<Either<Failure, void>> call(NutritionLog log) async {
    return await repository.addLog(log);
  }
}