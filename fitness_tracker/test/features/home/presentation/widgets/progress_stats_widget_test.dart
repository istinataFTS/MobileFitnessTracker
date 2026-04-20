import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/domain/entities/entity_sync_metadata.dart';
import 'package:fitness_tracker/domain/entities/muscle_visual_data.dart';
import 'package:fitness_tracker/domain/entities/nutrition_log.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:fitness_tracker/domain/entities/time_period.dart';
import 'package:fitness_tracker/domain/entities/workout_set.dart';
import 'package:fitness_tracker/domain/muscle_visual/muscle_visual_contract.dart';
import 'package:fitness_tracker/features/home/application/home_bloc.dart';
import 'package:fitness_tracker/features/home/application/models/home_dashboard_data.dart';
import 'package:fitness_tracker/features/home/application/muscle_visual_bloc.dart';
import 'package:fitness_tracker/features/home/presentation/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class MockMuscleVisualBloc
    extends MockBloc<MuscleVisualEvent, MuscleVisualState>
    implements MuscleVisualBloc {}

class FakeHomeEvent extends Fake implements HomeEvent {}

class FakeHomeState extends Fake implements HomeState {}

class FakeMuscleVisualEvent extends Fake implements MuscleVisualEvent {}

class FakeMuscleVisualState extends Fake implements MuscleVisualState {}

void main() {
  late MockHomeBloc homeBloc;
  late MockMuscleVisualBloc muscleVisualBloc;

  final DateTime now = DateTime(2026, 3, 19, 10, 0);

  const AppSettings settings = AppSettings.defaults();

  final HomeLoaded loadedHomeState = HomeLoaded(
    data: HomeDashboardData(
      targets: <Target>[
        Target(
          id: 'target-chest',
          type: TargetType.muscleSets,
          categoryKey: 'chest',
          targetValue: 12,
          unit: 'sets',
          period: TargetPeriod.weekly,
          createdAt: now,
          syncMetadata: const EntitySyncMetadata(),
        ),
      ],
      weeklySets: List<WorkoutSet>.generate(
        9,
        (int index) => WorkoutSet(
          id: 'set-$index',
          exerciseId: 'bench-press',
          reps: 8,
          weight: 80,
          intensity: 8,
          date: now,
          createdAt: now,
          syncMetadata: const EntitySyncMetadata(),
        ),
      ),
      todaysLogs: const <NutritionLog>[],
      dailyMacros: const <String, double>{},
      weeklySetCount: 9,
    ),
  );

  final MuscleVisualLoaded loadedMuscleState = MuscleVisualLoaded(
    muscleData: <String, MuscleVisualData>{
      'chest': MuscleVisualData(
        muscleGroup: 'chest',
        totalStimulus: 18,
        threshold: 6,
        visualIntensity: 1.0,
        bucket: MuscleVisualBucket.maximum,
        coverageState: MuscleVisualCoverageState.full,
        aggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
        visibleSurfaces: const <MuscleVisualSurface>{
          MuscleVisualSurface.front,
        },
        overflowAmount: 0,
        hasTrained: true,
      ),
    },
    currentPeriod: TimePeriod.week,
    loadedAt: now,
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

    when(() => homeBloc.state).thenReturn(loadedHomeState);
    whenListen<HomeState>(
      homeBloc,
      const Stream<HomeState>.empty(),
      initialState: loadedHomeState,
    );

    when(() => muscleVisualBloc.state).thenReturn(loadedMuscleState);
    whenListen<MuscleVisualState>(
      muscleVisualBloc,
      const Stream<MuscleVisualState>.empty(),
      initialState: loadedMuscleState,
    );
  });

  Widget buildSubject() {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<HomeBloc>.value(value: homeBloc),
        BlocProvider<MuscleVisualBloc>.value(value: muscleVisualBloc),
      ],
      child: const MaterialApp(
        home: HomePage(settings: settings),
      ),
    );
  }

  group('HomePage progress section', () {
    testWidgets('renders prepared progress stats inside the page', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.textContaining('Progress'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsWidgets);

      expect(find.text('Sets'), findsOneWidget);
      expect(find.text('Target'), findsOneWidget);
      expect(find.text('Muscles'), findsOneWidget);

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('renders muted target placeholder when target is hidden', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final MuscleVisualLoaded allTimeState = MuscleVisualLoaded(
        muscleData: <String, MuscleVisualData>{
          'chest': MuscleVisualData(
            muscleGroup: 'chest',
            totalStimulus: 18,
            threshold: 6,
            visualIntensity: 1.0,
            bucket: MuscleVisualBucket.maximum,
            coverageState: MuscleVisualCoverageState.full,
            aggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
            visibleSurfaces: const <MuscleVisualSurface>{
              MuscleVisualSurface.front,
            },
            overflowAmount: 0,
            hasTrained: true,
          ),
        },
        currentPeriod: TimePeriod.allTime,
        loadedAt: now,
      );

      when(() => muscleVisualBloc.state).thenReturn(allTimeState);
      whenListen<MuscleVisualState>(
        muscleVisualBloc,
        const Stream<MuscleVisualState>.empty(),
        initialState: allTimeState,
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('-'), findsOneWidget);
      expect(find.text('Target'), findsOneWidget);
    });

    testWidgets('shows visual error state and retry action', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      when(() => muscleVisualBloc.state).thenReturn(
        const MuscleVisualError(
          message: 'visual load failed',
          period: TimePeriod.week,
        ),
      );
      whenListen<MuscleVisualState>(
        muscleVisualBloc,
        const Stream<MuscleVisualState>.empty(),
        initialState: const MuscleVisualError(
          message: 'visual load failed',
          period: TimePeriod.week,
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('visual load failed'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pump();

      verify(() => muscleVisualBloc.add(const RefreshVisualsEvent())).called(1);
    });
  });
}