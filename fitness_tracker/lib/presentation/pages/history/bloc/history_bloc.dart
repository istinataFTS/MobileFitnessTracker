import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../../../domain/usecases/workout_sets/get_all_workout_sets.dart';
import '../../../../domain/usecases/workout_sets/get_sets_by_date_range.dart';
import '../../../../domain/usecases/workout_sets/delete_workout_set.dart';
import '../../../../domain/usecases/workout_sets/update_workout_set.dart';

// ==================== Events ====================

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  
  @override
  List<Object?> get props => [];
}

/// Event to load sets for a specific month (for calendar view)
class LoadMonthSetsEvent extends HistoryEvent {
  final DateTime month; // Any date within the target month
  
  const LoadMonthSetsEvent(this.month);
  
  @override
  List<Object?> get props => [month];
}

/// Event to select a specific date in the calendar
class SelectDateEvent extends HistoryEvent {
  final DateTime date;
  
  const SelectDateEvent(this.date);
  
  @override
  List<Object?> get props => [date];
}

/// Event to clear date selection (close bottom sheet)
class ClearDateSelectionEvent extends HistoryEvent {}

/// Event to update an existing workout set
class UpdateSetEvent extends HistoryEvent {
  final WorkoutSet set;
  
  const UpdateSetEvent(this.set);
  
  @override
  List<Object?> get props => [set];
}

/// Event to delete a workout set
class DeleteSetEvent extends HistoryEvent {
  final String setId;
  
  const DeleteSetEvent(this.setId);
  
  @override
  List<Object?> get props => [setId];
}

/// Event to refresh current month data
class RefreshCurrentMonthEvent extends HistoryEvent {}

/// Event to navigate to different month
class NavigateToMonthEvent extends HistoryEvent {
  final DateTime month;
  
  const NavigateToMonthEvent(this.month);
  
  @override
  List<Object?> get props => [month];
}

// ==================== States ====================

abstract class HistoryState extends Equatable {
  const HistoryState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state
class HistoryInitial extends HistoryState {}

/// Loading state
class HistoryLoading extends HistoryState {}

/// Loaded state with calendar data
class HistoryLoaded extends HistoryState {
  final DateTime currentMonth; // Currently displayed month
  final Map<DateTime, List<WorkoutSet>> monthSets; // All sets in current month, keyed by date
  final DateTime? selectedDate; // Currently selected date (for bottom sheet)
  final List<WorkoutSet> selectedDateSets; // Sets for the selected date
  
  const HistoryLoaded({
    required this.currentMonth,
    required this.monthSets,
    this.selectedDate,
    this.selectedDateSets = const [],
  });
  
  /// Get set count for a specific date
  int getSetsCountForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return monthSets[normalizedDate]?.length ?? 0;
  }
  
  /// Check if date has any sets
  bool hasWorkoutsOnDate(DateTime date) {
    return getSetsCountForDate(date) > 0;
  }
  
  @override
  List<Object?> get props => [
        currentMonth,
        monthSets,
        selectedDate,
        selectedDateSets,
      ];
}

/// Error state
class HistoryError extends HistoryState {
  final String message;
  
  const HistoryError(this.message);
  
  @override
  List<Object?> get props => [message];
}

/// Success state for operations (update/delete)
class HistoryOperationSuccess extends HistoryState {
  final String message;
  final DateTime currentMonth;
  final Map<DateTime, List<WorkoutSet>> monthSets;
  final DateTime? selectedDate;
  
  const HistoryOperationSuccess({
    required this.message,
    required this.currentMonth,
    required this.monthSets,
    this.selectedDate,
  });
  
  @override
  List<Object?> get props => [message, currentMonth, monthSets, selectedDate];
}

// ==================== BLoC ====================

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetAllWorkoutSets getAllWorkoutSets;
  final GetSetsByDateRange getSetsByDateRange;
  final DeleteWorkoutSet deleteWorkoutSet;
  final UpdateWorkoutSet updateWorkoutSet;
  
  // Cache for current loaded data
  DateTime _currentMonth = DateTime.now();
  Map<DateTime, List<WorkoutSet>> _monthSets = {};
  DateTime? _selectedDate;

  HistoryBloc({
    required this.getAllWorkoutSets,
    required this.getSetsByDateRange,
    required this.deleteWorkoutSet,
    required this.updateWorkoutSet,
  }) : super(HistoryInitial()) {
    on<LoadMonthSetsEvent>(_onLoadMonthSets);
    on<SelectDateEvent>(_onSelectDate);
    on<ClearDateSelectionEvent>(_onClearDateSelection);
    on<UpdateSetEvent>(_onUpdateSet);
    on<DeleteSetEvent>(_onDeleteSet);
    on<RefreshCurrentMonthEvent>(_onRefreshCurrentMonth);
    on<NavigateToMonthEvent>(_onNavigateToMonth);
  }

  /// Load all sets for a specific month
  Future<void> _onLoadMonthSets(
    LoadMonthSetsEvent event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    
    // Normalize to first and last day of month
    final firstDay = DateTime(event.month.year, event.month.month, 1);
    final lastDay = DateTime(event.month.year, event.month.month + 1, 0);
    
    final result = await getSetsByDateRange(
      startDate: firstDay,
      endDate: lastDay,
    );
    
    result.fold(
      (failure) => emit(HistoryError(failure.message)),
      (sets) {
        // Group sets by date
        final groupedSets = <DateTime, List<WorkoutSet>>{};
        for (final set in sets) {
          final dateKey = DateTime(set.date.year, set.date.month, set.date.day);
          if (!groupedSets.containsKey(dateKey)) {
            groupedSets[dateKey] = [];
          }
          groupedSets[dateKey]!.add(set);
        }
        
        // Sort each day's sets by creation time
        for (final sets in groupedSets.values) {
          sets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        
        _currentMonth = firstDay;
        _monthSets = groupedSets;
        
        emit(HistoryLoaded(
          currentMonth: _currentMonth,
          monthSets: _monthSets,
          selectedDate: _selectedDate,
          selectedDateSets: _selectedDate != null 
              ? (_monthSets[_selectedDate!] ?? [])
              : [],
        ));
      },
    );
  }

  /// Select a specific date to view details
  void _onSelectDate(
    SelectDateEvent event,
    Emitter<HistoryState> emit,
  ) {
    final normalizedDate = DateTime(event.date.year, event.date.month, event.date.day);
    _selectedDate = normalizedDate;
    
    final selectedSets = _monthSets[normalizedDate] ?? [];
    
    emit(HistoryLoaded(
      currentMonth: _currentMonth,
      monthSets: _monthSets,
      selectedDate: _selectedDate,
      selectedDateSets: selectedSets,
    ));
  }

  /// Clear date selection (close bottom sheet)
  void _onClearDateSelection(
    ClearDateSelectionEvent event,
    Emitter<HistoryState> emit,
  ) {
    _selectedDate = null;
    
    emit(HistoryLoaded(
      currentMonth: _currentMonth,
      monthSets: _monthSets,
    ));
  }

  /// Update an existing workout set
  Future<void> _onUpdateSet(
    UpdateSetEvent event,
    Emitter<HistoryState> emit,
  ) async {
    final result = await updateWorkoutSet(event.set);
    
    result.fold(
      (failure) => emit(HistoryError(failure.message)),
      (_) {
        // Refresh current month to show updated data
        add(RefreshCurrentMonthEvent());
        
        emit(HistoryOperationSuccess(
          message: 'Set updated successfully',
          currentMonth: _currentMonth,
          monthSets: _monthSets,
          selectedDate: _selectedDate,
        ));
      },
    );
  }

  /// Delete a workout set
  Future<void> _onDeleteSet(
    DeleteSetEvent event,
    Emitter<HistoryState> emit,
  ) async {
    final result = await deleteWorkoutSet(event.setId);
    
    result.fold(
      (failure) => emit(HistoryError(failure.message)),
      (_) {
        // Refresh current month to show updated data
        add(RefreshCurrentMonthEvent());
        
        emit(HistoryOperationSuccess(
          message: 'Set deleted successfully',
          currentMonth: _currentMonth,
          monthSets: _monthSets,
          selectedDate: _selectedDate,
        ));
      },
    );
  }

  /// Refresh current month data
  Future<void> _onRefreshCurrentMonth(
    RefreshCurrentMonthEvent event,
    Emitter<HistoryState> emit,
  ) async {
    add(LoadMonthSetsEvent(_currentMonth));
  }

  /// Navigate to a different month
  void _onNavigateToMonth(
    NavigateToMonthEvent event,
    Emitter<HistoryState> emit,
  ) {
    _selectedDate = null; // Clear selection when changing months
    add(LoadMonthSetsEvent(event.month));
  }
}