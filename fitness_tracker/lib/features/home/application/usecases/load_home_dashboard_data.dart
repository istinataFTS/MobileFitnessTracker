import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../domain/entities/nutrition_log.dart';
import '../../../../domain/repositories/app_session_repository.dart';
import '../../../../domain/services/muscle_load_resolver.dart';
import '../../../../domain/usecases/nutrition_logs/get_daily_macros.dart';
import '../../../../domain/usecases/nutrition_logs/get_logs_for_date.dart';
import '../../../../domain/usecases/targets/get_all_targets.dart';
import '../models/home_dashboard_data.dart';

class LoadHomeDashboardData {
  const LoadHomeDashboardData({
    required GetAllTargets getAllTargets,
    required GetLogsForDate getLogsForDate,
    required GetDailyMacros getDailyMacros,
    required MuscleLoadResolver muscleLoadResolver,
    required AppSessionRepository appSessionRepository,
  })  : _getAllTargets = getAllTargets,
        _getLogsForDate = getLogsForDate,
        _getDailyMacros = getDailyMacros,
        _muscleLoadResolver = muscleLoadResolver,
        _appSessionRepository = appSessionRepository;

  final GetAllTargets _getAllTargets;
  final GetLogsForDate _getLogsForDate;
  final GetDailyMacros _getDailyMacros;
  final MuscleLoadResolver _muscleLoadResolver;
  final AppSessionRepository _appSessionRepository;

  Future<Either<Failure, HomeDashboardData>> call() async {
    final targetsResult = await _getAllTargets();

    return targetsResult.fold(
      (Failure failure) async => Left<Failure, HomeDashboardData>(failure),
      (targets) async {
        final List<NutritionLog> todaysLogs = await _loadTodayLogs();
        final Map<String, double> dailyMacros = await _loadDailyMacros();
        final _WeeklyMuscleLoad muscleLoad = await _loadWeeklyMuscleLoad();

        return Right<Failure, HomeDashboardData>(
          HomeDashboardData(
            targets: targets,
            todaysLogs: todaysLogs,
            dailyMacros: dailyMacros,
            muscleSetCounts: muscleLoad.countsByMuscle,
            weeklySetCount: muscleLoad.totalSetCount,
          ),
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

  /// Resolves both the per-muscle counts and the total weekly set count via
  /// [MuscleLoadResolver] so the body map, the muscle-group progress list,
  /// and the "Sets" stat card all derive from the same pipeline. Guest
  /// sessions or resolver errors collapse to the empty/zero defaults rather
  /// than surface as a dashboard load failure.
  Future<_WeeklyMuscleLoad> _loadWeeklyMuscleLoad() async {
    final sessionResult = await _appSessionRepository.getCurrentSession();
    final String? userId = sessionResult.fold((_) => null, (s) => s.user?.id);
    if (userId == null) return const _WeeklyMuscleLoad.empty();

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final countsResult = await _muscleLoadResolver.getSetCountsByMuscle(
      userId: userId,
      start: startDate,
      end: now,
    );
    final totalResult = await _muscleLoadResolver.getTotalSetCount(
      userId: userId,
      start: startDate,
      end: now,
    );

    return _WeeklyMuscleLoad(
      countsByMuscle: countsResult.fold(
        (_) => const <String, int>{},
        (counts) => counts,
      ),
      totalSetCount: totalResult.fold((_) => 0, (count) => count),
    );
  }
}

class _WeeklyMuscleLoad {
  const _WeeklyMuscleLoad({
    required this.countsByMuscle,
    required this.totalSetCount,
  });

  const _WeeklyMuscleLoad.empty()
      : countsByMuscle = const <String, int>{},
        totalSetCount = 0;

  final Map<String, int> countsByMuscle;
  final int totalSetCount;
}
