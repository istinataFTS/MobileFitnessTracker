import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
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

/// Event to clear cache and force reload
class ClearCacheEvent extends MuscleVisualEvent {
  const ClearCacheEvent();
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
  final DateTime loadedAt; // NEW: Track when data was loaded
  
  const MuscleVisualLoaded({
    required this.muscleData,
    required this.currentPeriod,
    required this.loadedAt,
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
  
  /// Check if data is stale (older than threshold)
  bool isStale({Duration threshold = const Duration(minutes: 5)}) {
    return DateTime.now().difference(loadedAt) > threshold;
  }
  
  @override
  List<Object?> get props => [muscleData, currentPeriod, loadedAt];
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

/// Optimized BLoC with multi-period caching and lazy loading
class MuscleVisualBloc extends Bloc<MuscleVisualEvent, MuscleVisualState> {
  final GetMuscleVisualData getMuscleVisualData;
  
  // Multi-period cache: stores data for each period separately
  final Map<TimePeriod, Map<String, MuscleVisualData>> _periodCache = {};
  
  // Cache timestamps: track when each period was last loaded
  final Map<TimePeriod, DateTime> _cacheTimestamps = {};
  
  // Current period tracker
  TimePeriod _currentPeriod = TimePeriod.week; // Default to week view
  
  // Cache validity duration (configurable)
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  
  MuscleVisualBloc({
    required this.getMuscleVisualData,
  }) : super(MuscleVisualInitial()) {
    on<LoadMuscleVisualsEvent>(_onLoadMuscleVisuals);
    on<ChangePeriodEvent>(_onChangePeriod);
    on<RefreshVisualsEvent>(_onRefreshVisuals);
    on<ClearCacheEvent>(_onClearCache);
  }
  
  /// Load muscle visual data for a specific time period
  /// 
  /// Uses cache if available and fresh
  Future<void> _onLoadMuscleVisuals(
    LoadMuscleVisualsEvent event,
    Emitter<MuscleVisualState> emit,
  ) async {
    _currentPeriod = event.period;
    
    // Check cache first
    if (_isCacheValid(event.period)) {
      final cachedData = _periodCache[event.period]!;
      emit(MuscleVisualLoaded(
        muscleData: cachedData,
        currentPeriod: event.period,
        loadedAt: _cacheTimestamps[event.period]!,
      ));
      return;
    }
    
    // Cache miss or stale - fetch from repository
    emit(MuscleVisualLoading(event.period));
    
    final result = await getMuscleVisualData(event.period);
    
    result.fold(
      (failure) => emit(MuscleVisualError(
        message: failure.message,
        period: event.period,
      )),
      (visualData) {
        // Store in cache
        _periodCache[event.period] = visualData;
        _cacheTimestamps[event.period] = DateTime.now();
        
        emit(MuscleVisualLoaded(
          muscleData: visualData,
          currentPeriod: event.period,
          loadedAt: DateTime.now(),
        ));
      },
    );
  }
  
  /// Change to a different time period
  /// 
  /// Optimized: Uses cached data if available
  Future<void> _onChangePeriod(
    ChangePeriodEvent event,
    Emitter<MuscleVisualState> emit,
  ) async {
    // Don't reload if period hasn't changed and data is loaded
    if (event.newPeriod == _currentPeriod && 
        state is MuscleVisualLoaded) {
      return;
    }
    
    _currentPeriod = event.newPeriod;
    
    // Check cache first
    if (_isCacheValid(event.newPeriod)) {
      final cachedData = _periodCache[event.newPeriod]!;
      emit(MuscleVisualLoaded(
        muscleData: cachedData,
        currentPeriod: event.newPeriod,
        loadedAt: _cacheTimestamps[event.newPeriod]!,
      ));
      return;
    }
    
    // Cache miss - load fresh data
    emit(MuscleVisualLoading(event.newPeriod));
    
    final result = await getMuscleVisualData(event.newPeriod);
    
    result.fold(
      (failure) => emit(MuscleVisualError(
        message: failure.message,
        period: event.newPeriod,
      )),
      (visualData) {
        // Store in cache
        _periodCache[event.newPeriod] = visualData;
        _cacheTimestamps[event.newPeriod] = DateTime.now();
        
        emit(MuscleVisualLoaded(
          muscleData: visualData,
          currentPeriod: event.newPeriod,
          loadedAt: DateTime.now(),
        ));
      },
    );
  }
  
  /// Refresh current period data (after workout logged)
  /// 
  /// Optimized: Only invalidates current period, keeps other periods cached
  Future<void> _onRefreshVisuals(
    RefreshVisualsEvent event,
    Emitter<MuscleVisualState> emit,
  ) async {
    // Invalidate current period cache
    _periodCache.remove(_currentPeriod);
    _cacheTimestamps.remove(_currentPeriod);
    
    // Reload current period
    emit(MuscleVisualLoading(_currentPeriod));
    
    final result = await getMuscleVisualData(_currentPeriod);
    
    result.fold(
      (failure) => emit(MuscleVisualError(
        message: failure.message,
        period: _currentPeriod,
      )),
      (visualData) {
        // Store in cache
        _periodCache[_currentPeriod] = visualData;
        _cacheTimestamps[_currentPeriod] = DateTime.now();
        
        emit(MuscleVisualLoaded(
          muscleData: visualData,
          currentPeriod: _currentPeriod,
          loadedAt: DateTime.now(),
        ));
      },
    );
  }
  
  /// Clear all cached data and force reload
  Future<void> _onClearCache(
    ClearCacheEvent event,
    Emitter<MuscleVisualState> emit,
  ) async {
    _periodCache.clear();
    _cacheTimestamps.clear();
    
    // Reload current period
    add(LoadMuscleVisualsEvent(_currentPeriod));
  }
  
  /// Check if cached data is valid for a given period
  bool _isCacheValid(TimePeriod period) {
    if (!_periodCache.containsKey(period)) return false;
    if (!_cacheTimestamps.containsKey(period)) return false;
    
    final cacheAge = DateTime.now().difference(_cacheTimestamps[period]!);
    return cacheAge <= _cacheValidityDuration;
  }
  
  /// Get currently selected time period
  TimePeriod get currentPeriod => _currentPeriod;
  
  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_periods': _periodCache.keys.toList(),
      'cache_sizes': _periodCache.map(
        (period, data) => MapEntry(period.toString(), data.length),
      ),
      'current_period': _currentPeriod.toString(),
    };
  }
  
  @override
  Future<void> close() {
    // Clean up cache on BLoC disposal
    _periodCache.clear();
    _cacheTimestamps.clear();
    return super.close();
  }
}