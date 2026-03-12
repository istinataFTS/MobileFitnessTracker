import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/bloc_effects_mixin.dart';
import '../../../../domain/entities/nutrition_log.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../../../domain/usecases/nutrition_logs/delete_nutrition_log.dart';
import '../../../../domain/usecases/nutrition_logs/get_logs_by_date_range.dart';
import '../../../../domain/usecases/nutrition_logs/update_nutrition_log.dart';
import '../../../../domain/usecases/workout_sets/delete_workout_set.dart';
import '../../../../domain/usecases/workout_sets/get_all_workout_sets.dart';
import '../../../../domain/usecases/workout_sets/get_sets_by_date_range.dart';
import '../../../../domain/usecases/workout_sets/update_workout_set.dart';

enum HistoryMode {
  workouts,
  nutrition,
}

// ==================== Events ====================

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadMonthSetsEvent extends HistoryEvent {
  final DateTime month;

  const LoadMonthSetsEvent(this.month);

  @override
  List<Object?> get props => [month];
}

class SelectDateEvent extends HistoryEvent {
  final DateTime date;

  const SelectDateEvent(this.date);

  @override
  List<Object?> get props => [date];
}

class ClearDateSelectionEvent extends HistoryEvent {}

class UpdateSetEvent extends HistoryEvent {
  final WorkoutSet set;

  const UpdateSetEvent(this.set);

  @override
  List<Object?> get props => [set];
}

class DeleteSetEvent extends HistoryEvent {
  final String setId;

  const DeleteSetEvent(this.setId);

  @override
  List<Object?> get props => [setId];
}

class DeleteNutritionHistoryLogEvent extends HistoryEvent {
  final String logId;

  const DeleteNutritionHistoryLogEvent(this.logId);

  @override
  List<Object?> get props => [logId];
}

class UpdateNutritionHistoryLogEvent extends HistoryEvent {
  final NutritionLog log;

  const UpdateNutritionHistoryLogEvent(this.log);

  @override
  List<Object?> get props => [log];
}

class RefreshCurrentMonthEvent extends HistoryEvent {}

class NavigateToMonthEvent extends HistoryEvent {
  final DateTime month;

  const NavigateToMonthEvent(this.month);

  @override
  List<Object?> get props => [month];
}

class ChangeHistoryModeEvent extends HistoryEvent {
  final HistoryMode mode;

  const ChangeHistoryModeEvent(this.mode);

  @override
  List<Object?> get props => [mode];
}

// ==================== States ====================

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final DateTime currentMonth;
  final HistoryMode currentMode;
  final Map<DateTime, List<WorkoutSet>> monthSets;
  final Map<DateTime, List<NutritionLog>> monthNutritionLogs;
  final DateTime? selectedDate;
  final List<WorkoutSet> selectedDateSets;
  final List<NutritionLog> selectedDateNutritionLogs;

  const HistoryLoaded({
    required this.currentMonth,
    required this.currentMode,
    required this.monthSets,
    required this.monthNutritionLogs,
    this.selectedDate,
    this.selectedDateSets = const <WorkoutSet>[],
    this.selectedDateNutritionLogs = const <NutritionLog>[],
  });

  int getSetsCountForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return monthSets[normalizedDate]?.length ?? 0;
  }

  int getNutritionCountForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return monthNutritionLogs[normalizedDate]?.length ?? 0;
  }

  @override
  List<Object?> get props => [
        currentMonth,
        currentMode,
        monthSets,
        monthNutritionLogs,
        selectedDate,
        selectedDateSets,
        selectedDateNutritionLogs,
      ];
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== Effects ====================

abstract class HistoryUiEffect {
  const HistoryUiEffect();
}

class HistorySuccessEffect extends HistoryUiEffect {
  final String message;

  const HistorySuccessEffect(this.message);
}

// ==================== BLoC ====================

class HistoryBloc extends Bloc<HistoryEvent, HistoryState>
    with BlocEffectsMixin<HistoryState, HistoryUiEffect> {
  final GetAllWorkoutSets getAllWorkoutSets;
  final GetSetsByDateRange getSetsByDateRange;
  final GetLogsByDateRange getNutritionLogsByDateRange;
  final DeleteWorkoutSet deleteWorkoutSet;
  final UpdateWorkoutSet updateWorkoutSet;
  final DeleteNutritionLog deleteNutritionLog;
  final UpdateNutritionLog updateNutritionLog;

  DateTime _currentMonth = DateTime.now();
  HistoryMode _currentMode = HistoryMode.workouts;
  Map<DateTime, List<WorkoutSet>> _monthSets = {};
  Map<DateTime, List<NutritionLog>> _monthNutritionLogs = {};
  DateTime? _selectedDate;

  HistoryBloc({
    required this.getAllWorkoutSets,
    required this.getSetsByDateRange,
    required this.getNutritionLogsByDateRange,
    required this.deleteWorkoutSet,
    required this.updateWorkoutSet,
    required this.deleteNutritionLog,
    required this.updateNutritionLog,
  }) : super(HistoryInitial()) {
    on<LoadMonthSetsEvent>(_onLoadMonthSets);
    on<SelectDateEvent>(_onSelectDate);
    on<ClearDateSelectionEvent>(_onClearDateSelection);
    on<UpdateSetEvent>(_onUpdateSet);
    on<DeleteSetEvent>(_onDeleteSet);
    on<DeleteNutritionHistoryLogEvent>(_onDeleteNutritionLog);
    on<UpdateNutritionHistoryLogEvent>(_onUpdateNutritionLog);
    on<RefreshCurrentMonthEvent>(_onRefreshCurrentMonth);
    on<NavigateToMonthEvent>(_onNavigateToMonth);
    on<ChangeHistoryModeEvent>(_onChangeHistoryMode);
  }

  Future<void> _onLoadMonthSets(
    LoadMonthSetsEvent event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());

    final loaded = await _loadMonthData(event.month);
    if (loaded != null) {
      emit(loaded);
    } else {
      emit(const HistoryError('Failed to load history data'));
    }
  }

  void _onSelectDate(
    SelectDateEvent event,
    Emitter<HistoryState> emit,
  ) {
    _selectedDate = _normalizeDate(event.date);
    emit(_buildLoadedState());
  }

  void _onClearDateSelection(
    ClearDateSelectionEvent event,
    Emitter<HistoryState> emit,
  ) {
    _selectedDate = null;
    emit(_buildLoadedState());
  }

  Future<void> _onUpdateSet(
    UpdateSetEvent event,
    Emitter<HistoryState> emit,
  ) async {
    await _performHistoryMutation(
      emit,
      action: () => updateWorkoutSet(event.set),
      successMessage: 'Set updated successfully',
    );
  }

  Future<void> _onDeleteSet(
    DeleteSetEvent event,
    Emitter<HistoryState> emit,
  ) async {
    await _performHistoryMutation(
      emit,
      action: () => deleteWorkoutSet(event.setId),
      successMessage: 'Set deleted successfully',
    );
  }

  Future<void> _onDeleteNutritionLog(
    DeleteNutritionHistoryLogEvent event,
    Emitter<HistoryState> emit,
  ) async {
    await _performHistoryMutation(
      emit,
      action: () => deleteNutritionLog(event.logId),
      successMessage: 'Nutrition log deleted successfully',
    );
  }

  Future<void> _onUpdateNutritionLog(
    UpdateNutritionHistoryLogEvent event,
    Emitter<HistoryState> emit,
  ) async {
    await _performHistoryMutation(
      emit,
      action: () => updateNutritionLog(event.log),
      successMessage: 'Nutrition log updated successfully',
    );
  }

  Future<void> _onRefreshCurrentMonth(
    RefreshCurrentMonthEvent event,
    Emitter<HistoryState> emit,
  ) async {
    final reloaded = await _reloadCurrentMonth();
    if (reloaded != null) {
      emit(reloaded);
    } else {
      emit(const HistoryError('Failed to refresh history data'));
    }
  }

  void _onNavigateToMonth(
    NavigateToMonthEvent event,
    Emitter<HistoryState> emit,
  ) {
    _selectedDate = null;
    add(LoadMonthSetsEvent(event.month));
  }

  void _onChangeHistoryMode(
    ChangeHistoryModeEvent event,
    Emitter<HistoryState> emit,
  ) {
    _currentMode = event.mode;
    emit(_buildLoadedState());
  }

  Future<void> _performHistoryMutation(
    Emitter<HistoryState> emit, {
    required Future<dynamic> Function() action,
    required String successMessage,
  }) async {
    final result = await action();

    await result.fold(
      (failure) async => emit(HistoryError(failure.message)),
      (_) async {
        final reloaded = await _reloadCurrentMonth();
        if (reloaded == null) {
          emit(const HistoryError('Failed to reload history data'));
          return;
        }

        emit(reloaded);
        emitEffect(HistorySuccessEffect(successMessage));
      },
    );
  }

  Future<HistoryLoaded?> _reloadCurrentMonth() async {
    return _loadMonthData(_currentMonth);
  }

  Future<HistoryLoaded?> _loadMonthData(DateTime month) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    final setsResult = await getSetsByDateRange(
      startDate: firstDay,
      endDate: lastDay,
    );

    final nutritionResult = await getNutritionLogsByDateRange(
      startDate: firstDay,
      endDate: lastDay,
    );

    final groupedSets = setsResult.fold<Map<DateTime, List<WorkoutSet>>?>(
      (_) => null,
      (sets) {
        final grouped = <DateTime, List<WorkoutSet>>{};
        for (final set in sets) {
          final dateKey = _normalizeDate(set.date);
          grouped.putIfAbsent(dateKey, () => <WorkoutSet>[]);
          grouped[dateKey]!.add(set);
        }
        for (final items in grouped.values) {
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        return grouped;
      },
    );

    if (groupedSets == null) {
      return null;
    }

    final groupedNutrition =
        nutritionResult.fold<Map<DateTime, List<NutritionLog>>?>(
      (_) => null,
      (logs) {
        final grouped = <DateTime, List<NutritionLog>>{};
        for (final log in logs) {
          final dateKey = _normalizeDate(log.loggedAt);
          grouped.putIfAbsent(dateKey, () => <NutritionLog>[]);
          grouped[dateKey]!.add(log);
        }
        for (final items in grouped.values) {
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        return grouped;
      },
    );

    if (groupedNutrition == null) {
      return null;
    }

    _currentMonth = firstDay;
    _monthSets = groupedSets;
    _monthNutritionLogs = groupedNutrition;

    if (_selectedDate != null) {
      final normalizedSelectedDate = _normalizeDate(_selectedDate!);
      final hasWorkouts = (_monthSets[normalizedSelectedDate] ?? []).isNotEmpty;
      final hasNutrition =
          (_monthNutritionLogs[normalizedSelectedDate] ?? []).isNotEmpty;

      if (!hasWorkouts && !hasNutrition) {
        _selectedDate = null;
      }
    }

    return _buildLoadedState();
  }

  HistoryLoaded _buildLoadedState() {
    final List<WorkoutSet> selectedDateSets = _selectedDate != null
        ? (_monthSets[_selectedDate!] ?? <WorkoutSet>[])
        : <WorkoutSet>[];

    final List<NutritionLog> selectedDateNutritionLogs = _selectedDate != null
        ? (_monthNutritionLogs[_selectedDate!] ?? <NutritionLog>[])
        : <NutritionLog>[];

    return HistoryLoaded(
      currentMonth: _currentMonth,
      currentMode: _currentMode,
      monthSets: _monthSets,
      monthNutritionLogs: _monthNutritionLogs,
      selectedDate: _selectedDate,
      selectedDateSets: selectedDateSets,
      selectedDateNutritionLogs: selectedDateNutritionLogs,
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}