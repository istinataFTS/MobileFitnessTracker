import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/nutrition_log_repository.dart';

/// Use case for calculating total daily macros from all nutrition logs
/// Returns aggregated totals: protein, carbs, fats, calories
class GetDailyMacros {
  final NutritionLogRepository repository;

  const GetDailyMacros(this.repository);

  /// Calculate total macros for a specific date
  /// Returns map with keys: 'protein', 'carbs', 'fats', 'calories'
  Future<Either<Failure, Map<String, double>>> call(DateTime date) async {
    final result = await repository.getLogsForDate(date);
    
    return result.fold(
      (failure) => Left(failure),
      (logs) {
        double totalProtein = 0;
        double totalCarbs = 0;
        double totalFats = 0;
        double totalCalories = 0;

        for (final log in logs) {
          totalProtein += log.protein;
          totalCarbs += log.carbs;
          totalFats += log.fats;
          totalCalories += log.calories;
        }

        return Right({
          'protein': totalProtein,
          'carbs': totalCarbs,
          'fats': totalFats,
          'calories': totalCalories,
        });
      },
    );
  }
}