import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/nutrition_log.dart';
import '../../../domain/entities/target.dart';
import '../../../domain/entities/workout_set.dart';
import '../../../domain/usecases/exercises/get_all_exercises.dart';
import '../../../domain/usecases/nutrition_logs/get_daily_macros.dart';
import '../../../domain/usecases/nutrition_logs/get_logs_for_date.dart';
import '../../../domain/usecases/targets/get_all_targets.dart';
import '../../../domain/usecases/workout_sets/get_weekly_sets.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class LoadHomeDataEvent extends HomeEvent {
  const LoadHomeDataEvent();
}

class RefreshHomeDataEvent extends HomeEvent {
  const RefreshHomeDataEvent();
}

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => <Object?>[];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.targets,
    required this.weeklySets,
    required this.todaysLogs,
    required this.dailyMacros,
    required this.exercises,
  });

  final List<Target> targets;
  final List<WorkoutSet> weeklySets;
  final List<NutritionLog> todaysLogs;
  final Map<String, double> dailyMacros;
  final List<Exercise> exercises;

  List<Target> get trainingTargets => targets
      .where((Target target) => target.isWeeklyMuscleTarget)
      .toList(growable: false);

  List<Target> get macroTargets => targets
      .where((Target target) => target.isDailyMacroTarget)
      .toList(growable: false);

  @override
  List<Object?> get props => <Object?>[
        targets,
        weeklySets,
        todaysLogs,
        dailyMacros,
        exercises,
      ];
}

class HomeError extends HomeState {
  const HomeError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required this.getAllTargets,
    required this.getWeeklySets,
    required this.getLogsForDate,
    required this.getDailyMacros,
    required this.getAllExercises,
  }) : super(const HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadHomeData);
    on<RefreshHomeDataEvent>(_onRefreshHomeData);
  }

  final GetAllTargets getAllTargets;
  final GetWeeklySets getWeeklySets;
  final GetLogsForDate getLogsForDate;
  final GetDailyMacros getDailyMacros;
  final GetAllExercises getAllExercises;

  Future<void> _onLoadHomeData(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    await _loadAndEmitHomeState(emit);
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    await _loadAndEmitHomeState(
      emit,
      preserveCurrentStateOnFailure: true,
    );
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
        final weeklySetsResult = await getWeeklySets();

        await weeklySetsResult.fold(
          (failure) async {
            _emitErrorOrPreserve(
              emit,
              failure.message,
              preserveCurrentStateOnFailure,
            );
          },
          (weeklySets) async {
            final exercisesResult = await getAllExercises();

            await exercisesResult.fold(
              (failure) async {
                _emitErrorOrPreserve(
                  emit,
                  failure.message,
                  preserveCurrentStateOnFailure,
                );
              },
              (exercises) async {
                final List<NutritionLog> todaysLogs = await _loadTodayLogs();
                final Map<String, double> dailyMacros =
                    await _loadDailyMacros();

                emit(
                  HomeLoaded(
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

  Future<List<NutritionLog>> _loadTodayLogs() async {
    final DateTime today = DateTime.now();
    final logsResult = await getLogsForDate(today);

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
    final macrosResult = await getDailyMacros(today);

    return macrosResult.fold<Map<String, double>>(
      (_) => _emptyDailyMacros,
      (macros) => macros,
    );
  }

  static const Map<String, double> _emptyDailyMacros = <String, double>{
    'protein': 0.0,
    'carbs': 0.0,
    'fats': 0.0,
    'calories': 0.0,
  };
}