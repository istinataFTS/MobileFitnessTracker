import 'package:dartz/dartz.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/nutrition_log.dart';
import '../../domain/repositories/nutrition_log_repository.dart';
import '../datasources/local/nutrition_log_local_datasource.dart';
import '../models/nutrition_log_model.dart';

class NutritionLogRepositoryImpl implements NutritionLogRepository {
  final NutritionLogLocalDataSource localDataSource;

  const NutritionLogRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<NutritionLog>>> getAllLogs() async {
    try {
      final logs = await localDataSource.getAllLogs();
      return Right(logs);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, NutritionLog?>> getLogById(String id) async {
    try {
      final log = await localDataSource.getLogById(id);
      return Right(log);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getLogsByDate(
    DateTime date,
  ) async {
    try {
      final logs = await localDataSource.getLogsByDate(date);
      return Right(logs);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  // Keeps compatibility with existing use cases that call repository.getLogsForDate(...)
  Future<Either<Failure, List<NutritionLog>>> getLogsForDate(
    DateTime date,
  ) async {
    return getLogsByDate(date);
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final logs = await localDataSource.getLogsByDateRange(startDate, endDate);
      return Right(logs);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getLogsByMealId(
    String mealId,
  ) async {
    try {
      final logs = await localDataSource.getLogsByMealId(mealId);
      return Right(logs);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getTodayLogs() async {
    try {
      final logs = await localDataSource.getTodayLogs();
      return Right(logs);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getWeeklyLogs() async {
    try {
      final logs = await localDataSource.getWeeklyLogs();
      return Right(logs);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getMealLogs() async {
    try {
      final logs = await localDataSource.getMealLogs();
      return Right(logs);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getDirectMacroLogs() async {
    try {
      final logs = await localDataSource.getDirectMacroLogs();
      return Right(logs);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addLog(NutritionLog log) async {
    try {
      final model = NutritionLogModel.fromEntity(log);
      model.validate();
      await localDataSource.insertLog(model);
      return const Right(null);
    } on ArgumentError catch (e) {
      return Left(ValidationFailure(e.message.toString()));
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateLog(NutritionLog log) async {
    try {
      final model = NutritionLogModel.fromEntity(log);
      model.validate();
      await localDataSource.updateLog(model);
      return const Right(null);
    } on ArgumentError catch (e) {
      return Left(ValidationFailure(e.message.toString()));
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLog(String id) async {
    try {
      await localDataSource.deleteLog(id);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLogsByDate(DateTime date) async {
    try {
      await localDataSource.deleteLogsByDate(date);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLogsByMealId(String mealId) async {
    try {
      await localDataSource.deleteLogsByMealId(mealId);
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllLogs() async {
    try {
      await localDataSource.clearAllLogs();
      return const Right(null);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getLogsCount() async {
    try {
      final logs = await localDataSource.getAllLogs();
      return Right(logs.length);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, DailyMacros>> getDailyMacros(DateTime date) async {
    try {
      final result = await localDataSource.getDailyMacros(date);

      final dailyMacros = DailyMacros(
        totalCarbs: result['totalCarbs'] ?? 0.0,
        totalProtein: result['totalProtein'] ?? 0.0,
        totalFat: result['totalFat'] ?? 0.0,
        totalCalories: result['totalCalories'] ?? 0.0,
        date: date,
        logsCount: (result['logsCount'] ?? 0.0).round(),
      );

      return Right(dailyMacros);
    } on CacheDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }
}