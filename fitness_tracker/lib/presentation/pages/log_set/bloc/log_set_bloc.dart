import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../domain/entities/target.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../../../domain/usecases/targets/get_all_targets.dart';
import '../../../../domain/usecases/workout_sets/add_workout_set.dart';
import '../../../../domain/usecases/workout_sets/get_weekly_sets.dart';

// Events
abstract class LogSetEvent extends Equatable {
  const LogSetEvent();
  @override
  List<Object?> get props => [];
}

class LoadLogSetDataEvent extends LogSetEvent {}

class AddSetEvent extends LogSetEvent {
  final WorkoutSet workoutSet;
  const AddSetEvent(this.workoutSet);
  @override
  List<Object?> get props => [workoutSet];
}

// States
abstract class LogSetState extends Equatable {
  const LogSetState();
  @override
  List<Object?> get props => [];
}

class LogSetInitial extends LogSetState {}

class LogSetLoading extends LogSetState {}

class LogSetLoaded extends LogSetState {
  final List<Target> targets;
  final List<WorkoutSet> weeklySets;
  
  const LogSetLoaded({
    required this.targets,
    required this.weeklySets,
  });
  
  @override
  List<Object?> get props => [targets, weeklySets];
}

class LogSetError extends LogSetState {
  final String message;
  const LogSetError(this.message);
  @override
  List<Object?> get props => [message];
}

class SetLoggedSuccess extends LogSetState {
  final String message;
  const SetLoggedSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class LogSetBloc extends Bloc<LogSetEvent, LogSetState> {
  final AddWorkoutSet addWorkoutSet;
  final GetAllTargets getAllTargets;
  final GetWeeklySets getWeeklySets;

  LogSetBloc({
    required this.addWorkoutSet,
    required this.getAllTargets,
    required this.getWeeklySets,
  }) : super(LogSetInitial()) {
    on<LoadLogSetDataEvent>(_onLoadLogSetData);
    on<AddSetEvent>(_onAddSet);
  }

  Future<void> _onLoadLogSetData(
    LoadLogSetDataEvent event,
    Emitter<LogSetState> emit,
  ) async {
    emit(LogSetLoading());
    
    final targetsResult = await getAllTargets();
    final setsResult = await getWeeklySets();
    
    if (targetsResult.isLeft() || setsResult.isLeft()) {
      emit(const LogSetError(AppStrings.errorLoadData));
      return;
    }
    
    final targets = targetsResult.getOrElse(() => []);
    final sets = setsResult.getOrElse(() => []);
    
    emit(LogSetLoaded(targets: targets, weeklySets: sets));
  }

  Future<void> _onAddSet(
    AddSetEvent event,
    Emitter<LogSetState> emit,
  ) async {
    final result = await addWorkoutSet(event.workoutSet);
    await result.fold(
      (failure) async => emit(LogSetError(failure.message)),
      (_) async {
        emit(const SetLoggedSuccess(AppStrings.successSetLogged));
        add(LoadLogSetDataEvent());
      },
    );
  }
}