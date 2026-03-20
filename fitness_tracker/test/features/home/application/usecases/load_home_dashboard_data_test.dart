import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
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
import 'package:fitness_tracker/features/home/application/models/home_dashboard_data.dart';
import 'package:fitness_tracker/features/home/application/usecases/load_home_dashboard_data.dart';
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

  late LoadHomeDashboardData usecase;

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

    usecase = LoadHomeDashboardData(
      getAllTargets: mockGetAllTargets,
      getWeeklySets: mockGetWeeklySets,
      getLogsForDate: mockGetLogsForDate,
      getDailyMacros: mockGetDailyMacros,
      getAllExercises: mockGetAllExercises,
    );
  });

  void stubSuccessfulCoreLoads() {
    when(() => mockGetAllTargets()).thenAnswer((_) async => Right(targets));
    when(() => mockGetWeeklySets()).thenAnswer((_) async => Right(weeklySets));
    when(() => mockGetAllExercises()).thenAnswer((_) async => Right(exercises));
  }

  test('returns aggregated dashboard data when all core loads succeed', () async {
    stubSuccessfulCoreLoads();

    when(() => mockGetLogsForDate(any())).thenAnswer(
      (_) async => Right(<NutritionLog>[olderLog, newerLog]),
    );
    when(() => mockGetDailyMacros(any())).thenAnswer(
      (_) async => Right(dailyMacros),
    );

    final result = await usecase();

    expect(
      result,
      Right<Failure, HomeDashboardData>(
        HomeDashboardData(
          targets: targets,
          weeklySets: weeklySets,
          todaysLogs: <NutritionLog>[newerLog, olderLog],
          dailyMacros: dailyMacros,
          exercises: exercises,
        ),
      ),
    );
  });

  test('returns failure when targets loading fails', () async {
    when(() => mockGetAllTargets()).thenAnswer(
      (_) async => const Left(CacheFailure('targets failed')),
    );

    final result = await usecase();

    expect(result, const Left<Failure, HomeDashboardData>(CacheFailure('targets failed')));
  });

  test('returns failure when weekly sets loading fails', () async {
    when(() => mockGetAllTargets()).thenAnswer((_) async => Right(targets));
    when(() => mockGetWeeklySets()).thenAnswer(
      (_) async => const Left(CacheFailure('weekly sets failed')),
    );

    final result = await usecase();

    expect(
      result,
      const Left<Failure, HomeDashboardData>(CacheFailure('weekly sets failed')),
    );
  });

  test('returns failure when exercises loading fails', () async {
    when(() => mockGetAllTargets()).thenAnswer((_) async => Right(targets));
    when(() => mockGetWeeklySets()).thenAnswer((_) async => Right(weeklySets));
    when(() => mockGetAllExercises()).thenAnswer(
      (_) async => const Left(CacheFailure('exercises failed')),
    );

    final result = await usecase();

    expect(
      result,
      const Left<Failure, HomeDashboardData>(CacheFailure('exercises failed')),
    );
  });

  test('falls back to empty logs when logs loading fails', () async {
    stubSuccessfulCoreLoads();

    when(() => mockGetLogsForDate(any())).thenAnswer(
      (_) async => const Left(CacheFailure('logs failed')),
    );
    when(() => mockGetDailyMacros(any())).thenAnswer(
      (_) async => Right(dailyMacros),
    );

    final result = await usecase();

    expect(
      result,
      Right<Failure, HomeDashboardData>(
        HomeDashboardData(
          targets: targets,
          weeklySets: weeklySets,
          todaysLogs: const <NutritionLog>[],
          dailyMacros: dailyMacros,
          exercises: exercises,
        ),
      ),
    );
  });

  test('falls back to empty daily macros when macros loading fails', () async {
    stubSuccessfulCoreLoads();

    when(() => mockGetLogsForDate(any())).thenAnswer(
      (_) async => Right(<NutritionLog>[newerLog]),
    );
    when(() => mockGetDailyMacros(any())).thenAnswer(
      (_) async => const Left(CacheFailure('macros failed')),
    );

    final result = await usecase();

    expect(
      result,
      Right<Failure, HomeDashboardData>(
        HomeDashboardData(
          targets: targets,
          weeklySets: weeklySets,
          todaysLogs: <NutritionLog>[newerLog],
          dailyMacros: HomeDashboardData.emptyDailyMacros,
          exercises: exercises,
        ),
      ),
    );
  });
}