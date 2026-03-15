import 'package:dartz/dartz.dart';

import '../../core/enums/data_source_preference.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
import '../../domain/entities/nutrition_log.dart';
import '../../domain/repositories/nutrition_log_repository.dart';
import '../datasources/local/nutrition_log_local_datasource.dart';
import '../datasources/remote/nutrition_log_remote_datasource.dart';
import '../models/nutrition_log_model.dart';
import '../sync/nutrition_log_sync_coordinator.dart';

class NutritionLogRepositoryImpl implements NutritionLogRepository {
  final NutritionLogLocalDataSource localDataSource;
  final NutritionLogRemoteDataSource remoteDataSource;
  final NutritionLogSyncCoordinator syncCoordinator;

  const NutritionLogRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.syncCoordinator,
  });

  @override
  Future<Either<Failure, List<NutritionLog>>> getAllLogs({
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      switch (sourcePreference) {
        case DataSourcePreference.localOnly:
          return localDataSource.getAllLogs();

        case DataSourcePreference.remoteOnly:
          if (!remoteDataSource.isConfigured) {
            return const <NutritionLog>[];
          }
          return remoteDataSource.getAllLogs();

        case DataSourcePreference.localThenRemote:
          final localLogs = await localDataSource.getAllLogs();
          if (localLogs.isNotEmpty || !remoteDataSource.isConfigured) {
            return localLogs;
          }

          final remoteLogs = await remoteDataSource.getAllLogs();
          if (remoteLogs.isNotEmpty) {
            await localDataSource.replaceAllLogs(
              remoteLogs.map(NutritionLogModel.fromEntity).toList(),
            );
          }
          return remoteLogs;

        case DataSourcePreference.remoteThenLocal:
          if (remoteDataSource.isConfigured) {
            final remoteLogs = await remoteDataSource.getAllLogs();
            if (remoteLogs.isNotEmpty) {
              await localDataSource.replaceAllLogs(
                remoteLogs.map(NutritionLogModel.fromEntity).toList(),
              );
              return remoteLogs;
            }
          }
          return localDataSource.getAllLogs();
      }
    });
  }

  @override
  Future<Either<Failure, NutritionLog?>> getLogById(
    String id, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      switch (sourcePreference) {
        case DataSourcePreference.localOnly:
          return localDataSource.getLogById(id);

        case DataSourcePreference.remoteOnly:
          if (!remoteDataSource.isConfigured) {
            return null;
          }
          return remoteDataSource.getLogById(id);

        case DataSourcePreference.localThenRemote:
          final localLog = await localDataSource.getLogById(id);
          if (localLog != null) {
            return localLog;
          }

          if (!remoteDataSource.isConfigured) {
            return null;
          }

          final remoteLog = await remoteDataSource.getLogById(id);
          if (remoteLog != null) {
            await localDataSource.insertLog(
              NutritionLogModel.fromEntity(remoteLog),
            );
          }
          return remoteLog;

        case DataSourcePreference.remoteThenLocal:
          if (remoteDataSource.isConfigured) {
            final remoteLog = await remoteDataSource.getLogById(id);
            if (remoteLog != null) {
              final existingLocal = await localDataSource.getLogById(id);
              if (existingLocal == null) {
                await localDataSource.insertLog(
                  NutritionLogModel.fromEntity(remoteLog),
                );
              } else {
                await localDataSource.updateLog(
                  NutritionLogModel.fromEntity(remoteLog),
                );
              }
              return remoteLog;
            }
          }
          return localDataSource.getLogById(id);
      }
    });
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getLogsByDate(
    DateTime date, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      if (sourcePreference == DataSourcePreference.localOnly ||
          !remoteDataSource.isConfigured) {
        return localDataSource.getLogsByDate(date);
      }
      return remoteDataSource.getLogsByDate(date);
    });
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getLogsForDate(
    DateTime date, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return getLogsByDate(date, sourcePreference: sourcePreference);
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      if (sourcePreference == DataSourcePreference.localOnly ||
          !remoteDataSource.isConfigured) {
        return localDataSource.getLogsByDateRange(startDate, endDate);
      }
      return remoteDataSource.getLogsByDateRange(startDate, endDate);
    });
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getLogsByMealId(
    String mealId, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      if (sourcePreference == DataSourcePreference.localOnly ||
          !remoteDataSource.isConfigured) {
        return localDataSource.getLogsByMealId(mealId);
      }
      return remoteDataSource.getLogsByMealId(mealId);
    });
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getTodayLogs({
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      if (sourcePreference == DataSourcePreference.localOnly ||
          !remoteDataSource.isConfigured) {
        return localDataSource.getTodayLogs();
      }
      return remoteDataSource.getLogsByDate(DateTime.now());
    });
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getWeeklyLogs({
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      if (sourcePreference == DataSourcePreference.localOnly ||
          !remoteDataSource.isConfigured) {
        return localDataSource.getWeeklyLogs();
      }

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

      return remoteDataSource.getLogsByDateRange(startDate, now);
    });
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getMealLogs({
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      if (sourcePreference == DataSourcePreference.localOnly ||
          !remoteDataSource.isConfigured) {
        return localDataSource.getMealLogs();
      }

      final logs = await remoteDataSource.getAllLogs();
      return logs.where((log) => log.isMealLog).toList();
    });
  }

  @override
  Future<Either<Failure, List<NutritionLog>>> getDirectMacroLogs({
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      if (sourcePreference == DataSourcePreference.localOnly ||
          !remoteDataSource.isConfigured) {
        return localDataSource.getDirectMacroLogs();
      }

      final logs = await remoteDataSource.getAllLogs();
      return logs.where((log) => log.isDirectMacroLog).toList();
    });
  }

  @override
  Future<Either<Failure, void>> addLog(NutritionLog log) {
    return RepositoryGuard.run(() async {
      await syncCoordinator.persistAddedLog(log);
    });
  }

  @override
  Future<Either<Failure, void>> updateLog(NutritionLog log) {
    return RepositoryGuard.run(() async {
      await syncCoordinator.persistUpdatedLog(log);
    });
  }

  @override
  Future<Either<Failure, void>> deleteLog(String id) {
    return RepositoryGuard.run(() async {
      await syncCoordinator.persistDeletedLog(id);
    });
  }

  @override
  Future<Either<Failure, void>> deleteLogsByDate(DateTime date) {
    return RepositoryGuard.run(() async {
      final logs = await localDataSource.getLogsByDate(date);
      for (final log in logs) {
        await syncCoordinator.persistDeletedLog(log.id);
      }
    });
  }

  @override
  Future<Either<Failure, void>> deleteLogsByMealId(String mealId) {
    return RepositoryGuard.run(() async {
      final logs = await localDataSource.getLogsByMealId(mealId);
      for (final log in logs) {
        await syncCoordinator.persistDeletedLog(log.id);
      }
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
      final logs = await localDataSource.getAllLogs();
      return logs.length;
    });
  }

  @override
  Future<Either<Failure, DailyMacros>> getDailyMacros(
    DateTime date, {
    DataSourcePreference sourcePreference = DataSourcePreference.localOnly,
  }) {
    return RepositoryGuard.run(() async {
      final Map<String, dynamic> result = sourcePreference ==
                  DataSourcePreference.localOnly ||
              !remoteDataSource.isConfigured
          ? await localDataSource.getDailyMacros(date)
          : _aggregateDailyMacros(await remoteDataSource.getLogsByDate(date));

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

  @override
  Future<Either<Failure, void>> syncPendingLogs() {
    return RepositoryGuard.run(() async {
      await syncCoordinator.syncPendingChanges();
    });
  }

  Map<String, double> _aggregateDailyMacros(List<NutritionLog> logs) {
    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;
    double totalCalories = 0;

    for (final log in logs) {
      totalCarbs += log.carbsGrams;
      totalProtein += log.proteinGrams;
      totalFat += log.fatGrams;
      totalCalories += log.calories;
    }

    return {
      'totalCarbs': totalCarbs,
      'totalProtein': totalProtein,
      'totalFat': totalFat,
      'totalCalories': totalCalories,
      'logsCount': logs.length.toDouble(),
    };
  }
}