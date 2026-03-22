import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/domain/entities/entity_sync_metadata.dart';
import 'package:fitness_tracker/domain/entities/exercise.dart';
import 'package:fitness_tracker/domain/entities/muscle_visual_data.dart';
import 'package:fitness_tracker/domain/entities/nutrition_log.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:fitness_tracker/domain/entities/time_period.dart';
import 'package:fitness_tracker/domain/entities/workout_set.dart';
import 'package:fitness_tracker/features/home/application/home_bloc.dart';
import 'package:fitness_tracker/features/home/application/models/home_dashboard_data.dart';
import 'package:fitness_tracker/features/home/application/muscle_visual_bloc.dart';
import 'package:fitness_tracker/features/home/presentation/home_page.dart';
import 'package:fitness_tracker/features/settings/application/app_settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class MockMuscleVisualBloc
    extends MockBloc<MuscleVisualEvent, MuscleVisualState>
    implements MuscleVisualBloc {}

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

class FakeHomeEvent extends Fake implements HomeEvent {}

class FakeHomeState extends Fake implements HomeState {}

class FakeMuscleVisualEvent extends Fake implements MuscleVisualEvent {}

class FakeMuscleVisualState extends Fake implements MuscleVisualState {}

void main() {
  late MockHomeBloc homeBloc;
  late MockMuscleVisualBloc muscleVisualBloc;
  late MockAppSettingsCubit appSettingsCubit;

  final DateTime now = DateTime(2026, 3, 19, 10, 0);

  final AppSettingsState settingsState = AppSettingsState(
    settings: const AppSettings.defaults(),
    isLoading: false,
    isSaving: false,
    hasLoaded: true,
    errorMessage: null,
  );

  final HomeLoaded loadedHomeState = HomeLoaded(
    data: HomeDashboardData(
      targets: <Target>[
        Target(
          id: 'target-chest',
          type: TargetType.muscleSets,
          categoryKey: 'chest',
          targetValue: 6,
          unit: 'sets',
          period: TargetPeriod.weekly,
          createdAt: now,
          syncMetadata: const EntitySyncMetadata(),
        ),
      ],
      weeklySets: <WorkoutSet>[
        WorkoutSet(
          id: 'set-1',
          exerciseId: 'bench-press',
          reps: 8,
          weight: 80,
          date: now,
          createdAt: now,
          syncMetadata: const EntitySyncMetadata(),
        ),
      ],
      todaysLogs: const <NutritionLog>[],
      dailyMacros: const <String, double>{},
      exercises: <Exercise>[
        Exercise(
          id: 'bench-press',
          name: 'Bench Press',
          muscleGroups: <String>['chest'],
          createdAt: now,
          syncMetadata: const EntitySyncMetadata(),
        ),
      ],
    ),
  );

  setUpAll(() {
    registerFallbackValue(FakeHomeEvent());
    registerFallbackValue(FakeHomeState());
    registerFallbackValue(FakeMuscleVisualEvent());
    registerFallbackValue(FakeMuscleVisualState());
  });

  setUp(() {
    homeBloc = MockHomeBloc();
    muscleVisualBloc = MockMuscleVisualBloc();
    appSettingsCubit = MockAppSettingsCubit();

    when(() => appSettingsCubit.state).thenReturn(settingsState);
    whenListen<AppSettingsState>(
      appSettingsCubit,
      Stream<AppSettingsState>.fromIterable(<AppSettingsState>[settingsState]),
      initialState: settingsState,
    );

    when(() => homeBloc.state).thenReturn(loadedHomeState);
    whenListen<HomeState>(
      homeBloc,
      const Stream<HomeState>.empty(),
      initialState: loadedHomeState,
    );
  });

  Widget buildSubject() {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<AppSettingsCubit>.value(value: appSettingsCubit),
        BlocProvider<HomeBloc>.value(value: homeBloc),
        BlocProvider<MuscleVisualBloc>.value(value: muscleVisualBloc),
      ],
      child: const MaterialApp(
        home: HomePage(),
      ),
    );
  }

  group('HomePage muscle summary rendering', () {
    testWidgets('shows empty summary list when no trained muscles are present', (
      WidgetTester tester,
    ) async {
      when(() => muscleVisualBloc.state).thenReturn(
        MuscleVisualLoaded(
          muscleData: const <String, MuscleVisualData>{},
          currentPeriod: TimePeriod.week,
          loadedAt: now,
        ),
      );
      whenListen<MuscleVisualState>(
        muscleVisualBloc,
        const Stream<MuscleVisualState>.empty(),
        initialState: MuscleVisualLoaded(
          muscleData: const <String, MuscleVisualData>{},
          currentPeriod: TimePeriod.week,
          loadedAt: now,
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.textContaining('Progress'), findsOneWidget);
      expect(find.text('Chest'), findsNothing);
      expect(find.text('Biceps'), findsNothing);
      expect(find.text('Lats'), findsNothing);
    });

    testWidgets('shows ranked trained muscles in display order', (
      WidgetTester tester,
    ) async {
      final MuscleVisualLoaded visualState = MuscleVisualLoaded(
        muscleData: <String, MuscleVisualData>{
          'lats': const MuscleVisualData(
            muscleGroup: 'lats',
            totalStimulus: 20,
            threshold: 20,
            visualIntensity: 0.85,
            bucket: MuscleVisualBucket.maximum,
            coverageState: MuscleVisualCoverageState.full,
            aggregationMode: MuscleVisualAggregationMode.cumulative,
            visibleSurfaces: <MuscleVisualSurface>{MuscleVisualSurface.back},
            overflowAmount: 0,
            hasTrained: true,
          ),
          'chest': const MuscleVisualData(
            muscleGroup: 'chest',
            totalStimulus: 12,
            threshold: 20,
            visualIntensity: 0.55,
            bucket: MuscleVisualBucket.heavy,
            coverageState: MuscleVisualCoverageState.partial,
            aggregationMode: MuscleVisualAggregationMode.cumulative,
            visibleSurfaces: <MuscleVisualSurface>{MuscleVisualSurface.front},
            overflowAmount: 0,
            hasTrained: true,
          ),
          'biceps': const MuscleVisualData(
            muscleGroup: 'biceps',
            totalStimulus: 7,
            threshold: 20,
            visualIntensity: 0.18,
            bucket: MuscleVisualBucket.light,
            coverageState: MuscleVisualCoverageState.partial,
            aggregationMode: MuscleVisualAggregationMode.cumulative,
            visibleSurfaces: <MuscleVisualSurface>{MuscleVisualSurface.front},
            overflowAmount: 0,
            hasTrained: true,
          ),
        },
        currentPeriod: TimePeriod.week,
        loadedAt: now,
      );

      when(() => muscleVisualBloc.state).thenReturn(visualState);
      whenListen<MuscleVisualState>(
        muscleVisualBloc,
        const Stream<MuscleVisualState>.empty(),
        initialState: visualState,
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      final Finder latsFinder = find.text('Lats');
      final Finder chestFinder = find.text('Chest');
      final Finder bicepsFinder = find.text('Biceps');

      expect(latsFinder, findsOneWidget);
      expect(chestFinder, findsOneWidget);
      expect(bicepsFinder, findsOneWidget);

      expect(
        tester.getTopLeft(latsFinder).dy,
        lessThan(tester.getTopLeft(chestFinder).dy),
      );
      expect(
        tester.getTopLeft(chestFinder).dy,
        lessThan(tester.getTopLeft(bicepsFinder).dy),
      );

      expect(find.text('20 • Maximum'), findsOneWidget);
      expect(find.text('12 • Heavy'), findsOneWidget);
      expect(find.text('7 • Light'), findsOneWidget);
    });

    testWidgets('shows muscle summary rows only for trained muscles', (
      WidgetTester tester,
    ) async {
      final MuscleVisualLoaded visualState = MuscleVisualLoaded(
        muscleData: <String, MuscleVisualData>{
          'chest': const MuscleVisualData(
            muscleGroup: 'chest',
            totalStimulus: 14,
            threshold: 20,
            visualIntensity: 0.55,
            bucket: MuscleVisualBucket.heavy,
            coverageState: MuscleVisualCoverageState.partial,
            aggregationMode: MuscleVisualAggregationMode.cumulative,
            visibleSurfaces: <MuscleVisualSurface>{MuscleVisualSurface.front},
            overflowAmount: 0,
            hasTrained: true,
          ),
          'back': const MuscleVisualData(
            muscleGroup: 'back',
            totalStimulus: 0,
            threshold: 20,
            visualIntensity: 0,
            bucket: MuscleVisualBucket.empty,
            coverageState: MuscleVisualCoverageState.empty,
            aggregationMode: MuscleVisualAggregationMode.cumulative,
            visibleSurfaces: <MuscleVisualSurface>{MuscleVisualSurface.back},
            overflowAmount: 0,
            hasTrained: false,
          ),
        },
        currentPeriod: TimePeriod.week,
        loadedAt: now,
      );

      when(() => muscleVisualBloc.state).thenReturn(visualState);
      whenListen<MuscleVisualState>(
        muscleVisualBloc,
        const Stream<MuscleVisualState>.empty(),
        initialState: visualState,
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('14 • Heavy'), findsOneWidget);
      expect(find.text('Back'), findsNothing);
    });
  });
}