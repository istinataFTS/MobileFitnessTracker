import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/muscle_visual_data.dart';
import '../../../domain/entities/time_period.dart';
import '../../../domain/usecases/muscle_stimulus/get_muscle_visual_data.dart';

/// Controls what the 2D human model visualises.
///
/// - [volume]: training load for the selected time period (today / week / month / all-time).
/// - [fatigue]: current accumulated fatigue based on the rolling weekly load,
///   independent of the period selector.  If the user trained heavily 4–5 days
///   in a row and then rests today, volume (today) is gray while fatigue is
///   orange/red because the muscles have not yet recovered.
enum MuscleMapMode { volume, fatigue }

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class MuscleVisualEvent extends Equatable {
  const MuscleVisualEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class LoadMuscleVisualsEvent extends MuscleVisualEvent {
  const LoadMuscleVisualsEvent(this.period);

  final TimePeriod period;

  @override
  List<Object?> get props => <Object?>[period];
}

class ChangePeriodEvent extends MuscleVisualEvent {
  const ChangePeriodEvent(this.newPeriod);

  final TimePeriod newPeriod;

  @override
  List<Object?> get props => <Object?>[newPeriod];
}

class ChangeModeEvent extends MuscleVisualEvent {
  const ChangeModeEvent(this.mode);

  final MuscleMapMode mode;

  @override
  List<Object?> get props => <Object?>[mode];
}

class RefreshVisualsEvent extends MuscleVisualEvent {
  const RefreshVisualsEvent();
}

class ClearCacheEvent extends MuscleVisualEvent {
  const ClearCacheEvent();
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class MuscleVisualState extends Equatable {
  const MuscleVisualState();

  @override
  List<Object?> get props => <Object?>[];
}

class MuscleVisualInitial extends MuscleVisualState {
  const MuscleVisualInitial();
}

class MuscleVisualLoading extends MuscleVisualState {
  const MuscleVisualLoading(this.period, {this.mode = MuscleMapMode.volume});

  final TimePeriod period;
  final MuscleMapMode mode;

  @override
  List<Object?> get props => <Object?>[period, mode];
}

class MuscleVisualLoaded extends MuscleVisualState {
  const MuscleVisualLoaded({
    required this.muscleData,
    required this.currentPeriod,
    required this.loadedAt,
    this.mode = MuscleMapMode.volume,
  });

  final Map<String, MuscleVisualData> muscleData;
  final TimePeriod currentPeriod;
  final DateTime loadedAt;
  final MuscleMapMode mode;

  int get trainedMuscleCount =>
      muscleData.values.where((MuscleVisualData data) => data.hasTrained).length;

  bool get hasAnyTraining =>
      muscleData.values.any((MuscleVisualData data) => data.hasTrained);

  @override
  List<Object?> get props => <Object?>[muscleData, currentPeriod, loadedAt, mode];
}

class MuscleVisualError extends MuscleVisualState {
  const MuscleVisualError({
    required this.message,
    required this.period,
    this.mode = MuscleMapMode.volume,
  });

  final String message;
  final TimePeriod period;
  final MuscleMapMode mode;

  @override
  List<Object?> get props => <Object?>[message, period, mode];
}

class MuscleVisualBloc extends Bloc<MuscleVisualEvent, MuscleVisualState> {
  MuscleVisualBloc({
    required this.getMuscleVisualData,
  }) : super(const MuscleVisualInitial()) {
    on<LoadMuscleVisualsEvent>(_onLoadMuscleVisuals);
    on<ChangePeriodEvent>(_onChangePeriod);
    on<ChangeModeEvent>(_onChangeMode);
    on<RefreshVisualsEvent>(_onRefreshVisuals);
    on<ClearCacheEvent>(_onClearCache);
  }

  final GetMuscleVisualData getMuscleVisualData;

  final Map<TimePeriod, Map<String, MuscleVisualData>> _periodCache =
      <TimePeriod, Map<String, MuscleVisualData>>{};
  final Map<TimePeriod, DateTime> _cacheTimestamps = <TimePeriod, DateTime>{};

  TimePeriod _currentPeriod = TimePeriod.week;
  MuscleMapMode _currentMode = MuscleMapMode.volume;

  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  Future<void> _onLoadMuscleVisuals(
    LoadMuscleVisualsEvent event,
    Emitter<MuscleVisualState> emit,
  ) async {
    _currentPeriod = event.period;

    if (_isCacheValid(event.period)) {
      emit(
        MuscleVisualLoaded(
          muscleData: _periodCache[event.period]!,
          currentPeriod: event.period,
          loadedAt: _cacheTimestamps[event.period]!,
          mode: _currentMode,
        ),
      );
      return;
    }

    emit(MuscleVisualLoading(event.period, mode: _currentMode));

    final result = await getMuscleVisualData(event.period);

    result.fold(
      (failure) => emit(
        MuscleVisualError(
          message: failure.message,
          period: event.period,
          mode: _currentMode,
        ),
      ),
      (visualData) {
        final DateTime now = DateTime.now();
        _periodCache[event.period] = visualData;
        _cacheTimestamps[event.period] = now;

        emit(
          MuscleVisualLoaded(
            muscleData: visualData,
            currentPeriod: event.period,
            loadedAt: now,
            mode: _currentMode,
          ),
        );
      },
    );
  }

  Future<void> _onChangePeriod(
    ChangePeriodEvent event,
    Emitter<MuscleVisualState> emit,
  ) async {
    // Selecting a period while in fatigue mode implicitly switches to volume.
    if (_currentMode == MuscleMapMode.fatigue) {
      _currentMode = MuscleMapMode.volume;
    }

    if (event.newPeriod == _currentPeriod && state is MuscleVisualLoaded) {
      return;
    }

    _currentPeriod = event.newPeriod;

    if (_isCacheValid(event.newPeriod)) {
      emit(
        MuscleVisualLoaded(
          muscleData: _periodCache[event.newPeriod]!,
          currentPeriod: event.newPeriod,
          loadedAt: _cacheTimestamps[event.newPeriod]!,
          mode: _currentMode,
        ),
      );
      return;
    }

    emit(MuscleVisualLoading(event.newPeriod, mode: _currentMode));

    final result = await getMuscleVisualData(event.newPeriod);

    result.fold(
      (failure) => emit(
        MuscleVisualError(
          message: failure.message,
          period: event.newPeriod,
          mode: _currentMode,
        ),
      ),
      (visualData) {
        final DateTime now = DateTime.now();
        _periodCache[event.newPeriod] = visualData;
        _cacheTimestamps[event.newPeriod] = now;

        emit(
          MuscleVisualLoaded(
            muscleData: visualData,
            currentPeriod: event.newPeriod,
            loadedAt: now,
            mode: _currentMode,
          ),
        );
      },
    );
  }

  /// Switches between [MuscleMapMode.volume] and [MuscleMapMode.fatigue].
  ///
  /// Fatigue always reads the rolling weekly load (same underlying data as the
  /// Week period view) but frames it as "how tired are my muscles right now"
  /// rather than "how much did I train this period".
  Future<void> _onChangeMode(
    ChangeModeEvent event,
    Emitter<MuscleVisualState> emit,
  ) async {
    if (_currentMode == event.mode && state is MuscleVisualLoaded) return;
    _currentMode = event.mode;

    // Fatigue always reads the rolling weekly load, regardless of selected period.
    final TimePeriod periodToFetch =
        _currentMode == MuscleMapMode.fatigue ? TimePeriod.week : _currentPeriod;

    if (_isCacheValid(periodToFetch)) {
      emit(
        MuscleVisualLoaded(
          muscleData: _periodCache[periodToFetch]!,
          currentPeriod: _currentPeriod,
          loadedAt: _cacheTimestamps[periodToFetch]!,
          mode: _currentMode,
        ),
      );
      return;
    }

    emit(MuscleVisualLoading(_currentPeriod, mode: _currentMode));

    final result = await getMuscleVisualData(periodToFetch);

    result.fold(
      (failure) => emit(
        MuscleVisualError(
          message: failure.message,
          period: _currentPeriod,
          mode: _currentMode,
        ),
      ),
      (visualData) {
        final DateTime now = DateTime.now();
        _periodCache[periodToFetch] = visualData;
        _cacheTimestamps[periodToFetch] = now;

        emit(
          MuscleVisualLoaded(
            muscleData: visualData,
            currentPeriod: _currentPeriod,
            loadedAt: now,
            mode: _currentMode,
          ),
        );
      },
    );
  }

  Future<void> _onRefreshVisuals(
    RefreshVisualsEvent event,
    Emitter<MuscleVisualState> emit,
  ) async {
    final TimePeriod periodToRefresh =
        _currentMode == MuscleMapMode.fatigue ? TimePeriod.week : _currentPeriod;

    _periodCache.remove(periodToRefresh);
    _cacheTimestamps.remove(periodToRefresh);

    emit(MuscleVisualLoading(_currentPeriod, mode: _currentMode));

    final result = await getMuscleVisualData(periodToRefresh);

    result.fold(
      (failure) => emit(
        MuscleVisualError(
          message: failure.message,
          period: _currentPeriod,
          mode: _currentMode,
        ),
      ),
      (visualData) {
        final DateTime now = DateTime.now();
        _periodCache[periodToRefresh] = visualData;
        _cacheTimestamps[periodToRefresh] = now;

        emit(
          MuscleVisualLoaded(
            muscleData: visualData,
            currentPeriod: _currentPeriod,
            loadedAt: now,
            mode: _currentMode,
          ),
        );
      },
    );
  }

  Future<void> _onClearCache(
    ClearCacheEvent event,
    Emitter<MuscleVisualState> emit,
  ) async {
    _periodCache.clear();
    _cacheTimestamps.clear();
    add(LoadMuscleVisualsEvent(_currentPeriod));
  }

  bool _isCacheValid(TimePeriod period) {
    if (!_periodCache.containsKey(period) ||
        !_cacheTimestamps.containsKey(period)) {
      return false;
    }

    final Duration cacheAge = DateTime.now().difference(
      _cacheTimestamps[period]!,
    );

    return cacheAge <= _cacheValidityDuration;
  }

  @override
  Future<void> close() {
    _periodCache.clear();
    _cacheTimestamps.clear();
    return super.close();
  }
}