import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/domain/entities/entity_sync_metadata.dart';
import 'package:fitness_tracker/domain/entities/exercise.dart';
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
import 'package:fitness_tracker/features/home/presentation/widgets/period_selector_widget.dart';
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

  final HomeDashboardData loadedHomeData = HomeDashboardData(
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
      Target(
        id: 'target-protein',
        type: TargetType.macro,
        categoryKey: 'protein',
        targetValue: 180,
        unit: 'g',
        period: TargetPeriod.daily,
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
        intensity: 8,
        date: now,
        createdAt: now,
        syncMetadata: const EntitySyncMetadata(),
      ),
    ],
    todaysLogs: <NutritionLog>[
      NutritionLog(
        id: 'log-1',
        mealName: 'Chicken and Rice',
        proteinGrams: 45,
        carbsGrams: 60,
        fatGrams: 12,
        calories: 528,
        loggedAt: now,
        createdAt: now,
        syncMetadata: const EntitySyncMetadata(),
      ),
    ],
    dailyMacros: const <String, double>{
      'protein': 120,
      'carbs': 140,
      'fats': 40,
      'calories': 1600,
    },
    exercises: <Exercise>[
      Exercise(
        id: 'bench-press',
        name: 'Bench Press',
        muscleGroups: <String>['chest'],
        createdAt: now,
        syncMetadata: const EntitySyncMetadata(),
      ),
    ],
  );

  final HomeLoaded loadedHomeState = HomeLoaded(
    data: loadedHomeData,
  );

  final MuscleVisualLoaded loadedMuscleState = MuscleVisualLoaded(
    muscleData: <String, MuscleVisualData>{
      'chest': MuscleVisualData(
        muscleGroup: 'chest',
        totalStimulus: 6,
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

  testWidgets('shows dedicated page loading indicator for HomeInitial', (
    WidgetTester tester,
  ) async {
    when(() => homeBloc.state).thenReturn(const HomeInitial());
    whenListen<HomeState>(
      homeBloc,
      const Stream<HomeState>.empty(),
      initialState: const HomeInitial(),
    );

    await tester.pumpWidget(buildSubject());

    expect(find.byKey(HomePage.pageLoadingIndicatorKey), findsOneWidget);
  });

  testWidgets('shows dedicated page loading indicator for HomeLoading', (
    WidgetTester tester,
  ) async {
    when(() => homeBloc.state).thenReturn(const HomeLoading());
    whenListen<HomeState>(
      homeBloc,
      const Stream<HomeState>.empty(),
      initialState: const HomeLoading(),
    );

    await tester.pumpWidget(buildSubject());

    expect(find.byKey(HomePage.pageLoadingIndicatorKey), findsOneWidget);
  });

  testWidgets('home-level retry dispatches LoadHomeDataEvent', (
    WidgetTester tester,
  ) async {
    when(() => homeBloc.state).thenReturn(const HomeError('load failed'));
    whenListen<HomeState>(
      homeBloc,
      const Stream<HomeState>.empty(),
      initialState: const HomeError('load failed'),
    );

    await tester.pumpWidget(buildSubject());

    expect(find.byKey(HomePage.homeRetryButtonKey), findsOneWidget);

    await tester.tap(find.byKey(HomePage.homeRetryButtonKey));
    await tester.pump();

    verify(() => homeBloc.add(const LoadHomeDataEvent())).called(1);
  });

  testWidgets('renders core loaded sections through stable feature keys', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.byKey(HomePage.refreshListKey), findsOneWidget);
    expect(find.byKey(HomePage.progressCardKey), findsOneWidget);
    expect(find.byKey(HomePage.latestEntriesSectionKey), findsOneWidget);
    expect(find.byKey(HomePage.muscleGroupsSectionKey), findsOneWidget);
    expect(find.byKey(HomePage.totalSetsValueKey), findsOneWidget);
    expect(find.byKey(HomePage.targetValueKey), findsOneWidget);
    expect(find.byKey(HomePage.trainedMusclesValueKey), findsOneWidget);

    expect(find.text('Chicken and Rice'), findsOneWidget);
    expect(find.text('Progress • Week'), findsOneWidget);
  });

  testWidgets('period selector exposes stable key and dispatches month change', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.byKey(PeriodSelectorWidget.dropdownKey), findsOneWidget);

    await tester.tap(find.byKey(PeriodSelectorWidget.dropdownKey));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(PeriodSelectorWidget.menuItemKey(TimePeriod.month)).last,
    );
    await tester.pumpAndSettle();

    verify(
      () => muscleVisualBloc.add(ChangePeriodEvent(TimePeriod.month)),
    ).called(1);
  });

  testWidgets('visual retry uses progress retry button key', (
    WidgetTester tester,
  ) async {
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

    expect(find.byKey(HomePage.progressRetryButtonKey), findsOneWidget);

    await tester.tap(find.byKey(HomePage.progressRetryButtonKey));
    await tester.pump();

    verify(() => muscleVisualBloc.add(const RefreshVisualsEvent())).called(1);
  });

  testWidgets('visual loading shows dedicated progress loading indicator', (
    WidgetTester tester,
  ) async {
    when(() => muscleVisualBloc.state).thenReturn(
      const MuscleVisualLoading(TimePeriod.month),
    );
    whenListen<MuscleVisualState>(
      muscleVisualBloc,
      const Stream<MuscleVisualState>.empty(),
      initialState: const MuscleVisualLoading(TimePeriod.month),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.byKey(HomePage.progressLoadingIndicatorKey), findsOneWidget);
    expect(find.byKey(PeriodSelectorWidget.dropdownKey), findsOneWidget);
  });

  testWidgets('month period hides weekly target in stable target value field', (
    WidgetTester tester,
  ) async {
    final MuscleVisualLoaded monthState = MuscleVisualLoaded(
      muscleData: <String, MuscleVisualData>{
        'chest': MuscleVisualData(
          muscleGroup: 'chest',
          totalStimulus: 12,
          threshold: 6,
          visualIntensity: 1.0,
          bucket: MuscleVisualBucket.maximum,
          coverageState: MuscleVisualCoverageState.full,
          aggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
          visibleSurfaces: const <MuscleVisualSurface>{
            MuscleVisualSurface.front,
          },
          overflowAmount: 6,
          hasTrained: true,
        ),
      },
      currentPeriod: TimePeriod.month,
      loadedAt: now,
    );

    when(() => muscleVisualBloc.state).thenReturn(monthState);
    whenListen<MuscleVisualState>(
      muscleVisualBloc,
      const Stream<MuscleVisualState>.empty(),
      initialState: monthState,
    );

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Progress • Month'), findsOneWidget);
    expect(find.byKey(HomePage.targetValueKey), findsOneWidget);
    expect(find.text('-'), findsWidgets);
  });

  testWidgets('pull to refresh dispatches both refresh events from refresh list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.drag(
      find.byKey(HomePage.refreshListKey),
      const Offset(0, 300),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(() => homeBloc.add(const RefreshHomeDataEvent())).called(1);
    verify(() => muscleVisualBloc.add(const RefreshVisualsEvent())).called(1);
  });

  testWidgets('muscle group section disappears when there are no training targets', (
    WidgetTester tester,
  ) async {
    final HomeLoaded noTrainingTargetsState = HomeLoaded(
      data: HomeDashboardData(
        targets: <Target>[
          Target(
            id: 'target-protein',
            type: TargetType.macro,
            categoryKey: 'protein',
            targetValue: 180,
            unit: 'g',
            period: TargetPeriod.daily,
            createdAt: now,
            syncMetadata: const EntitySyncMetadata(),
          ),
        ],
        weeklySets: const <WorkoutSet>[],
        todaysLogs: const <NutritionLog>[],
        dailyMacros: const <String, double>{
          'protein': 0,
          'carbs': 0,
          'fats': 0,
          'calories': 0,
        },
        exercises: const <Exercise>[],
      ),
    );

    when(() => homeBloc.state).thenReturn(noTrainingTargetsState);
    whenListen<HomeState>(
      homeBloc,
      const Stream<HomeState>.empty(),
      initialState: noTrainingTargetsState,
    );

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.byKey(HomePage.muscleGroupsSectionKey), findsNothing);
  });

  testWidgets('nutrition empty state is shown when there are no logs', (
    WidgetTester tester,
  ) async {
    final HomeLoaded noLogsState = HomeLoaded(
      data: HomeDashboardData(
        targets: loadedHomeData.targets,
        weeklySets: loadedHomeData.weeklySets,
        todaysLogs: const <NutritionLog>[],
        dailyMacros: loadedHomeData.dailyMacros,
        exercises: loadedHomeData.exercises,
      ),
    );

    when(() => homeBloc.state).thenReturn(noLogsState);
    whenListen<HomeState>(
      homeBloc,
      const Stream<HomeState>.empty(),
      initialState: noLogsState,
    );

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.byKey(HomePage.nutritionEmptyStateKey), findsOneWidget);
    expect(find.byKey(HomePage.latestEntriesSectionKey), findsNothing);
  });
}