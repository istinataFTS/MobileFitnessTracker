import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../domain/entities/exercise.dart';
import '../../../../domain/entities/target.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../../../domain/usecases/exercises/get_all_exercises.dart';
import '../../../../domain/usecases/targets/get_all_targets.dart';
import '../../../../domain/usecases/workout_sets/get_weekly_sets.dart';
import '../../../../domain/usecases/workout_sets/get_sets_by_date_range.dart';

// ==================== EVENTS ====================

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all home page data
class LoadHomeDataEvent extends HomeEvent {}

/// Event to refresh home data (after workout logged)
class RefreshHomeDataEvent extends HomeEvent {}

// ==================== STATES ====================

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class HomeInitial extends HomeState {}

/// Loading state
class HomeLoading extends HomeState {}

/// Loaded state with comprehensive home data
class HomeLoaded extends HomeState {
  final List<Target> targets;
  final List<WorkoutSet> weeklySets;
  final HomeStats stats;

  const HomeLoaded({
    required this.targets,
    required this.weeklySets,
    required this.stats,
  });

  @override
  List<Object?> get props => [targets, weeklySets, stats];
}

/// Error state
class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== DATA CLASSES ====================

/// Comprehensive statistics for home page display
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

// ==================== BLOC ====================

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetAllTargets getAllTargets;
  final GetWeeklySets getWeeklySets;
  final GetSetsByDateRange getSetsByDateRange;
  final GetAllExercises getAllExercises;

  HomeBloc({
    required this.getAllTargets,
    required this.getWeeklySets,
    required this.getSetsByDateRange,
    required this.getAllExercises,
  }) : super(HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadHomeData);
    on<RefreshHomeDataEvent>(_onRefreshHomeData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());

    final targetsResult = await getAllTargets();

    await targetsResult.fold(
      (failure) async {
        emit(HomeError(failure.message));
      },
      (targets) async {
        final setsResult = await getWeeklySets();

        await setsResult.fold(
          (failure) async {
            emit(HomeError(failure.message));
          },
          (weeklySets) async {
            final stats = await _calculateStats(
              targets: targets,
              weeklySets: weeklySets,
            );

            emit(
              HomeLoaded(
                targets: targets,
                weeklySets: weeklySets,
                stats: stats,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    final targetsResult = await getAllTargets();
    final setsResult = await getWeeklySets();

    await targetsResult.fold(
      (failure) async {
        if (state is HomeLoaded) {
          emit(state);
        } else {
          emit(HomeError(failure.message));
        }
      },
      (targets) async {
        await setsResult.fold(
          (failure) async {
            if (state is HomeLoaded) {
              emit(state);
            } else {
              emit(HomeError(failure.message));
            }
          },
          (weeklySets) async {
            final stats = await _calculateStats(
              targets: targets,
              weeklySets: weeklySets,
            );

            emit(
              HomeLoaded(
                targets: targets,
                weeklySets: weeklySets,
                stats: stats,
              ),
            );
          },
        );
      },
    );
  }

  Future<HomeStats> _calculateStats({
    required List<Target> targets,
    required List<WorkoutSet> weeklySets,
  }) async {
    final totalWeeklyTarget = targets.fold<int>(
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