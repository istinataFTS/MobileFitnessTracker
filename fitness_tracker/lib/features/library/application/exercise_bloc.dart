import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/usecases/exercises/add_exercise.dart';
import '../../../domain/usecases/exercises/delete_exercise.dart';
import '../../../domain/usecases/exercises/ensure_default_exercises.dart';
import '../../../domain/usecases/exercises/get_all_exercises.dart';
import '../../../domain/usecases/exercises/get_exercise_by_id.dart';
import '../../../domain/usecases/exercises/get_exercises_for_muscle.dart';
import '../../../domain/usecases/exercises/update_exercise.dart';

abstract class ExerciseEvent extends Equatable {
  const ExerciseEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class LoadExercisesEvent extends ExerciseEvent {}

class LoadExerciseByIdEvent extends ExerciseEvent {
  const LoadExerciseByIdEvent(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}

class LoadExercisesForMuscleEvent extends ExerciseEvent {
  const LoadExercisesForMuscleEvent(this.muscleGroup);

  final String muscleGroup;

  @override
  List<Object?> get props => <Object?>[muscleGroup];
}

class AddExerciseEvent extends ExerciseEvent {
  const AddExerciseEvent(this.exercise);

  final Exercise exercise;

  @override
  List<Object?> get props => <Object?>[exercise];
}

class UpdateExerciseEvent extends ExerciseEvent {
  const UpdateExerciseEvent(this.exercise);

  final Exercise exercise;

  @override
  List<Object?> get props => <Object?>[exercise];
}

class DeleteExerciseEvent extends ExerciseEvent {
  const DeleteExerciseEvent(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}

abstract class ExerciseState extends Equatable {
  const ExerciseState();

  @override
  List<Object?> get props => <Object?>[];
}

class ExerciseInitial extends ExerciseState {}

class ExerciseLoading extends ExerciseState {}

class ExercisesLoaded extends ExerciseState {
  const ExercisesLoaded(this.exercises);

  final List<Exercise> exercises;

  @override
  List<Object?> get props => <Object?>[exercises];
}

class ExerciseLoaded extends ExerciseState {
  const ExerciseLoaded(this.exercise);

  final Exercise exercise;

  @override
  List<Object?> get props => <Object?>[exercise];
}

class ExerciseError extends ExerciseState {
  const ExerciseError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class ExerciseOperationSuccess extends ExerciseState {
  const ExerciseOperationSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class ExerciseBloc extends Bloc<ExerciseEvent, ExerciseState> {
  ExerciseBloc({
    required this.getAllExercises,
    required this.getExerciseById,
    required this.getExercisesForMuscle,
    required this.addExercise,
    required this.updateExercise,
    required this.deleteExercise,
    required this.ensureDefaultExercises,
  }) : super(ExerciseInitial()) {
    on<LoadExercisesEvent>(_onLoadExercises);
    on<LoadExerciseByIdEvent>(_onLoadExerciseById);
    on<LoadExercisesForMuscleEvent>(_onLoadExercisesForMuscle);
    on<AddExerciseEvent>(_onAddExercise);
    on<UpdateExerciseEvent>(_onUpdateExercise);
    on<DeleteExerciseEvent>(_onDeleteExercise);
  }

  final GetAllExercises getAllExercises;
  final GetExerciseById getExerciseById;
  final GetExercisesForMuscle getExercisesForMuscle;
  final AddExercise addExercise;
  final UpdateExercise updateExercise;
  final DeleteExercise deleteExercise;
  final EnsureDefaultExercises ensureDefaultExercises;

  /// Guards against running the default-exercise seeding more than once per
  /// bloc instance (= per user session, since [AuthSessionShell] recreates
  /// the bloc on every user switch).
  bool _hasEnsuredDefaults = false;

  Future<void> _onLoadExercises(
    LoadExercisesEvent event,
    Emitter<ExerciseState> emit,
  ) async {
    emit(ExerciseLoading());
    final result = await getAllExercises();

    await result.fold(
      (failure) async {
        _logFailure('LoadExercisesEvent', failure);
        emit(ExerciseError(failure.message));
      },
      (exercises) async {
        // If the user has no exercises and we haven't seeded yet this session,
        // run the per-user default-exercise seeding as a safety-net fallback
        // (e.g. fresh device, second user on a shared device, cloud account
        // with no exercises). The flag prevents an infinite re-seed loop.
        if (exercises.isEmpty && !_hasEnsuredDefaults) {
          _hasEnsuredDefaults = true;
          await ensureDefaultExercises();

          // Reload after seeding so the UI shows the freshly inserted exercises.
          final reloadResult = await getAllExercises();
          reloadResult.fold(
            (failure) {
              _logFailure('LoadExercisesEvent (post-seed reload)', failure);
              emit(ExerciseError(failure.message));
            },
            (seeded) => emit(ExercisesLoaded(seeded)),
          );
          return;
        }

        emit(ExercisesLoaded(exercises));
      },
    );
  }

  Future<void> _onLoadExerciseById(
    LoadExerciseByIdEvent event,
    Emitter<ExerciseState> emit,
  ) async {
    emit(ExerciseLoading());
    final result = await getExerciseById(event.id);
    result.fold(
      (failure) {
        _logFailure('LoadExerciseByIdEvent(${event.id})', failure);
        emit(ExerciseError(failure.message));
      },
      (exercise) {
        if (exercise == null) {
          AppLogger.warning(
            'LoadExerciseByIdEvent(${event.id}): exercise not found',
            category: 'exercise_bloc',
          );
          emit(const ExerciseError('Exercise not found'));
        } else {
          emit(ExerciseLoaded(exercise));
        }
      },
    );
  }

  Future<void> _onLoadExercisesForMuscle(
    LoadExercisesForMuscleEvent event,
    Emitter<ExerciseState> emit,
  ) async {
    emit(ExerciseLoading());
    final result = await getExercisesForMuscle(event.muscleGroup);
    result.fold(
      (failure) {
        _logFailure('LoadExercisesForMuscleEvent(${event.muscleGroup})', failure);
        emit(ExerciseError(failure.message));
      },
      (exercises) => emit(ExercisesLoaded(exercises)),
    );
  }

  Future<void> _onAddExercise(
    AddExerciseEvent event,
    Emitter<ExerciseState> emit,
  ) async {
    final result = await addExercise(event.exercise);
    await result.fold(
      (failure) async {
        _logFailure('AddExerciseEvent(${event.exercise.name})', failure);
        emit(ExerciseError(failure.message));
      },
      (_) async {
        emit(const ExerciseOperationSuccess('Exercise added successfully'));
        add(LoadExercisesEvent());
      },
    );
  }

  Future<void> _onUpdateExercise(
    UpdateExerciseEvent event,
    Emitter<ExerciseState> emit,
  ) async {
    final result = await updateExercise(event.exercise);
    await result.fold(
      (failure) async {
        _logFailure('UpdateExerciseEvent(${event.exercise.name})', failure);
        emit(ExerciseError(failure.message));
      },
      (_) async {
        emit(const ExerciseOperationSuccess('Exercise updated successfully'));
        add(LoadExercisesEvent());
      },
    );
  }

  Future<void> _onDeleteExercise(
    DeleteExerciseEvent event,
    Emitter<ExerciseState> emit,
  ) async {
    final result = await deleteExercise(event.id);
    await result.fold(
      (failure) async {
        _logFailure('DeleteExerciseEvent(${event.id})', failure);
        emit(ExerciseError(failure.message));
      },
      (_) async {
        emit(const ExerciseOperationSuccess('Exercise deleted successfully'));
        add(LoadExercisesEvent());
      },
    );
  }

  void _logFailure(String operation, Failure failure) {
    AppLogger.error(
      '$operation failed — ${failure.runtimeType}: ${failure.message}',
      category: 'exercise_bloc',
    );
  }
}