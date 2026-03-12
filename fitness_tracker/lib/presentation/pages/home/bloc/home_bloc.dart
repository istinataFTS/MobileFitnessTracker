import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/entities/exercise.dart';
import '../../../../domain/entities/nutrition_log.dart';
import '../../../../domain/entities/target.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../../../domain/usecases/exercises/get_all_exercises.dart';
import '../../../../domain/usecases/nutrition_logs/get_daily_macros.dart';
import '../../../../domain/usecases/nutrition_logs/get_logs_for_date.dart';
import '../../../../domain/usecases/targets/get_all_targets.dart';
import '../../../../domain/usecases/workout_sets/get_weekly_sets.dart';
import '../../../../domain/usecases/workout_sets/get_sets_by_date_range.dart';

// ==================== EVENTS ====================

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeDataEvent extends HomeEvent {}

class RefreshHomeDataEvent extends HomeEvent {}

// ==================== STATES ====================

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Target> targets;
  final List<WorkoutSet> weeklySets;
  final HomeStats stats;
  final HomeNutritionStats nutritionStats;

  const HomeLoaded({
    required this.targets,
    required this.weeklySets,
    required this.stats,
    required this.nutritionStats,
  });

  List<Target> get trainingTargets =>
      targets.where((target) => target.isWeeklyMuscleTarget).toList();

  List<Target> get macroTargets =>
      targets.where((target) => target.isDailyMacroTarget).toList();

  @override
  List<Object?> get props => [targets, weeklySets, stats, nutritionStats];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== DATA CLASSES ====================

class HomeStats extends Equatable {
  final int totalWeeklySets;
  final int totalWeeklyTarget;
  final int remainingTarget;
  final int trainedMuscleCount;
  final double progressPercentage;

  const HomeStats({
    required this.totalWeeklySets,
    required this.totalWeeklyTarget,
    required this.remainingTarget,
    required this.trainedMuscleCount,
    required this.progressPercentage,
  });

  bool get hasMetTarget => totalWeeklySets >= totalWeeklyTarget;
  bool get hasTargets => totalWeeklyTarget > 0;
  bool get hasWorkouts => totalWeeklySets > 0;

  @override
  List<Object?> get props => [
        totalWeeklySets,
        totalWeeklyTarget,
        remainingTarget,
        trainedMuscleCount,
        progressPercentage,
      ];
}

class MacroProgress extends Equatable {
  final String key;
  final String label;
  final double actual;
  final double target;
  final String unit;

  const MacroProgress({
    required this.key,
    required this.label,
    required this.actual,
    required this.target,
    required this.unit,
  });

  bool get hasTarget => target > 0;

  double get progress =>
      hasTarget ? (actual / target).clamp(0.0, 1.0) : 0.0;

  double get remaining => hasTarget ? (target - actual).clamp(0.0, target) : 0.0;

  bool get isComplete => hasTarget && actual >= target;

  @override
  List<Object?> get props => [key, label, actual, target, unit];
}

class HomeNutritionStats extends Equatable {
  final List<NutritionLog> todaysLogs;
  final Map<String, double> dailyMacros;
  final List<MacroProgress> macroProgressItems;

  const HomeNutritionStats({
    required this.todaysLogs,
    required this.dailyMacros,
    required this.macroProgressItems,
  });

  double get totalProtein => dailyMacros['protein'] ?? 0.0;
  double get totalCarbs => dailyMacros['carbs'] ?? 0.0;
  double get totalFats => dailyMacros['fats'] ?? 0.0;
  double get totalCalories => dailyMacros['calories'] ?? 0.0;

  bool get hasLogs => todaysLogs.isNotEmpty;

  @override
  List<Object?> get props => [todaysLogs, dailyMacros, macroProgressItems];
}

// ==================== BLOC ====================

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetAllTargets getAllTargets;
  final GetWeeklySets getWeeklySets;
  final GetSetsByDateRange getSetsByDateRange;
  final GetAllExercises getAllExercises;
  final GetLogsForDate getLogsForDate;
  final GetDailyMacros getDailyMacros;

  HomeBloc({
    required this.getAllTargets,
    required this.getWeeklySets,
    required this.getSetsByDateRange,
    required this.getAllExercises,
    required this.getLogsForDate,
    required this.getDailyMacros,
  }) : super(HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadHomeData);
    on<RefreshHomeDataEvent>(_onRefreshHomeData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    await _loadAndEmitHomeState(emit);
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    await _loadAndEmitHomeState(emit, preserveCurrentStateOnFailure: true);
  }

  Future<void> _loadAndEmitHomeState(
    Emitter<HomeState> emit, {
    bool preserveCurrentStateOnFailure = false,
  }) async {
    final targetsResult = await getAllTargets();

    await targetsResult.fold(
      (failure) async {
        _emitErrorOrPreserve(
          emit,
          failure.message,
          preserveCurrentStateOnFailure,
        );
      },
      (targets) async {
        final setsResult = await getWeeklySets();

        await setsResult.fold(
          (failure) async {
            _emitErrorOrPreserve(
              emit,
              failure.message,
              preserveCurrentStateOnFailure,
            );
          },
          (weeklySets) async {
            final stats = await _calculateStats(
              targets: targets,
              weeklySets: weeklySets,
            );

            final nutritionStats = await _calculateNutritionStats(
              targets: targets,
            );

            emit(
              HomeLoaded(
                targets: targets,
                weeklySets: weeklySets,
                stats: stats,
                nutritionStats: nutritionStats,
              ),
            );
          },
        );
      },
    );
  }

  void _emitErrorOrPreserve(
    Emitter<HomeState> emit,
    String message,
    bool preserveCurrentStateOnFailure,
  ) {
    if (preserveCurrentStateOnFailure && state is HomeLoaded) {
      emit(state);
      return;
    }

    emit(HomeError(message));
  }

  Future<HomeStats> _calculateStats({
    required List<Target> targets,
    required List<WorkoutSet> weeklySets,
  }) async {
    final trainingTargets = targets.where((target) => target.isWeeklyMuscleTarget);

    final totalWeeklyTarget = trainingTargets.fold<int>(
      0,
      (sum, target) => sum + target.weeklyGoal,
    );

    final totalWeeklySets = weeklySets.length;

    final remainingTarget =
        (totalWeeklyTarget - totalWeeklySets).clamp(0, totalWeeklyTarget);

    final progressPercentage = totalWeeklyTarget > 0
        ? ((totalWeeklySets / totalWeeklyTarget) * 100).clamp(0.0, 100.0)
        : 0.0;

    final trainedMuscleCount = await _calculateTrainedMuscleCount();

    return HomeStats(
      totalWeeklySets: totalWeeklySets,
      totalWeeklyTarget: totalWeeklyTarget,
      remainingTarget: remainingTarget,
      trainedMuscleCount: trainedMuscleCount,
      progressPercentage: progressPercentage,
    );
  }

  Future<HomeNutritionStats> _calculateNutritionStats({
    required List<Target> targets,
  }) async {
    final today = DateTime.now();

    final logsResult = await getLogsForDate(today);
    final macrosResult = await getDailyMacros(today);

    final todaysLogs = logsResult.fold<List<NutritionLog>>(
      (_) => <NutritionLog>[],
      (logs) {
        final sortedLogs = [...logs];
        sortedLogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sortedLogs;
      },
    );

    final dailyMacros = macrosResult.fold<Map<String, double>>(
      (_) => {
        'protein': 0.0,
        'carbs': 0.0,
        'fats': 0.0,
        'calories': 0.0,
      },
      (macros) => macros,
    );

    final macroTargets = {
      for (final target in targets.where((target) => target.isDailyMacroTarget))
        target.categoryKey: target.targetValue,
    };

    final macroProgressItems = <MacroProgress>[
      MacroProgress(
        key: 'protein',
        label: 'Protein',
        actual: dailyMacros['protein'] ?? 0.0,
        target: macroTargets['protein'] ?? 0.0,
        unit: 'g',
      ),
      MacroProgress(
        key: 'carbs',
        label: 'Carbs',
        actual: dailyMacros['carbs'] ?? 0.0,
        target: macroTargets['carbs'] ?? 0.0,
        unit: 'g',
      ),
      MacroProgress(
        key: 'fats',
        label: 'Fats',
        actual: dailyMacros['fats'] ?? 0.0,
        target: macroTargets['fats'] ?? 0.0,
        unit: 'g',
      ),
    ];

    return HomeNutritionStats(
      todaysLogs: todaysLogs,
      dailyMacros: dailyMacros,
      macroProgressItems: macroProgressItems,
    );
  }

  Future<int> _calculateTrainedMuscleCount() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final setsResult = await getSetsByDateRange(
      startDate: weekStartDate,
      endDate: today,
    );

    final exercisesResult = await getAllExercises();

    return setsResult.fold(
      (_) => 0,
      (sets) {
        return exercisesResult.fold(
          (_) => 0,
          (exercises) {
            final exerciseMap = <String, Exercise>{
              for (final exercise in exercises) exercise.id: exercise,
            };

            final uniqueMuscles = <String>{};

            for (final set in sets) {
              final exercise = exerciseMap[set.exerciseId];
              if (exercise == null) {
                continue;
              }
              uniqueMuscles.addAll(exercise.muscleGroups);
            }

            return uniqueMuscles.length;
          },
        );
      },
    );
  }
}