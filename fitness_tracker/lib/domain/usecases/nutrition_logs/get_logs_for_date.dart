import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/nutrition_log.dart';
import '../../repositories/nutrition_log_repository.dart';

class GetLogsForDate {
  final NutritionLogRepository repository;

  const GetLogsForDate(this.repository);

  Future<Either<Failure, List<NutritionLog>>> call(DateTime date) async {
    return await repository.getLogsForDate(date);
  }
}