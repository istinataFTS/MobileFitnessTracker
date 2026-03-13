import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
import '../../domain/entities/nutrition_log.dart';
import '../../domain/repositories/nutrition_log_repository.dart';
import '../datasources/local/nutrition_log_local_datasource.dart';
import '../models/nutrition_log_model.dart';

class NutritionLogRepositoryImpl implements NutritionLogRepository {
  final NutritionLogLocalDataSource localDataSource;

  const NutritionLogRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<NutritionLog>>> getAllLogs() {
    return RepositoryGuard.run(() async {
      return localDataSource.getAllLogs();
    });
  }

  @override
  Future<Either<Failure, NutritionLog?>> getLogById(String id) {
    return RepositoryGuard.run(() async {
      return localDataSource.getLogById(id);
    });
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getLogsByDate(
    DateTime date,
  ) {
    return RepositoryGuard.run(() async {
      return localDataSource.getLogsByDate(date);
    });
  }

  Future<Either<Failure, List<NutritionLog>>> getLogsForDate(
    DateTime date,
  ) {
    return getLogsByDate(date);
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return RepositoryGuard.run(() async {
      return localDataSource.getLogsByDateRange(startDate, endDate);
    });
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getLogsByMealId(
    String mealId,
  ) {
    return RepositoryGuard.run(() async {
      return localDataSource.getLogsByMealId(mealId);
    });
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getTodayLogs() {
    return RepositoryGuard.run(() async {
      return localDataSource.getTodayLogs();
    });
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getWeeklyLogs() {
    return RepositoryGuard.run(() async {
      return localDataSource.getWeeklyLogs();
    });
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getMealLogs() {
    return RepositoryGuard.run(() async {
      return localDataSource.getMealLogs();
    });
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getDirectMacroLogs() {
    return RepositoryGuard.run(() async {
      return localDataSource.getDirectMacroLogs();
    });
  }

  @override
  Future<Either<Failure, void>> addLog(NutritionLog log) {
    return RepositoryGuard.run(() async {
      final NutritionLogModel model = NutritionLogModel.fromEntity(log);
      model.validate();
      await localDataSource.insertLog(model);
    });
  }

  @override
  Future<Either<Failure, void>> updateLog(NutritionLog log) {
    return RepositoryGuard.run(() async {
      final NutritionLogModel model = NutritionLogModel.fromEntity(log);
      model.validate();
      await localDataSource.updateLog(model);
    });
  }

  @override
  Future<Either<Failure, void>> deleteLog(String id) {
    return RepositoryGuard.run(() async {
      await localDataSource.deleteLog(id);
    });
  }

  @override
  Future<Either<Failure, void>> deleteLogsByDate(DateTime date) {
    return RepositoryGuard.run(() async {
      await localDataSource.deleteLogsByDate(date);
    });
  }

  @override
  Future<Either<Failure, void>> deleteLogsByMealId(String mealId) {
    return RepositoryGuard.run(() async {
      await localDataSource.deleteLogsByMealId(mealId);
    });
  }

  @override
  Future<Either<Failure, void>> clearAllLogs() {
    return RepositoryGuard.run(() async {
      await localDataSource.clearAllLogs();
    });
  }

  @override
  Future<Either<Failure, int>> getLogsCount() {
    return RepositoryGuard.run(() async {
      final List<NutritionLog> logs = await localDataSource.getAllLogs();
      return logs.length;
    });
  }

  @override
  Future<Either<Failure, DailyMacros>> getDailyMacros(DateTime date) {
    return RepositoryGuard.run(() async {
      final Map<String, dynamic> result =
          await localDataSource.getDailyMacros(date);

      return DailyMacros(
        totalCarbs: result['totalCarbs'] ?? 0.0,
        totalProtein: result['totalProtein'] ?? 0.0,
        totalFat: result['totalFat'] ?? 0.0,
        totalCalories: result['totalCalories'] ?? 0.0,
        date: date,
        logsCount: (result['logsCount'] ?? 0.0).round(),
      );
    });
  }
}