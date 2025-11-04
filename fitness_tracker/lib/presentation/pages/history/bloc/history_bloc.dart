import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../../../domain/usecases/workout_sets/get_all_workout_sets.dart';
import '../../../../domain/usecases/workout_sets/get_sets_by_date_range.dart';
import '../../../../domain/usecases/workout_sets/delete_workout_set.dart';

// ==================== Events ====================

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  
  @override
  List<Object?> get props => [];
}

/// Event to load all workout sets
class LoadAllSetsEvent extends HistoryEvent {}

/// Event to load sets filtered by date range
class LoadSetsByDateRangeEvent extends HistoryEvent {
  final DateTime startDate;
  final DateTime endDate;
  
  const LoadSetsByDateRangeEvent({
    required this.startDate,
    required this.endDate,
  });
  
  @override
  List<Object?> get props => [startDate, endDate];
}

/// Event to filter sets by muscle group
class FilterByMuscleGroupEvent extends HistoryEvent {
  final String? muscleGroup; // null means "All" (no filter)
  
  const FilterByMuscleGroupEvent(this.muscleGroup);
  
  @override
  List<Object?> get props => [muscleGroup];
}

/// Event to delete a workout set
class DeleteSetEvent extends HistoryEvent {
  final String setId;
  
  const DeleteSetEvent(this.setId);
  
  @override
  List<Object?> get props => [setId];
}

/// Event to refresh history data (useful after adding/editing sets)
class RefreshHistoryEvent extends HistoryEvent {}

// ==================== States ====================

abstract class HistoryState extends Equatable {
  const HistoryState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class HistoryInitial extends HistoryState {}

/// Loading state while fetching data
class HistoryLoading extends HistoryState {}

/// Loaded state with workout sets and current filter
class HistoryLoaded extends HistoryState {
  final List<WorkoutSet> sets;
  final String? currentMuscleFilter; // null means "All"
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  
  const HistoryLoaded({
    required this.sets,
    this.currentMuscleFilter,
    this.filterStartDate,
    this.filterEndDate,
  });
  
  @override
  List<Object?> get props => [
        sets,
        currentMuscleFilter,
        filterStartDate,
        filterEndDate,
      ];
  
  /// Helper to check if any filters are active
  bool get hasActiveFilters =>
      currentMuscleFilter != null ||
      filterStartDate != null ||
      filterEndDate != null;
}

/// Error state when something goes wrong
class HistoryError extends HistoryState {
  final String message;
  
  const HistoryError(this.message);
  
  @override
  List<Object?> get props => [message];
}

/// Success state after an operation (like delete)
class HistoryOperationSuccess extends HistoryState {
  final String message;
  
  const HistoryOperationSuccess(this.message);
  
  @override
  List<Object?> get props => [message];
}

// ==================== BLoC ====================

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetAllWorkoutSets getAllWorkoutSets;
  final GetSetsByDateRange getSetsByDateRange;
  final DeleteWorkoutSet deleteWorkoutSet;
  
  // Keep track of current filters for refresh operations
  String? _currentMuscleFilter;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  HistoryBloc({
    required this.getAllWorkoutSets,
    required this.getSetsByDateRange,
    required this.deleteWorkoutSet,
  }) : super(HistoryInitial()) {
    on<LoadAllSetsEvent>(_onLoadAllSets);
    on<LoadSetsByDateRangeEvent>(_onLoadSetsByDateRange);
    on<FilterByMuscleGroupEvent>(_onFilterByMuscleGroup);
    on<DeleteSetEvent>(_onDeleteSet);
    on<RefreshHistoryEvent>(_onRefreshHistory);
  }

  /// Load all workout sets without any filters
  Future<void> _onLoadAllSets(
    LoadAllSetsEvent event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    
    // Clear filters
    _currentMuscleFilter = null;
    _filterStartDate = null;
    _filterEndDate = null;
    
    final result = await getAllWorkoutSets();
    
    result.fold(
      (failure) => emit(HistoryError(failure.message)),
      (sets) => emit(HistoryLoaded(sets: sets)),
    );
  }

  /// Load sets filtered by date range
  Future<void> _onLoadSetsByDateRange(
    LoadSetsByDateRangeEvent event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    
    // Save date filters
    _filterStartDate = event.startDate;
    _filterEndDate = event.endDate;
    
    final result = await getSetsByDateRange(
      startDate: event.startDate,
      endDate: event.endDate,
      muscleGroup: _currentMuscleFilter,
    );
    
    result.fold(
      (failure) => emit(HistoryError(failure.message)),
      (sets) => emit(HistoryLoaded(
            sets: sets,
            currentMuscleFilter: _currentMuscleFilter,
            filterStartDate: event.startDate,
            filterEndDate: event.endDate,
          )),
    );
  }

  /// Filter sets by muscle group (applies to current date range if any)
  Future<void> _onFilterByMuscleGroup(
    FilterByMuscleGroupEvent event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    
    // Update muscle filter
    _currentMuscleFilter = event.muscleGroup;
    
    // If we have date filters, use them
    if (_filterStartDate != null && _filterEndDate != null) {
      final result = await getSetsByDateRange(
        startDate: _filterStartDate!,
        endDate: _filterEndDate!,
        muscleGroup: event.muscleGroup,
      );
      
      result.fold(
        (failure) => emit(HistoryError(failure.message)),
        (sets) => emit(HistoryLoaded(
              sets: sets,
              currentMuscleFilter: event.muscleGroup,
              filterStartDate: _filterStartDate,
              filterEndDate: _filterEndDate,
            )),
      );
    } else {
      // No date filters, get all sets and filter by muscle group
      final result = await getSetsByDateRange(
        startDate: DateTime(2000), // Far past date
        endDate: DateTime.now().add(const Duration(days: 1)),
        muscleGroup: event.muscleGroup,
      );
      
      result.fold(
        (failure) => emit(HistoryError(failure.message)),
        (sets) => emit(HistoryLoaded(
              sets: sets,
              currentMuscleFilter: event.muscleGroup,
            )),
      );
    }
  }

  /// Delete a workout set and refresh the list
  Future<void> _onDeleteSet(
    DeleteSetEvent event,
    Emitter<HistoryState> emit,
  ) async {
    final result = await deleteWorkoutSet(event.setId);
    
    await result.fold(
      (failure) async => emit(HistoryError(failure.message)),
      (_) async {
        emit(const HistoryOperationSuccess('Set deleted successfully'));
        // Refresh the data after successful deletion
        add(RefreshHistoryEvent());
      },
    );
  }

  /// Refresh history with current filters
  Future<void> _onRefreshHistory(
    RefreshHistoryEvent event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    
    // If we have date filters, use them
    if (_filterStartDate != null && _filterEndDate != null) {
      final result = await getSetsByDateRange(
        startDate: _filterStartDate!,
        endDate: _filterEndDate!,
        muscleGroup: _currentMuscleFilter,
      );
      
      result.fold(
        (failure) => emit(HistoryError(failure.message)),
        (sets) => emit(HistoryLoaded(
              sets: sets,
              currentMuscleFilter: _currentMuscleFilter,
              filterStartDate: _filterStartDate,
              filterEndDate: _filterEndDate,
            )),
      );
    } else {
      // No date filters, load all sets
      final result = await getSetsByDateRange(
        startDate: DateTime(2000), // Far past date
        endDate: DateTime.now().add(const Duration(days: 1)),
        muscleGroup: _currentMuscleFilter,
      );
      
      result.fold(
        (failure) => emit(HistoryError(failure.message)),
        (sets) => emit(HistoryLoaded(
              sets: sets,
              currentMuscleFilter: _currentMuscleFilter,
            )),
      );
    }
  }
}
