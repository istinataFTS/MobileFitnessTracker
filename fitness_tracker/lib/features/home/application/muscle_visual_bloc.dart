import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/muscle_visual_data.dart';
import '../../../domain/entities/time_period.dart';
import '../../../domain/usecases/muscle_stimulus/get_muscle_visual_data.dart';

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

class RefreshVisualsEvent extends MuscleVisualEvent {
  const RefreshVisualsEvent();
}

class ClearCacheEvent extends MuscleVisualEvent {
  const ClearCacheEvent();
}

abstract class MuscleVisualState extends Equatable {
  const MuscleVisualState();

  @override
  List<Object?> get props => <Object?>[];
}

class MuscleVisualInitial extends MuscleVisualState {
  const MuscleVisualInitial();
}

class MuscleVisualLoading extends MuscleVisualState {
  const MuscleVisualLoading(this.period);

  final TimePeriod period;

  @override
  List<Object?> get props => <Object?>[period];
}

class MuscleVisualLoaded extends MuscleVisualState {
  const MuscleVisualLoaded({
    required this.muscleData,
    required this.currentPeriod,
    required this.loadedAt,
  });

  final Map<String, MuscleVisualData> muscleData;
  final TimePeriod currentPeriod;
  final DateTime loadedAt;

  int get trainedMuscleCount =>
      muscleData.values.where((MuscleVisualData data) => data.hasTrained).length;

  bool get hasAnyTraining =>
      muscleData.values.any((MuscleVisualData data) => data.hasTrained);

  @override
  List<Object?> get props => <Object?>[muscleData, currentPeriod, loadedAt];
}

class MuscleVisualError extends MuscleVisualState {
  const MuscleVisualError({
    required this.message,
    required this.period,
  });

  final String message;
  final TimePeriod period;

  @override
  List<Object?> get props => <Object?>[message, period];
}

class MuscleVisualBloc extends Bloc<MuscleVisualEvent, MuscleVisualState> {
  MuscleVisualBloc({
    required this.getMuscleVisualData,
  }) : super(const MuscleVisualInitial()) {
    on<LoadMuscleVisualsEvent>(_onLoadMuscleVisuals);
    on<ChangePeriodEvent>(_onChangePeriod);
    on<RefreshVisualsEvent>(_onRefreshVisuals);
    on<ClearCacheEvent>(_onClearCache);
  }

  final GetMuscleVisualData getMuscleVisualData;

  final Map<TimePeriod, Map<String, MuscleVisualData>> _periodCache =
      <TimePeriod, Map<String, MuscleVisualData>>{};
  final Map<TimePeriod, DateTime> _cacheTimestamps = <TimePeriod, DateTime>{};

  TimePeriod _currentPeriod = TimePeriod.week;

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
        ),
      );
      return;
    }

    emit(MuscleVisualLoading(event.period));

    final result = await getMuscleVisualData(event.period);

    result.fold(
      (failure) => emit(
        MuscleVisualError(
          message: failure.message,
          period: event.period,
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
          ),
        );
      },
    );
  }

  Future<void> _onChangePeriod(
    ChangePeriodEvent event,
    Emitter<MuscleVisualState> emit,
  ) async {
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
        ),
      );
      return;
    }

    emit(MuscleVisualLoading(event.newPeriod));

    final result = await getMuscleVisualData(event.newPeriod);

    result.fold(
      (failure) => emit(
        MuscleVisualError(
          message: failure.message,
          period: event.newPeriod,
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
          ),
        );
      },
    );
  }

  Future<void> _onRefreshVisuals(
    RefreshVisualsEvent event,
    Emitter<MuscleVisualState> emit,
  ) async {
    _periodCache.remove(_currentPeriod);
    _cacheTimestamps.remove(_currentPeriod);

    emit(MuscleVisualLoading(_currentPeriod));

    final result = await getMuscleVisualData(_currentPeriod);

    result.fold(
      (failure) => emit(
        MuscleVisualError(
          message: failure.message,
          period: _currentPeriod,
        ),
      ),
      (visualData) {
        final DateTime now = DateTime.now();
        _periodCache[_currentPeriod] = visualData;
        _cacheTimestamps[_currentPeriod] = now;

        emit(
          MuscleVisualLoaded(
            muscleData: visualData,
            currentPeriod: _currentPeriod,
            loadedAt: now,
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
}