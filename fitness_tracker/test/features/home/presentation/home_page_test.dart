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
import 'package:fitness_tracker/features/home/application/muscle_visual_bloc.dart';
import 'package:fitness_tracker/features/home/presentation/home_page.dart';
import 'package:fitness_tracker/presentation/settings/bloc/app_settings_cubit.dart';
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

  final MuscleVisualLoaded loadedMuscleState = MuscleVisualLoaded(
    muscleData: <String, MuscleVisualData>{
      'chest': MuscleVisualData(
        muscleGroup: 'chest',
        totalStimulus: 6,
        threshold: 6,
        visualIntensity: 1.0,
        bucket: MuscleVisualBucket.maximum,
        coverageState: MuscleVisualCoverageState.full,
        aggregationMode: MuscleVisualAggregationMode.cumulative,
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
        BlocProvider<AppSettingsCubit>.value(value: appSettingsCubit),
        BlocProvider<HomeBloc>.value(value: homeBloc),
        BlocProvider<MuscleVisualBloc>.value(value: muscleVisualBloc),
      ],
      child: const MaterialApp(
        home: HomePage(),
      ),
    );
  }

  testWidgets('shows loading indicator for HomeInitial', (
    WidgetTester tester,
  ) async {
    when(() => homeBloc.state).thenReturn(const HomeInitial());
    whenListen<HomeState>(
      homeBloc,
      const Stream<HomeState>.empty(),
      initialState: const HomeInitial(),
    );

    await tester.pumpWidget(buildSubject());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows loading indicator for HomeLoading', (
    WidgetTester tester,
  ) async {
    when(() => homeBloc.state).thenReturn(const HomeLoading());
    whenListen<HomeState>(
      homeBloc,
      const Stream<HomeState>.empty(),
      initialState: const HomeLoading(),
    );

    await tester.pumpWidget(buildSubject());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error state and retry dispatches LoadHomeDataEvent', (
    WidgetTester tester,
  ) async {
    when(() => homeBloc.state).thenReturn(const HomeError('load failed'));
    whenListen<HomeState>(
      homeBloc,
      const Stream<HomeState>.empty(),
      initialState: const HomeError('load failed'),
    );

    await tester.pumpWidget(buildSubject());

    expect(find.text('load failed'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    verify(() => homeBloc.add(const LoadHomeDataEvent())).called(1);
  });

  testWidgets('renders loaded home content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.textContaining('Hello'), findsOneWidget);
    expect(find.text('Today’s Nutrition'), findsOneWidget);
    expect(find.textContaining('Progress'), findsOneWidget);
    expect(find.text('Chicken and Rice'), findsOneWidget);
    expect(find.text('Muscle Groups'), findsOneWidget);
  });

  testWidgets('shows current period in selector', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Week'), findsWidgets);
  });

  testWidgets('changing period dispatches ChangePeriodEvent', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.text('Week').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Month').last);
    await tester.pumpAndSettle();

    verify(
      () => muscleVisualBloc.add(ChangePeriodEvent(TimePeriod.month)),
    ).called(1);
  });

  testWidgets(
    'loaded home with visual error shows retry action for visuals',
    (WidgetTester tester) async {
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
    },
  );

  testWidgets('pull to refresh dispatches both refresh events', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    final Finder listView = find.byType(ListView);
    expect(listView, findsOneWidget);

    await tester.drag(listView, const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(() => homeBloc.add(const RefreshHomeDataEvent())).called(1);
    verify(() => muscleVisualBloc.add(const RefreshVisualsEvent())).called(1);
  });

  testWidgets('hides muscle group section when there are no training targets', (
    WidgetTester tester,
  ) async {
    final HomeLoaded noTrainingTargetsState = HomeLoaded(
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
    );

    when(() => homeBloc.state).thenReturn(noTrainingTargetsState);
    whenListen<HomeState>(
      homeBloc,
      const Stream<HomeState>.empty(),
      initialState: noTrainingTargetsState,
    );

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Muscle Groups'), findsNothing);
  });
}