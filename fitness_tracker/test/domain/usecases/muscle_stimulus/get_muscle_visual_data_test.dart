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

  test(
    'week view classifies a week-old moderate load as recovered — '
    'regression guard for the Lats-are-always-fatigued bug at the use-case level',
    () async {
      // This is the cross-layer counterpart to the NormalizedMuscleLoad unit
      // test: it verifies the fix survives inside GetMuscleVisualData's
      // _buildWeekDataWithoutToday codepath, where the bug originally lived.
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final yesterday = todayStart.subtract(const Duration(days: 1));
      final lookbackStart = todayStart.subtract(const Duration(days: 30));
      final staleRecordDate = todayStart.subtract(const Duration(days: 7));

      // Today: no stimulus records for any muscle — forces every muscle
      // through _buildWeekDataWithoutToday.
      for (final String muscleGroup
          in stimulus_constants.MuscleStimulus.allMuscleGroups) {
        when(
          () => repository.getStimulusByMuscleAndDate(
            userId: testUserId,
            muscleGroup: muscleGroup,
            date: todayStart,
          ),
        ).thenAnswer((_) async => const Right(null));

        // Past 30 days: lats has a 7-day-old moderate load (raw=20,
        // threshold=25).  After `0.6^7 ≈ 0.028` decay the normalized load
        // sits at ~0.022, well below the 0.5 recovery cutoff, so the map
        // must render lats as untrained.  A raw-vs-normalized regression
        // would compare the ~0.56 raw decayed value against 0.5 and
        // incorrectly leave lats fatigued.
        if (muscleGroup == stimulus_constants.MuscleStimulus.lats) {
          when(
            () => repository.getStimulusByDateRange(
              userId: testUserId,
              muscleGroup: muscleGroup,
              startDate: lookbackStart,
              endDate: yesterday,
            ),
          ).thenAnswer(
            (_) async => Right(<stimulus_entity.MuscleStimulus>[
              stimulus_entity.MuscleStimulus(
                id: 'lats-stale',
                ownerUserId: testUserId,
                muscleGroup: muscleGroup,
                date: staleRecordDate,
                dailyStimulus: 0,
                rollingWeeklyLoad: 20.0,
                createdAt: staleRecordDate,
                updatedAt: staleRecordDate,
              ),
            ]),
          );
        } else {
          when(
            () => repository.getStimulusByDateRange(
              userId: testUserId,
              muscleGroup: muscleGroup,
              startDate: lookbackStart,
              endDate: yesterday,
            ),
          ).thenAnswer(
            (_) async => const Right(<stimulus_entity.MuscleStimulus>[]),
          );
        }
      }

      final result = await usecase(TimePeriod.week, testUserId);
      final visualData = result.getOrElse(
        () => throw StateError('expected data'),
      );
      final lats = visualData[stimulus_constants.MuscleStimulus.lats]!;

      expect(
        lats.hasTrained,
        isFalse,
        reason:
            'a 7-day-old moderate load must decay below the recovery cutoff; '
            'a unit-mismatch regression would leave lats permanently fatigued',
      );
    },
  );

  test(
    'week view classifies a stale today-row whose rolling load has decayed '
    'below the recovery cutoff as untrained — guards the today-branch path',
    () async {
      // The original bug: when the rebuild propagates a row forward to today
      // for every day in the workout history, _getWeekVisualData's today
      // branch returned `rollingWeeklyLoad` raw and asked the contract to
      // classify it. The contract treats any positive stimulus as
      // `hasTrained`, so a fully-decayed muscle still painted on the body
      // map. This test pins the today-branch through the same isRecovered
      // check the without-today branch already used.
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      for (final String muscleGroup
          in stimulus_constants.MuscleStimulus.allMuscleGroups) {
        if (muscleGroup == stimulus_constants.MuscleStimulus.lats) {
          when(
            () => repository.getStimulusByMuscleAndDate(
              userId: testUserId,
              muscleGroup: muscleGroup,
              date: todayStart,
            ),
          ).thenAnswer(
            (_) async => Right(
              stimulus_entity.MuscleStimulus(
                id: 'lats-today-decayed',
                ownerUserId: testUserId,
                muscleGroup: muscleGroup,
                date: todayStart,
                dailyStimulus: 0.0,
                // Below 0.5 * weeklyThreshold (12.5) → already recovered.
                rollingWeeklyLoad: 1.0,
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
          when(
            () => repository.getStimulusByDateRange(
              userId: testUserId,
              muscleGroup: muscleGroup,
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            ),
          ).thenAnswer(
            (_) async => const Right(<stimulus_entity.MuscleStimulus>[]),
          );
        }
      }

      final result = await usecase(TimePeriod.week, testUserId);
      final visualData = result.getOrElse(
        () => throw StateError('expected data'),
      );

      expect(
        visualData[stimulus_constants.MuscleStimulus.lats]!.hasTrained,
        isFalse,
        reason:
            'a today-row with a fully-decayed rolling load must render as '
            'untrained, otherwise muscles stay coloured forever once a row '
            'has been propagated to today by the rebuild',
      );
    },
  );

  test(
    'week view applies decay to a stale-dated today-branch row using '
    'days-since-the-row-date',
    () async {
      // If a stimulus row is dated several days in the past (e.g. the rebuild
      // never ran or a future regression stops propagating rows forward),
      // the today-branch must still age the load by `today - row.date` and
      // hand off to isRecovered. With raw=20 and 5 days of decay
      // (0.6^5 ≈ 0.0778) the normalized load drops to ~0.062 — well under
      // the 0.5 cutoff.
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final fiveDaysAgo = todayStart.subtract(const Duration(days: 5));

      for (final String muscleGroup
          in stimulus_constants.MuscleStimulus.allMuscleGroups) {
        if (muscleGroup == stimulus_constants.MuscleStimulus.midChest) {
          when(
            () => repository.getStimulusByMuscleAndDate(
              userId: testUserId,
              muscleGroup: muscleGroup,
              date: todayStart,
            ),
          ).thenAnswer(
            (_) async => Right(
              stimulus_entity.MuscleStimulus(
                id: 'chest-stale-today',
                ownerUserId: testUserId,
                muscleGroup: muscleGroup,
                date: fiveDaysAgo,
                dailyStimulus: 0.0,
                rollingWeeklyLoad: 20.0,
                createdAt: fiveDaysAgo,
                updatedAt: fiveDaysAgo,
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
          when(
            () => repository.getStimulusByDateRange(
              userId: testUserId,
              muscleGroup: muscleGroup,
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            ),
          ).thenAnswer(
            (_) async => const Right(<stimulus_entity.MuscleStimulus>[]),
          );
        }
      }

      final result = await usecase(TimePeriod.week, testUserId);
      final visualData = result.getOrElse(
        () => throw StateError('expected data'),
      );

      expect(
        visualData[stimulus_constants.MuscleStimulus.midChest]!.hasTrained,
        isFalse,
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
