import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/nutrition_log.dart';
import '../../repositories/nutrition_log_repository.dart';

class GetLogsByMealId {
  final NutritionLogRepository repository;

  const GetLogsByMealId(this.repository);

  Future<Either<Failure, List<NutritionLog>>> call(String mealId) async {
    return await repository.getLogsByMealId(mealId);
  }
}