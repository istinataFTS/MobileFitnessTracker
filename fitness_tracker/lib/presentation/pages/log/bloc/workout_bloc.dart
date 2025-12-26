// File: lib/presentation/pages/log/bloc/workout_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../../../domain/usecases/workout_sets/add_workout_set.dart';
import '../../../../domain/usecases/workout_sets/get_weekly_sets.dart';

// ==================== EVENTS ====================

abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();
  
  @override
  List<Object?> get props => [];
}

/// Event to add a new workout set
class AddWorkoutSetEvent extends WorkoutEvent {
  final WorkoutSet workoutSet;
  
  const AddWorkoutSetEvent(this.workoutSet);
  
  @override
  List<Object?> get props => [workoutSet];
}

/// Event to load weekly sets (for validation/display)
class LoadWeeklySetsEvent extends WorkoutEvent {
  const LoadWeeklySetsEvent();
}

/// Event to refresh after a set is logged
class RefreshWeeklySetsEvent extends WorkoutEvent {
  const RefreshWeeklySetsEvent();
}

// ==================== STATES ====================

abstract class WorkoutState extends Equatable {
  const WorkoutState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state before any operations
class WorkoutInitial extends WorkoutState {}

/// Loading state during async operations
class WorkoutLoading extends WorkoutState {}

/// Loaded state with weekly sets data
class WorkoutLoaded extends WorkoutState {
  final List<WorkoutSet> weeklySets;
  
  const WorkoutLoaded(this.weeklySets);
  
  @override
  List<Object?> get props => [weeklySets];
}

/// Error state with message
class WorkoutError extends WorkoutState {
  final String message;
  
  const WorkoutError(this.message);
  
  @override
  List<Object?> get props => [message];
}

/// Success state after operations (add/update/delete)
class WorkoutOperationSuccess extends WorkoutState {
  final String message;
  final List<WorkoutSet> weeklySets; // Keep updated sets in state
  
  const WorkoutOperationSuccess({
    required this.message,
    required this.weeklySets,
  });
  
  @override
  List<Object?> get props => [message, weeklySets];
}

// ==================== BLoC ====================

/// BLoC for handling workout set logging operations
/// 
/// Responsibilities:
/// - Add new workout sets to database
/// - Load weekly sets for progress tracking
/// - Provide feedback on operations (success/error)
/// 
/// Used primarily by LogPage's exercise logging tab
class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final AddWorkoutSet addWorkoutSet;
  final GetWeeklySets getWeeklySets;
  
  // Cache weekly sets for quick access
  List<WorkoutSet> _cachedWeeklySets = [];
  
  WorkoutBloc({
    required this.addWorkoutSet,
    required this.getWeeklySets,
  }) : super(WorkoutInitial()) {
    on<AddWorkoutSetEvent>(_onAddWorkoutSet);
    on<LoadWeeklySetsEvent>(_onLoadWeeklySets);
    on<RefreshWeeklySetsEvent>(_onRefreshWeeklySets);
  }
  
  /// Handle adding a new workout set
  Future<void> _onAddWorkoutSet(
    AddWorkoutSetEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(WorkoutLoading());
    
    // Add the workout set
    final result = await addWorkoutSet(event.workoutSet);
    
    await result.fold(
      (failure) async {
        emit(WorkoutError(failure.message));
      },
      (_) async {
        // After successful add, reload weekly sets to get updated data
        final setsResult = await getWeeklySets();
        
        setsResult.fold(
          (failure) {
            // Even if reload fails, the set was added successfully
            emit(const WorkoutOperationSuccess(
              message: AppStrings.setLogged,
              weeklySets: [],
            ));
          },
          (sets) {
            _cachedWeeklySets = sets;
            emit(WorkoutOperationSuccess(
              message: AppStrings.setLogged,
              weeklySets: sets,
            ));
          },
        );
      },
    );
  }
  
  /// Handle loading weekly sets
  Future<void> _onLoadWeeklySets(
    LoadWeeklySetsEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(WorkoutLoading());
    
    final result = await getWeeklySets();
    
    result.fold(
      (failure) => emit(WorkoutError(failure.message)),
      (sets) {
        _cachedWeeklySets = sets;
        emit(WorkoutLoaded(sets));
      },
    );
  }
  
  /// Handle refreshing weekly sets (after external changes)
  Future<void> _onRefreshWeeklySets(
    RefreshWeeklySetsEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    // Don't show loading state for refresh (smoother UX)
    final result = await getWeeklySets();
    
    result.fold(
      (failure) => emit(WorkoutError(failure.message)),
      (sets) {
        _cachedWeeklySets = sets;
        emit(WorkoutLoaded(sets));
      },
    );
  }
  
  /// Get cached weekly sets without triggering state change
  List<WorkoutSet> get cachedWeeklySets => _cachedWeeklySets;
}