import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/nutrition_log.dart';
import '../../repositories/nutrition_log_repository.dart';

class GetLogsByDateRange {
  final NutritionLogRepository repository;

  const GetLogsByDateRange(this.repository);

  Future<Either<Failure, List<NutritionLog>>> call({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await repository.getLogsByDateRange(startDate, endDate);
  }
}