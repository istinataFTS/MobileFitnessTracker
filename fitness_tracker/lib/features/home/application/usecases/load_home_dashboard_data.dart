import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../domain/entities/nutrition_log.dart';
import '../../../../domain/repositories/app_session_repository.dart';
import '../../../../domain/services/muscle_load_resolver.dart';
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
    required MuscleLoadResolver muscleLoadResolver,
    required AppSessionRepository appSessionRepository,
  })  : _getAllTargets = getAllTargets,
        _getWeeklySets = getWeeklySets,
        _getLogsForDate = getLogsForDate,
        _getDailyMacros = getDailyMacros,
        _muscleLoadResolver = muscleLoadResolver,
        _appSessionRepository = appSessionRepository;

  final GetAllTargets _getAllTargets;
  final GetWeeklySets _getWeeklySets;
  final GetLogsForDate _getLogsForDate;
  final GetDailyMacros _getDailyMacros;
  final MuscleLoadResolver _muscleLoadResolver;
  final AppSessionRepository _appSessionRepository;

  Future<Either<Failure, HomeDashboardData>> call() async {
    final targetsResult = await _getAllTargets();

    return targetsResult.fold(
      (Failure failure) async => Left<Failure, HomeDashboardData>(failure),
      (targets) async {
        final weeklySetsResult = await _getWeeklySets();

        return weeklySetsResult.fold(
          (Failure failure) async => Left<Failure, HomeDashboardData>(failure),
          (weeklySets) async {
            final List<NutritionLog> todaysLogs = await _loadTodayLogs();
            final Map<String, double> dailyMacros = await _loadDailyMacros();
            final Map<String, int> muscleSetCounts =
                await _loadMuscleSetCounts();

            return Right<Failure, HomeDashboardData>(
              HomeDashboardData(
                targets: targets,
                weeklySets: weeklySets,
                todaysLogs: todaysLogs,
                dailyMacros: dailyMacros,
                muscleSetCounts: muscleSetCounts,
              ),
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

  Future<Map<String, int>> _loadMuscleSetCounts() async {
    final sessionResult = await _appSessionRepository.getCurrentSession();
    final String? userId = sessionResult.fold((_) => null, (s) => s.user?.id);
    if (userId == null) return const <String, int>{};

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final result = await _muscleLoadResolver.getSetCountsByMuscle(
      userId: userId,
      start: startDate,
      end: now,
    );
    return result.fold((_) => const <String, int>{}, (counts) => counts);
  }
}