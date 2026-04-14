import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/bloc_effects_mixin.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../../../domain/usecases/muscle_stimulus/record_workout_set.dart';
import '../../../../domain/usecases/workout_sets/add_workout_set.dart';
import '../../../../domain/usecases/workout_sets/get_weekly_sets.dart';

abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

class AddWorkoutSetEvent extends WorkoutEvent {
  final WorkoutSet workoutSet;

  const AddWorkoutSetEvent(this.workoutSet);

  @override
  List<Object?> get props => [workoutSet];
}

class LoadWeeklySetsEvent extends WorkoutEvent {
  const LoadWeeklySetsEvent();
}

class RefreshWeeklySetsEvent extends WorkoutEvent {
  const RefreshWeeklySetsEvent();
}

abstract class WorkoutState extends Equatable {
  const WorkoutState();

  @override
  List<Object?> get props => [];
}

class WorkoutInitial extends WorkoutState {}

class WorkoutLoading extends WorkoutState {}

class WorkoutLoaded extends WorkoutState {
  final List<WorkoutSet> weeklySets;

  const WorkoutLoaded(this.weeklySets);

  @override
  List<Object?> get props => [weeklySets];
}

class WorkoutError extends WorkoutState {
  final String message;

  const WorkoutError(this.message);

  @override
  List<Object?> get props => [message];
}

abstract class WorkoutUiEffect {
  const WorkoutUiEffect();
}

class WorkoutLoggedEffect extends WorkoutUiEffect {
  final String message;
  final List<String> affectedMuscles;

  const WorkoutLoggedEffect({
    required this.message,
    required this.affectedMuscles,
  });
}

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState>
    with BlocEffectsMixin<WorkoutState, WorkoutUiEffect> {
  final AddWorkoutSet addWorkoutSet;
  final GetWeeklySets getWeeklySets;
  final RecordWorkoutSet recordWorkoutSet;

  List<WorkoutSet> _cachedWeeklySets = [];

  WorkoutBloc({
    required this.addWorkoutSet,
    required this.getWeeklySets,
    required this.recordWorkoutSet,
  }) : super(WorkoutInitial()) {
    on<AddWorkoutSetEvent>(_onAddWorkoutSet);
    on<LoadWeeklySetsEvent>(_onLoadWeeklySets);
    on<RefreshWeeklySetsEvent>(_onRefreshWeeklySets);
  }

  Future<void> _onAddWorkoutSet(
    AddWorkoutSetEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(WorkoutLoading());

    final addResult = await addWorkoutSet(event.workoutSet);

    await addResult.fold(
      (failure) async => emit(WorkoutError(failure.message)),
      (_) async {
        final affectedMusclesResult = await recordWorkoutSet(
          exerciseId: event.workoutSet.exerciseId,
          sets: 1,
          intensity: event.workoutSet.intensity,
          timestamp: event.workoutSet.date,
        );

        final affectedMuscles = affectedMusclesResult.fold(
          (_) => <String>[],
          (muscles) => muscles,
        );

        await _loadWeeklySetsData(emit);

        emitEffect(
          WorkoutLoggedEffect(
            message: AppStrings.setLogged,
            affectedMuscles: affectedMuscles,
          ),
        );
      },
    );
  }

  Future<void> _onLoadWeeklySets(
    LoadWeeklySetsEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    await _loadWeeklySetsData(emit, showLoading: true);
  }

  Future<void> _onRefreshWeeklySets(
    RefreshWeeklySetsEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    await _loadWeeklySetsData(emit);
  }

  Future<void> _loadWeeklySetsData(
    Emitter<WorkoutState> emit, {
    bool showLoading = false,
  }) async {
    if (showLoading) {
      emit(WorkoutLoading());
    }

    final result = await getWeeklySets();

    result.fold(
      (failure) => emit(WorkoutError(failure.message)),
      (sets) {
        _cachedWeeklySets = sets;
        emit(WorkoutLoaded(sets));
      },
    );
  }

  List<WorkoutSet> get cachedWeeklySets => _cachedWeeklySets;
}