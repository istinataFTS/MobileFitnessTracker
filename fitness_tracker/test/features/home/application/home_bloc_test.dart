import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/error/failures.dart';
import 'package:fitness_tracker/domain/entities/entity_sync_metadata.dart';
import 'package:fitness_tracker/domain/entities/exercise.dart';
import 'package:fitness_tracker/domain/entities/nutrition_log.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:fitness_tracker/domain/entities/workout_set.dart';
import 'package:fitness_tracker/domain/usecases/exercises/get_all_exercises.dart';
import 'package:fitness_tracker/domain/usecases/nutrition_logs/get_daily_macros.dart';
import 'package:fitness_tracker/domain/usecases/nutrition_logs/get_logs_for_date.dart';
import 'package:fitness_tracker/domain/usecases/targets/get_all_targets.dart';
import 'package:fitness_tracker/domain/usecases/workout_sets/get_weekly_sets.dart';
import 'package:fitness_tracker/features/home/application/home_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAllTargets extends Mock implements GetAllTargets {}

class MockGetWeeklySets extends Mock implements GetWeeklySets {}

class MockGetLogsForDate extends Mock implements GetLogsForDate {}

class MockGetDailyMacros extends Mock implements GetDailyMacros {}

class MockGetAllExercises extends Mock implements GetAllExercises {}

void main() {
  late MockGetAllTargets mockGetAllTargets;
  late MockGetWeeklySets mockGetWeeklySets;
  late MockGetLogsForDate mockGetLogsForDate;
  late MockGetDailyMacros mockGetDailyMacros;
  late MockGetAllExercises mockGetAllExercises;

  late HomeBloc bloc;

  final DateTime now = DateTime(2026, 3, 19, 10, 0);

  final List<Target> targets = <Target>[
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
  ];

  final List<WorkoutSet> weeklySets = <WorkoutSet>[
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
    WorkoutSet(
      id: 'set-2',
      exerciseId: 'bench-press',
      reps: 10,
      weight: 75,
      intensity: 7,
      date: now.subtract(const Duration(days: 1)),
      createdAt: now.subtract(const Duration(days: 1)),
      syncMetadata: const EntitySyncMetadata(),
    ),
  ];

  final List<Exercise> exercises = <Exercise>[
    Exercise(
      id: 'bench-press',
      name: 'Bench Press',
      muscleGroups: <String>['chest'],
      createdAt: now,
      syncMetadata: const EntitySyncMetadata(),
    ),
  ];

  final NutritionLog olderLog = NutritionLog(
    id: 'log-older',
    mealName: 'Oats',
    proteinGrams: 20,
    carbsGrams: 40,
    fatGrams: 8,
    calories: 312,
    loggedAt: now.subtract(const Duration(hours: 4)),
    createdAt: now.subtract(const Duration(hours: 4)),
    syncMetadata: const EntitySyncMetadata(),
  );

  final NutritionLog newerLog = NutritionLog(
    id: 'log-newer',
    mealName: 'Chicken and Rice',
    proteinGrams: 45,
    carbsGrams: 60,
    fatGrams: 12,
    calories: 528,
    loggedAt: now.subtract(const Duration(hours: 1)),
    createdAt: now.subtract(const Duration(hours: 1)),
    syncMetadata: const EntitySyncMetadata(),
  );

  final Map<String, double> dailyMacros = <String, double>{
    'protein': 120,
    'carbs': 140,
    'fats': 40,
    'calories': 1600,
  };

  setUp(() {
    mockGetAllTargets = MockGetAllTargets();
    mockGetWeeklySets = MockGetWeeklySets();
    mockGetLogsForDate = MockGetLogsForDate();
    mockGetDailyMacros = MockGetDailyMacros();
    mockGetAllExercises = MockGetAllExercises();

    bloc = HomeBloc(
      getAllTargets: mockGetAllTargets,
      getWeeklySets: mockGetWeeklySets,
      getLogsForDate: mockGetLogsForDate,
      getDailyMacros: mockGetDailyMacros,
      getAllExercises: mockGetAllExercises,
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  void stubSuccessfulLoad({
    List<NutritionLog>? logs,
    Map<String, double>? macros,
  }) {
    when(() => mockGetAllTargets()).thenAnswer((_) async => Right(targets));
    when(() => mockGetWeeklySets()).thenAnswer((_) async => Right(weeklySets));
    when(() => mockGetAllExercises()).thenAnswer((_) async => Right(exercises));
    when(() => mockGetLogsForDate(any())).thenAnswer(
      (_) async => Right(logs ?? <NutritionLog>[olderLog, newerLog]),
    );
    when(() => mockGetDailyMacros(any())).thenAnswer(
      (_) async => Right(macros ?? dailyMacros),
    );
  }

  test('initial state is HomeInitial', () {
    expect(bloc.state, const HomeInitial());
  });

  blocTest<HomeBloc, HomeState>(
    'emits [HomeLoading, HomeLoaded] when load succeeds',
    build: () {
      stubSuccessfulLoad();
      return bloc;
    },
    act: (HomeBloc bloc) => bloc.add(const LoadHomeDataEvent()),
    expect: () => <Matcher>[
      const TypeMatcher<HomeLoading>(),
      isA<HomeLoaded>()
          .having((HomeLoaded state) => state.targets, 'targets', targets)
          .having(
            (HomeLoaded state) => state.weeklySets,
            'weeklySets',
            weeklySets,
          )
          .having(
            (HomeLoaded state) => state.exercises,
            'exercises',
            exercises,
          )
          .having(
            (HomeLoaded state) => state.dailyMacros,
            'dailyMacros',
            dailyMacros,
          ),
    ],
  );

  blocTest<HomeBloc, HomeState>(
    'sorts todays logs by createdAt descending before emitting HomeLoaded',
    build: () {
      stubSuccessfulLoad(
        logs: <NutritionLog>[olderLog, newerLog],
      );
      return bloc;
    },
    act: (HomeBloc bloc) => bloc.add(const LoadHomeDataEvent()),
    verify: (HomeBloc bloc) {
      final HomeLoaded state = bloc.state as HomeLoaded;
      expect(state.todaysLogs, <NutritionLog>[newerLog, olderLog]);
    },
  );

  blocTest<HomeBloc, HomeState>(
    'emits HomeError when targets loading fails',
    build: () {
      when(() => mockGetAllTargets()).thenAnswer(
        (_) async => const Left(CacheFailure('targets failed')),
      );
      return bloc;
    },
    act: (HomeBloc bloc) => bloc.add(const LoadHomeDataEvent()),
    expect: () => <Matcher>[
      const TypeMatcher<HomeLoading>(),
      isA<HomeError>().having(
        (HomeError state) => state.message,
        'message',
        'targets failed',
      ),
    ],
  );

  blocTest<HomeBloc, HomeState>(
    'emits HomeError when weekly sets loading fails',
    build: () {
      when(() => mockGetAllTargets()).thenAnswer((_) async => Right(targets));
      when(() => mockGetWeeklySets()).thenAnswer(
        (_) async => const Left(CacheFailure('weekly sets failed')),
      );
      return bloc;
    },
    act: (HomeBloc bloc) => bloc.add(const LoadHomeDataEvent()),
    expect: () => <Matcher>[
      const TypeMatcher<HomeLoading>(),
      isA<HomeError>().having(
        (HomeError state) => state.message,
        'message',
        'weekly sets failed',
      ),
    ],
  );

  blocTest<HomeBloc, HomeState>(
    'emits HomeError when exercises loading fails',
    build: () {
      when(() => mockGetAllTargets()).thenAnswer((_) async => Right(targets));
      when(() => mockGetWeeklySets()).thenAnswer((_) async => Right(weeklySets));
      when(() => mockGetAllExercises()).thenAnswer(
        (_) async => const Left(CacheFailure('exercises failed')),
      );
      return bloc;
    },
    act: (HomeBloc bloc) => bloc.add(const LoadHomeDataEvent()),
    expect: () => <Matcher>[
      const TypeMatcher<HomeLoading>(),
      isA<HomeError>().having(
        (HomeError state) => state.message,
        'message',
        'exercises failed',
      ),
    ],
  );

  blocTest<HomeBloc, HomeState>(
    'falls back to empty daily macros when getDailyMacros fails',
    build: () {
      stubSuccessfulLoad();
      when(() => mockGetDailyMacros(any())).thenAnswer(
        (_) async => const Left(CacheFailure('macros failed')),
      );
      return bloc;
    },
    act: (HomeBloc bloc) => bloc.add(const LoadHomeDataEvent()),
    verify: (HomeBloc bloc) {
      final HomeLoaded state = bloc.state as HomeLoaded;
      expect(
        state.dailyMacros,
        const <String, double>{
          'protein': 0.0,
          'carbs': 0.0,
          'fats': 0.0,
          'calories': 0.0,
        },
      );
    },
  );

  blocTest<HomeBloc, HomeState>(
    'refresh preserves current HomeLoaded state when a later load step fails',
    build: () {
      stubSuccessfulLoad();
      return bloc;
    },
    seed: () => HomeLoaded(
      targets: targets,
      weeklySets: weeklySets,
      todaysLogs: <NutritionLog>[newerLog],
      dailyMacros: dailyMacros,
      exercises: exercises,
    ),
    act: (HomeBloc bloc) {
      when(() => mockGetAllTargets()).thenAnswer((_) async => Right(targets));
      when(() => mockGetWeeklySets()).thenAnswer(
        (_) async => const Left(CacheFailure('refresh failed')),
      );
      bloc.add(const RefreshHomeDataEvent());
    },
    expect: () => <Matcher>[
      HomeLoaded(
        targets: targets,
        weeklySets: weeklySets,
        todaysLogs: <NutritionLog>[newerLog],
        dailyMacros: dailyMacros,
        exercises: exercises,
      ),
    ],
  );
}