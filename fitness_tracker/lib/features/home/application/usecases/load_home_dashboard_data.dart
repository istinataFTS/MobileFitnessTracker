import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../domain/entities/nutrition_log.dart';
import '../../../../domain/usecases/exercises/get_all_exercises.dart';
import '../../../../domain/usecases/nutrition_logs/get_daily_macros.dart';
import '../../../../domain/usecases/nutrition_logs/get_logs_for_date.dart';
import '../../../../domain/usecases/targets/get_all_targets.dart';
import '../../../../domain/usecases/workout_sets/get_weekly_sets.dart';
import '../models/home_dashboard_data.dart';

class LoadHomeDashboardData {
  const LoadHomeDashboardData({
    required GetAllTargets getAllTargets,
    required GetWeeklySets getWeeklySets,
    required GetLogsForDate getLogsForDate,
    required GetDailyMacros getDailyMacros,
    required GetAllExercises getAllExercises,
  })  : _getAllTargets = getAllTargets,
        _getWeeklySets = getWeeklySets,
        _getLogsForDate = getLogsForDate,
        _getDailyMacros = getDailyMacros,
        _getAllExercises = getAllExercises;

  final GetAllTargets _getAllTargets;
  final GetWeeklySets _getWeeklySets;
  final GetLogsForDate _getLogsForDate;
  final GetDailyMacros _getDailyMacros;
  final GetAllExercises _getAllExercises;

  Future<Either<Failure, HomeDashboardData>> call() async {
    final targetsResult = await _getAllTargets();

    return targetsResult.fold(
      (Failure failure) async => Left<Failure, HomeDashboardData>(failure),
      (targets) async {
        final weeklySetsResult = await _getWeeklySets();

        return weeklySetsResult.fold(
          (Failure failure) async => Left<Failure, HomeDashboardData>(failure),
          (weeklySets) async {
            final exercisesResult = await _getAllExercises();

            return exercisesResult.fold(
              (Failure failure) async =>
                  Left<Failure, HomeDashboardData>(failure),
              (exercises) async {
                final List<NutritionLog> todaysLogs = await _loadTodayLogs();
                final Map<String, double> dailyMacros =
                    await _loadDailyMacros();

                return Right<Failure, HomeDashboardData>(
                  HomeDashboardData(
                    targets: targets,
                    weeklySets: weeklySets,
                    todaysLogs: todaysLogs,
                    dailyMacros: dailyMacros,
                    exercises: exercises,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<NutritionLog>> _loadTodayLogs() async {
    final DateTime today = DateTime.now();
    final logsResult = await _getLogsForDate(today);

    return logsResult.fold<List<NutritionLog>>(
      (_) => <NutritionLog>[],
      (logs) {
        final List<NutritionLog> sortedLogs = <NutritionLog>[...logs]
          ..sort(
            (NutritionLog a, NutritionLog b) =>
                b.createdAt.compareTo(a.createdAt),
          );
        return sortedLogs;
      },
    );
  }

  Future<Map<String, double>> _loadDailyMacros() async {
    final DateTime today = DateTime.now();
    final macrosResult = await _getDailyMacros(today);

    return macrosResult.fold<Map<String, double>>(
      (_) => HomeDashboardData.emptyDailyMacros,
      (macros) => macros,
    );
  }
}