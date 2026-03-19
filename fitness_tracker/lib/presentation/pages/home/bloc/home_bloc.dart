import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/nutrition_log.dart';
import '../../../../domain/entities/target.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../../../domain/usecases/nutrition_logs/get_daily_macros.dart';
import '../../../../domain/usecases/nutrition_logs/get_logs_for_date.dart';
import '../../../../domain/usecases/targets/get_all_targets.dart';
import '../../../../domain/usecases/workout_sets/get_weekly_sets.dart';

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
  final List<NutritionLog> todaysLogs;
  final Map<String, double> dailyMacros;

  const HomeLoaded({
    required this.targets,
    required this.weeklySets,
    required this.todaysLogs,
    required this.dailyMacros,
  });

  List<Target> get trainingTargets =>
      targets.where((target) => target.isWeeklyMuscleTarget).toList();

  List<Target> get macroTargets =>
      targets.where((target) => target.isDailyMacroTarget).toList();

  @override
  List<Object?> get props => [
        targets,
        weeklySets,
        todaysLogs,
        dailyMacros,
      ];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== BLOC ====================

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetAllTargets getAllTargets;
  final GetWeeklySets getWeeklySets;
  final GetLogsForDate getLogsForDate;
  final GetDailyMacros getDailyMacros;

  HomeBloc({
    required this.getAllTargets,
    required this.getWeeklySets,
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
            final todaysLogs = await _loadTodayLogs();
            final dailyMacros = await _loadDailyMacros();

            emit(
              HomeLoaded(
                targets: targets,
                weeklySets: weeklySets,
                todaysLogs: todaysLogs,
                dailyMacros: dailyMacros,
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

  Future<List<NutritionLog>> _loadTodayLogs() async {
    final today = DateTime.now();
    final logsResult = await getLogsForDate(today);

    return logsResult.fold<List<NutritionLog>>(
      (_) => <NutritionLog>[],
      (logs) {
        final sortedLogs = [...logs];
        sortedLogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sortedLogs;
      },
    );
  }

  Future<Map<String, double>> _loadDailyMacros() async {
    final today = DateTime.now();
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