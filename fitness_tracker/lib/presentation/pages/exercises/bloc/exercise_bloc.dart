import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/exercise.dart';
import '../../../../domain/usecases/exercises/get_all_exercises.dart';
import '../../../../domain/usecases/exercises/get_exercise_by_id.dart';
import '../../../../domain/usecases/exercises/get_exercises_for_muscle.dart';
import '../../../../domain/usecases/exercises/add_exercise.dart';
import '../../../../domain/usecases/exercises/update_exercise.dart';
import '../../../../domain/usecases/exercises/delete_exercise.dart';

// ==================== Events ====================

abstract class ExerciseEvent extends Equatable {
  const ExerciseEvent();
  @override
  List<Object?> get props => [];
}

class LoadExercisesEvent extends ExerciseEvent {}

class LoadExerciseByIdEvent extends ExerciseEvent {
  final String id;
  const LoadExerciseByIdEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class LoadExercisesForMuscleEvent extends ExerciseEvent {
  final String muscleGroup;
  const LoadExercisesForMuscleEvent(this.muscleGroup);
  @override
  List<Object?> get props => [muscleGroup];
}

class AddExerciseEvent extends ExerciseEvent {
  final Exercise exercise;
  const AddExerciseEvent(this.exercise);
  @override
  List<Object?> get props => [exercise];
}

class UpdateExerciseEvent extends ExerciseEvent {
  final Exercise exercise;
  const UpdateExerciseEvent(this.exercise);
  @override
  List<Object?> get props => [exercise];
}

class DeleteExerciseEvent extends ExerciseEvent {
  final String id;
  const DeleteExerciseEvent(this.id);
  @override
  List<Object?> get props => [id];
}

// ==================== States ====================

abstract class ExerciseState extends Equatable {
  const ExerciseState();
  @override
  List<Object?> get props => [];
}

class ExerciseInitial extends ExerciseState {}

class ExerciseLoading extends ExerciseState {}

class ExercisesLoaded extends ExerciseState {
  final List<Exercise> exercises;
  const ExercisesLoaded(this.exercises);
  @override
  List<Object?> get props => [exercises];
}

class ExerciseLoaded extends ExerciseState {
  final Exercise exercise;
  const ExerciseLoaded(this.exercise);
  @override
  List<Object?> get props => [exercise];
}

class ExerciseError extends ExerciseState {
  final String message;
  const ExerciseError(this.message);
  @override
  List<Object?> get props => [message];
}

class ExerciseOperationSuccess extends ExerciseState {
  final String message;
  const ExerciseOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// ==================== BLoC ====================

class ExerciseBloc extends Bloc<ExerciseEvent, ExerciseState> {
  final GetAllExercises getAllExercises;
  final GetExerciseById getExerciseById;
  final GetExercisesForMuscle getExercisesForMuscle;
  final AddExercise addExercise;
  final UpdateExercise updateExercise;
  final DeleteExercise deleteExercise;

  ExerciseBloc({
    required this.getAllExercises,
    required this.getExerciseById,
    required this.getExercisesForMuscle,
    required this.addExercise,
    required this.updateExercise,
    required this.deleteExercise,
  }) : super(ExerciseInitial()) {
    on<LoadExercisesEvent>(_onLoadExercises);
    on<LoadExerciseByIdEvent>(_onLoadExerciseById);
    on<LoadExercisesForMuscleEvent>(_onLoadExercisesForMuscle);
    on<AddExerciseEvent>(_onAddExercise);
    on<UpdateExerciseEvent>(_onUpdateExercise);
    on<DeleteExerciseEvent>(_onDeleteExercise);
  }

  Future<void> _onLoadExercises(
    LoadExercisesEvent event,
    Emitter<ExerciseState> emit,
  ) async {
    emit(ExerciseLoading());
    final result = await getAllExercises();
    result.fold(
      (failure) => emit(ExerciseError(failure.message)),
      (exercises) => emit(ExercisesLoaded(exercises)),
    );
  }

  Future<void> _onLoadExerciseById(
    LoadExerciseByIdEvent event,
    Emitter<ExerciseState> emit,
  ) async {
    emit(ExerciseLoading());
    final result = await getExerciseById(event.id);
    result.fold(
      (failure) => emit(ExerciseError(failure.message)),
      (exercise) {
        if (exercise == null) {
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
      (failure) => emit(ExerciseError(failure.message)),
      (exercises) => emit(ExercisesLoaded(exercises)),
    );
  }

  Future<void> _onAddExercise(
    AddExerciseEvent event,
    Emitter<ExerciseState> emit,
  ) async {
    final result = await addExercise(event.exercise);
    await result.fold(
      (failure) async => emit(ExerciseError(failure.message)),
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
      (failure) async => emit(ExerciseError(failure.message)),
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
      (failure) async => emit(ExerciseError(failure.message)),
      (_) async {
        emit(const ExerciseOperationSuccess('Exercise deleted successfully'));
        add(LoadExercisesEvent());
      },
    );
  }
}
