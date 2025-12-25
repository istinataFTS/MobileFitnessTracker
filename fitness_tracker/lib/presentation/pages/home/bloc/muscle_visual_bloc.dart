// Directory: lib/presentation/pages/home/bloc/muscle_visual_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../domain/entities/muscle_visual_data.dart';
import '../../../../domain/entities/time_period.dart';
import '../../../../domain/usecases/muscle_stimulus/get_muscle_visual_data.dart';

// ==================== EVENTS ====================

abstract class MuscleVisualEvent extends Equatable {
  const MuscleVisualEvent();
  
  @override
  List<Object?> get props => [];
}

/// Event to load muscle visual data for a specific time period
class LoadMuscleVisualsEvent extends MuscleVisualEvent {
  final TimePeriod period;
  
  const LoadMuscleVisualsEvent(this.period);
  
  @override
  List<Object?> get props => [period];
}

/// Event to change the current time period
class ChangePeriodEvent extends MuscleVisualEvent {
  final TimePeriod newPeriod;
  
  const ChangePeriodEvent(this.newPeriod);
  
  @override
  List<Object?> get props => [newPeriod];
}

/// Event to refresh visuals (triggered after workout logged)
class RefreshVisualsEvent extends MuscleVisualEvent {
  const RefreshVisualsEvent();
}

// ==================== STATES ====================

abstract class MuscleVisualState extends Equatable {
  const MuscleVisualState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class MuscleVisualInitial extends MuscleVisualState {}

/// Loading state while fetching data
class MuscleVisualLoading extends MuscleVisualState {
  final TimePeriod period;
  
  const MuscleVisualLoading(this.period);
  
  @override
  List<Object?> get props => [period];
}

/// Loaded state with muscle visual data
class MuscleVisualLoaded extends MuscleVisualState {
  final Map<String, MuscleVisualData> muscleData;
  final TimePeriod currentPeriod;
  
  const MuscleVisualLoaded({
    required this.muscleData,
    required this.currentPeriod,
  });
  
  /// Get visual data for a specific muscle group
  MuscleVisualData? getMuscleData(String muscleGroup) {
    return muscleData[muscleGroup];
  }
  
  /// Get all muscles that have been trained (non-gray)
  List<String> getTrainedMuscles() {
    return muscleData.entries
        .where((entry) => entry.value.hasTrained)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Get count of trained muscle groups
  int get trainedMuscleCount {
    return muscleData.values.where((data) => data.hasTrained).length;
  }
  
  /// Check if any muscles have been trained
  bool get hasAnyTraining {
    return muscleData.values.any((data) => data.hasTrained);
  }
  
  @override
  List<Object?> get props => [muscleData, currentPeriod];
}

/// Error state when data loading fails
class MuscleVisualError extends MuscleVisualState {
  final String message;
  final TimePeriod period;
  
  const MuscleVisualError({
    required this.message,
    required this.period,
  });
  
  @override
  List<Object?> get props => [message, period];
}

// ==================== BLOC ====================

class MuscleVisualBloc extends Bloc<MuscleVisualEvent, MuscleVisualState> {
  final GetMuscleVisualData getMuscleVisualData;
  
  // Cache current period to avoid unnecessary reloads
  TimePeriod _currentPeriod = TimePeriod.week; // Default to week view
  
  MuscleVisualBloc({
    required this.getMuscleVisualData,
  }) : super(MuscleVisualInitial()) {
    on<LoadMuscleVisualsEvent>(_onLoadMuscleVisuals);
    on<ChangePeriodEvent>(_onChangePeriod);
    on<RefreshVisualsEvent>(_onRefreshVisuals);
  }
  
  /// Load muscle visual data for a specific time period
  Future<void> _onLoadMuscleVisuals(
    LoadMuscleVisualsEvent event,
    Emitter<MuscleVisualState> emit,
  ) async {
    emit(MuscleVisualLoading(event.period));
    _currentPeriod = event.period;
    
    final result = await getMuscleVisualData(event.period);
    
    result.fold(
      (failure) => emit(MuscleVisualError(
        message: failure.message,
        period: event.period,
      )),
      (visualData) => emit(MuscleVisualLoaded(
        muscleData: visualData,
        currentPeriod: event.period,
      )),
    );
  }
  
  /// Change to a different time period
  Future<void> _onChangePeriod(
    ChangePeriodEvent event,
    Emitter<MuscleVisualState> emit,
  ) async {
    // Don't reload if period hasn't changed
    if (event.newPeriod == _currentPeriod && state is MuscleVisualLoaded) {
      return;
    }
    
    emit(MuscleVisualLoading(event.newPeriod));
    _currentPeriod = event.newPeriod;
    
    final result = await getMuscleVisualData(event.newPeriod);
    
    result.fold(
      (failure) => emit(MuscleVisualError(
        message: failure.message,
        period: event.newPeriod,
      )),
      (visualData) => emit(MuscleVisualLoaded(
        muscleData: visualData,
        currentPeriod: event.newPeriod,
      )),
    );
  }
  
  /// Refresh current period data (after workout logged)
  Future<void> _onRefreshVisuals(
    RefreshVisualsEvent event,
    Emitter<MuscleVisualState> emit,
  ) async {
    // Reload current period data
    emit(MuscleVisualLoading(_currentPeriod));
    
    final result = await getMuscleVisualData(_currentPeriod);
    
    result.fold(
      (failure) => emit(MuscleVisualError(
        message: failure.message,
        period: _currentPeriod,
      )),
      (visualData) => emit(MuscleVisualLoaded(
        muscleData: visualData,
        currentPeriod: _currentPeriod,
      )),
    );
  }
  
  /// Get currently selected time period
  TimePeriod get currentPeriod => _currentPeriod;
}