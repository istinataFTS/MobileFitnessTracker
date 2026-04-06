import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/domain/entities/muscle_visual_data.dart';
import 'package:fitness_tracker/domain/entities/time_period.dart';
import 'package:fitness_tracker/domain/muscle_visual/muscle_visual_contract.dart';
import 'package:fitness_tracker/domain/usecases/muscle_stimulus/get_muscle_visual_data.dart';
import 'package:fitness_tracker/features/home/application/muscle_visual_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetMuscleVisualData extends Mock implements GetMuscleVisualData {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _chestData = MuscleVisualData(
  muscleGroup: 'chest',
  totalStimulus: 2.0,
  threshold: 5.0,
  visualIntensity: 0.4,
  bucket: MuscleVisualBucket.light,
  coverageState: MuscleVisualCoverageState.partial,
  aggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
  visibleSurfaces: {MuscleVisualSurface.front},
  overflowAmount: 0.0,
  hasTrained: true,
);

const _weekData = <String, MuscleVisualData>{'chest': _chestData};
const _dbFailure = DatabaseFailure('db error');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Matches a [MuscleVisualLoaded] by its observable fields, ignoring [loadedAt]
/// which is set internally via [DateTime.now()].
TypeMatcher<MuscleVisualLoaded> _isLoaded({
  required TimePeriod period,
  Map<String, MuscleVisualData> data = _weekData,
  MuscleMapMode mode = MuscleMapMode.volume,
}) =>
    isA<MuscleVisualLoaded>()
        .having((s) => s.currentPeriod, 'currentPeriod', period)
        .having((s) => s.muscleData, 'muscleData', data)
        .having((s) => s.mode, 'mode', mode);

void main() {
  late MockGetMuscleVisualData mockGet;

  MuscleVisualBloc buildBloc() =>
      MuscleVisualBloc(getMuscleVisualData: mockGet);

  setUp(() {
    mockGet = MockGetMuscleVisualData();
  });

  group('MuscleVisualBloc', () {
    group('LoadMuscleVisualsEvent', () {
      blocTest<MuscleVisualBloc, MuscleVisualState>(
        'emits [Loading, Loaded] on success',
        build: buildBloc,
        setUp: () {
          when(() => mockGet(TimePeriod.week))
              .thenAnswer((_) async => const Right(_weekData));
        },
        act: (bloc) => bloc.add(const LoadMuscleVisualsEvent(TimePeriod.week)),
        expect: () => [
          const MuscleVisualLoading(TimePeriod.week),
          _isLoaded(period: TimePeriod.week),
        ],
      );

      blocTest<MuscleVisualBloc, MuscleVisualState>(
        'emits [Loading, Error] on use case failure',
        build: buildBloc,
        setUp: () {
          when(() => mockGet(TimePeriod.week))
              .thenAnswer((_) async => const Left(_dbFailure));
        },
        act: (bloc) => bloc.add(const LoadMuscleVisualsEvent(TimePeriod.week)),
        expect: () => [
          const MuscleVisualLoading(TimePeriod.week),
          const MuscleVisualError(message: 'db error', period: TimePeriod.week),
        ],
      );

      blocTest<MuscleVisualBloc, MuscleVisualState>(
        'serves second load from cache without a second use-case call',
        build: buildBloc,
        setUp: () {
          when(() => mockGet(TimePeriod.week))
              .thenAnswer((_) async => const Right(_weekData));
        },
        act: (bloc) async {
          bloc.add(const LoadMuscleVisualsEvent(TimePeriod.week));
          await Future<void>.delayed(Duration.zero);
          // Second load: cache hit emits same state, BLoC deduplicates it
          bloc.add(const LoadMuscleVisualsEvent(TimePeriod.week));
        },
        expect: () => [
          const MuscleVisualLoading(TimePeriod.week),
          _isLoaded(period: TimePeriod.week),
        ],
        // The use case must only be called once despite two load events
        verify: (_) => verify(() => mockGet(TimePeriod.week)).called(1),
      );
    });

    group('ChangePeriodEvent', () {
      blocTest<MuscleVisualBloc, MuscleVisualState>(
        'loads data for the new period',
        build: buildBloc,
        setUp: () {
          when(() => mockGet(TimePeriod.today))
              .thenAnswer((_) async => const Right(_weekData));
        },
        act: (bloc) => bloc.add(const ChangePeriodEvent(TimePeriod.today)),
        expect: () => [
          const MuscleVisualLoading(TimePeriod.today),
          _isLoaded(period: TimePeriod.today),
        ],
      );

      blocTest<MuscleVisualBloc, MuscleVisualState>(
        'is a no-op when the same period is already loaded',
        build: buildBloc,
        seed: () => MuscleVisualLoaded(
          muscleData: _weekData,
          currentPeriod: TimePeriod.week,
          loadedAt: DateTime(2026, 4, 7),
        ),
        // _currentPeriod defaults to week; state is Loaded → no-op
        act: (bloc) => bloc.add(const ChangePeriodEvent(TimePeriod.week)),
        expect: () => <MuscleVisualState>[],
      );

      blocTest<MuscleVisualBloc, MuscleVisualState>(
        'switches to volume mode when period is changed while in fatigue mode',
        build: buildBloc,
        setUp: () {
          when(() => mockGet(TimePeriod.week))
              .thenAnswer((_) async => const Right(_weekData));
          when(() => mockGet(TimePeriod.today))
              .thenAnswer((_) async => const Right(_weekData));
        },
        act: (bloc) async {
          // First load week to populate cache
          bloc.add(const LoadMuscleVisualsEvent(TimePeriod.week));
          await Future<void>.delayed(Duration.zero);
          // Switch to fatigue mode (sets _currentMode = fatigue)
          bloc.add(const ChangeModeEvent(MuscleMapMode.fatigue));
          await Future<void>.delayed(Duration.zero);
          // Change period → must flip back to volume
          bloc.add(const ChangePeriodEvent(TimePeriod.today));
        },
        expect: () => [
          const MuscleVisualLoading(TimePeriod.week),
          _isLoaded(period: TimePeriod.week, mode: MuscleMapMode.volume),
          // fatigue mode load uses week data from cache
          _isLoaded(period: TimePeriod.week, mode: MuscleMapMode.fatigue),
          // after period change, volume is restored
          const MuscleVisualLoading(
            TimePeriod.today,
            mode: MuscleMapMode.volume,
          ),
          _isLoaded(period: TimePeriod.today, mode: MuscleMapMode.volume),
        ],
      );
    });

    group('ChangeModeEvent', () {
      blocTest<MuscleVisualBloc, MuscleVisualState>(
        'fatigue mode fetches week data regardless of current period',
        build: buildBloc,
        setUp: () {
          when(() => mockGet(TimePeriod.today))
              .thenAnswer((_) async => const Right(_weekData));
          when(() => mockGet(TimePeriod.week))
              .thenAnswer((_) async => const Right(_weekData));
        },
        act: (bloc) async {
          // Load today first so _currentPeriod = today
          bloc.add(const LoadMuscleVisualsEvent(TimePeriod.today));
          await Future<void>.delayed(Duration.zero);
          // Switch to fatigue → should fetch week, not today
          bloc.add(const ChangeModeEvent(MuscleMapMode.fatigue));
        },
        expect: () => [
          const MuscleVisualLoading(TimePeriod.today),
          _isLoaded(period: TimePeriod.today, mode: MuscleMapMode.volume),
          const MuscleVisualLoading(
            TimePeriod.today,
            mode: MuscleMapMode.fatigue,
          ),
          _isLoaded(period: TimePeriod.today, mode: MuscleMapMode.fatigue),
        ],
        verify: (_) {
          verify(() => mockGet(TimePeriod.today)).called(1);
          verify(() => mockGet(TimePeriod.week)).called(1);
        },
      );

      blocTest<MuscleVisualBloc, MuscleVisualState>(
        'serves from cache when week data is already cached for fatigue mode',
        build: buildBloc,
        setUp: () {
          when(() => mockGet(TimePeriod.week))
              .thenAnswer((_) async => const Right(_weekData));
        },
        act: (bloc) async {
          // Load week first → caches week data
          bloc.add(const LoadMuscleVisualsEvent(TimePeriod.week));
          await Future<void>.delayed(Duration.zero);
          // Switch to fatigue → week cache is valid, no second fetch
          bloc.add(const ChangeModeEvent(MuscleMapMode.fatigue));
        },
        expect: () => [
          const MuscleVisualLoading(TimePeriod.week),
          _isLoaded(period: TimePeriod.week, mode: MuscleMapMode.volume),
          _isLoaded(period: TimePeriod.week, mode: MuscleMapMode.fatigue),
        ],
        verify: (_) => verify(() => mockGet(TimePeriod.week)).called(1),
      );

      blocTest<MuscleVisualBloc, MuscleVisualState>(
        'is a no-op when already in the same mode and loaded',
        build: buildBloc,
        seed: () => MuscleVisualLoaded(
          muscleData: _weekData,
          currentPeriod: TimePeriod.week,
          loadedAt: DateTime(2026, 4, 7),
        ),
        act: (bloc) => bloc.add(const ChangeModeEvent(MuscleMapMode.volume)),
        expect: () => <MuscleVisualState>[],
      );
    });

    group('RefreshVisualsEvent', () {
      blocTest<MuscleVisualBloc, MuscleVisualState>(
        'bypasses cache and reloads current period',
        build: buildBloc,
        setUp: () {
          when(() => mockGet(TimePeriod.week))
              .thenAnswer((_) async => const Right(_weekData));
        },
        act: (bloc) async {
          // Load once to populate cache
          bloc.add(const LoadMuscleVisualsEvent(TimePeriod.week));
          await Future<void>.delayed(Duration.zero);
          // Refresh clears cache and reloads
          bloc.add(const RefreshVisualsEvent());
        },
        expect: () => [
          const MuscleVisualLoading(TimePeriod.week),
          _isLoaded(period: TimePeriod.week),
          const MuscleVisualLoading(TimePeriod.week),
          _isLoaded(period: TimePeriod.week),
        ],
        verify: (_) => verify(() => mockGet(TimePeriod.week)).called(2),
      );
    });

    group('ClearCacheEvent', () {
      blocTest<MuscleVisualBloc, MuscleVisualState>(
        'clears cache and triggers a fresh load of the current period',
        build: buildBloc,
        setUp: () {
          when(() => mockGet(TimePeriod.week))
              .thenAnswer((_) async => const Right(_weekData));
        },
        act: (bloc) => bloc.add(const ClearCacheEvent()),
        expect: () => [
          const MuscleVisualLoading(TimePeriod.week),
          _isLoaded(period: TimePeriod.week),
        ],
      );
    });
  });
}
