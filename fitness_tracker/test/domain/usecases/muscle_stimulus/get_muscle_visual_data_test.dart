import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/constants/muscle_stimulus_constants.dart'
    as stimulus_constants;
import 'package:fitness_tracker/domain/entities/muscle_stimulus.dart'
    as stimulus_entity;
import 'package:fitness_tracker/domain/entities/time_period.dart';
import 'package:fitness_tracker/domain/muscle_visual/muscle_visual_contract.dart';
import 'package:fitness_tracker/domain/repositories/muscle_stimulus_repository.dart';
import 'package:fitness_tracker/domain/usecases/muscle_stimulus/get_muscle_visual_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMuscleStimulusRepository extends Mock
    implements MuscleStimulusRepository {}

void main() {
  late MockMuscleStimulusRepository repository;
  late GetMuscleVisualData usecase;

  const String testUserId = 'user-1';

  setUp(() {
    repository = MockMuscleStimulusRepository();
    usecase = GetMuscleVisualData(repository);
  });

  test(
    'today visuals use daily stimulus instead of decayed last-set stimulus',
    () async {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final lastSetTimestamp = today
          .subtract(const Duration(hours: 6))
          .millisecondsSinceEpoch;

      for (final String muscleGroup
          in stimulus_constants.MuscleStimulus.allMuscleGroups) {
        if (muscleGroup == stimulus_constants.MuscleStimulus.quads) {
          when(
            () => repository.getStimulusByMuscleAndDate(
              userId: testUserId,
              muscleGroup: muscleGroup,
              date: todayStart,
            ),
          ).thenAnswer(
            (_) async => Right(
              stimulus_entity.MuscleStimulus(
                id: 'quads-today',
                ownerUserId: testUserId,
                muscleGroup: muscleGroup,
                date: todayStart,
                dailyStimulus: 8.0,
                rollingWeeklyLoad: 8.0,
                lastSetTimestamp: lastSetTimestamp,
                lastSetStimulus: 2.0,
                createdAt: todayStart,
                updatedAt: todayStart,
              ),
            ),
          );
        } else {
          when(
            () => repository.getStimulusByMuscleAndDate(
              userId: testUserId,
              muscleGroup: muscleGroup,
              date: todayStart,
            ),
          ).thenAnswer((_) async => const Right(null));
        }
      }

      final result = await usecase(TimePeriod.today, testUserId);
      final visualData = result.getOrElse(
        () => throw StateError('expected data'),
      );
      final quads = visualData[stimulus_constants.MuscleStimulus.quads]!;

      expect(quads.totalStimulus, 8.0);
      expect(quads.bucket, MuscleVisualBucket.maximum);
      expect(quads.coverageState, MuscleVisualCoverageState.full);
    },
  );

  test(
    'returns untrained data for all muscles when user has no stimulus records',
    () async {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      for (final String muscleGroup
          in stimulus_constants.MuscleStimulus.allMuscleGroups) {
        when(
          () => repository.getStimulusByMuscleAndDate(
            userId: testUserId,
            muscleGroup: muscleGroup,
            date: todayStart,
          ),
        ).thenAnswer((_) async => const Right(null));
      }

      final result = await usecase(TimePeriod.today, testUserId);
      final visualData = result.getOrElse(
        () => throw StateError('expected data'),
      );

      expect(
        visualData.values.every((data) => !data.hasTrained),
        isTrue,
        reason: 'a profile with no workouts should show no muscle activity',
      );
    },
  );

  test('userId is forwarded to every repository query', () async {
    const otherUserId = 'user-other';
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    // Stub for the other user: all muscles have stimulus
    for (final String muscleGroup
        in stimulus_constants.MuscleStimulus.allMuscleGroups) {
      when(
        () => repository.getStimulusByMuscleAndDate(
          userId: otherUserId,
          muscleGroup: muscleGroup,
          date: todayStart,
        ),
      ).thenAnswer(
        (_) async => Right(
          stimulus_entity.MuscleStimulus(
            id: '$muscleGroup-today',
            ownerUserId: otherUserId,
            muscleGroup: muscleGroup,
            date: todayStart,
            dailyStimulus: 5.0,
            rollingWeeklyLoad: 5.0,
            createdAt: todayStart,
            updatedAt: todayStart,
          ),
        ),
      );

      // Stub for testUserId: all muscles return null
      when(
        () => repository.getStimulusByMuscleAndDate(
          userId: testUserId,
          muscleGroup: muscleGroup,
          date: todayStart,
        ),
      ).thenAnswer((_) async => const Right(null));
    }

    final result = await usecase(TimePeriod.today, testUserId);
    final visualData = result.getOrElse(() => throw StateError(''));

    // testUserId has no data, so all muscles must be untrained
    expect(visualData.values.every((d) => !d.hasTrained), isTrue);

    // Verify no query was ever made with otherUserId
    verifyNever(
      () => repository.getStimulusByMuscleAndDate(
        userId: otherUserId,
        muscleGroup: any(named: 'muscleGroup'),
        date: any(named: 'date'),
      ),
    );
  });
}
