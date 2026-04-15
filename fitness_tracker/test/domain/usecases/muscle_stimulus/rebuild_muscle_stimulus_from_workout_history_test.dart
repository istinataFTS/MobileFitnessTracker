import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/constants/muscle_stimulus_constants.dart'
    as stimulus_constants;
import 'package:fitness_tracker/core/enums/data_source_preference.dart';
import 'package:fitness_tracker/domain/entities/muscle_factor.dart';
import 'package:fitness_tracker/domain/entities/muscle_stimulus.dart';
import 'package:fitness_tracker/domain/entities/workout_set.dart';
import 'package:fitness_tracker/domain/repositories/muscle_factor_repository.dart';
import 'package:fitness_tracker/domain/repositories/muscle_stimulus_repository.dart';
import 'package:fitness_tracker/domain/repositories/workout_set_repository.dart';
import 'package:fitness_tracker/domain/usecases/muscle_stimulus/calculate_muscle_stimulus.dart';
import 'package:fitness_tracker/domain/usecases/muscle_stimulus/rebuild_muscle_stimulus_from_workout_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutSetRepository extends Mock implements WorkoutSetRepository {}

class MockMuscleStimulusRepository extends Mock
    implements MuscleStimulusRepository {}

class MockMuscleFactorRepository extends Mock
    implements MuscleFactorRepository {}

void main() {
  late MockWorkoutSetRepository workoutSetRepository;
  late MockMuscleStimulusRepository muscleStimulusRepository;
  late MockMuscleFactorRepository muscleFactorRepository;
  late RebuildMuscleStimulusFromWorkoutHistory usecase;
  late List<MuscleStimulus> upsertedRecords;

  const String testUserId = 'user-1';

  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);
  final twoDaysAgo = todayStart.subtract(const Duration(days: 2));

  setUpAll(() {
    registerFallbackValue(
      MuscleStimulus(
        id: 'fallback',
        ownerUserId: testUserId,
        muscleGroup: stimulus_constants.MuscleStimulus.midChest,
        date: DateTime(2026, 1, 1),
        dailyStimulus: 0,
        rollingWeeklyLoad: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    workoutSetRepository = MockWorkoutSetRepository();
    muscleStimulusRepository = MockMuscleStimulusRepository();
    muscleFactorRepository = MockMuscleFactorRepository();
    upsertedRecords = <MuscleStimulus>[];

    usecase = RebuildMuscleStimulusFromWorkoutHistory(
      workoutSetRepository: workoutSetRepository,
      muscleStimulusRepository: muscleStimulusRepository,
      calculateMuscleStimulus: CalculateMuscleStimulus(
        muscleFactorRepository: muscleFactorRepository,
      ),
    );

    when(
      () => muscleStimulusRepository.clearStimulusForUser(testUserId),
    ).thenAnswer((_) async => const Right(null));

    when(() => muscleStimulusRepository.upsertStimulus(any())).thenAnswer((
      invocation,
    ) async {
      upsertedRecords.add(
        invocation.positionalArguments.first as MuscleStimulus,
      );
      return const Right(null);
    });

    when(
      () => workoutSetRepository.getAllSets(
        sourcePreference: DataSourcePreference.localOnly,
      ),
    ).thenAnswer(
      (_) async => Right(<WorkoutSet>[
        WorkoutSet(
          id: 'bench-1',
          exerciseId: 'bench',
          reps: 8,
          weight: 80,
          intensity: 4,
          date: todayStart.add(const Duration(hours: 9)),
          createdAt: todayStart.add(const Duration(hours: 9)),
        ),
        WorkoutSet(
          id: 'bench-2',
          exerciseId: 'bench',
          reps: 6,
          weight: 85,
          intensity: 5,
          date: todayStart.add(const Duration(hours: 9, minutes: 10)),
          createdAt: todayStart.add(const Duration(hours: 9, minutes: 10)),
        ),
        WorkoutSet(
          id: 'squat-1',
          exerciseId: 'squat',
          reps: 5,
          weight: 110,
          intensity: 5,
          date: twoDaysAgo.add(const Duration(hours: 18)),
          createdAt: twoDaysAgo.add(const Duration(hours: 18)),
        ),
      ]),
    );

    when(
      () => muscleFactorRepository.getFactorsForExercise('bench'),
    ).thenAnswer(
      (_) async => const Right(<MuscleFactor>[
        MuscleFactor(
          id: 'bench-chest',
          exerciseId: 'bench',
          muscleGroup: 'mid-chest',
          factor: 0.9,
        ),
        MuscleFactor(
          id: 'bench-triceps',
          exerciseId: 'bench',
          muscleGroup: 'triceps',
          factor: 0.55,
        ),
      ]),
    );

    when(
      () => muscleFactorRepository.getFactorsForExercise('squat'),
    ).thenAnswer(
      (_) async => const Right(<MuscleFactor>[
        MuscleFactor(
          id: 'squat-quads',
          exerciseId: 'squat',
          muscleGroup: 'quads',
          factor: 0.9,
        ),
      ]),
    );
  });

  test(
    'rebuild clears stale today muscles while preserving historic load',
    () async {
      final result = await usecase(testUserId);

      expect(result.isRight(), isTrue);
      // Must call the user-scoped clear, never the global clear
      verify(
        () => muscleStimulusRepository.clearStimulusForUser(testUserId),
      ).called(1);
      verifyNever(() => muscleStimulusRepository.clearAllStimulus());

      final todayQuads = upsertedRecords.firstWhere(
        (record) =>
            record.muscleGroup == stimulus_constants.MuscleStimulus.quads &&
            record.date == todayStart,
      );
      final todayChest = upsertedRecords.firstWhere(
        (record) =>
            record.muscleGroup == stimulus_constants.MuscleStimulus.midChest &&
            record.date == todayStart,
      );

      expect(todayQuads.dailyStimulus, 0);
      expect(todayQuads.rollingWeeklyLoad, greaterThan(0));
      expect(todayChest.dailyStimulus, greaterThan(0));
    },
  );

  test('rebuilt records are stamped with the provided userId', () async {
    await usecase(testUserId);

    expect(
      upsertedRecords.every((r) => r.ownerUserId == testUserId),
      isTrue,
      reason: 'every rebuilt record must carry the correct ownerUserId',
    );
  });

  test('does not touch clearStimulusForUser for a different userId', () async {
    const otherUserId = 'user-other';
    when(
      () => muscleStimulusRepository.clearStimulusForUser(otherUserId),
    ).thenAnswer((_) async => const Right(null));

    await usecase(testUserId);

    verifyNever(
      () => muscleStimulusRepository.clearStimulusForUser(otherUserId),
    );
  });
}
