import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/nutrition_log.dart';
import '../../repositories/nutrition_log_repository.dart';

class GetAllNutritionLogs {
  final NutritionLogRepository repository;

  const GetAllNutritionLogs(this.repository);

  Future<Either<Failure, List<NutritionLog>>> call() async {
    return await repository.getAllLogs();
  }
}