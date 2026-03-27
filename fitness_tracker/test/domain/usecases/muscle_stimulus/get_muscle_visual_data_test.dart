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
              muscleGroup: muscleGroup,
              date: todayStart,
            ),
          ).thenAnswer(
            (_) async => Right(
              stimulus_entity.MuscleStimulus(
                id: 'quads-today',
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
              muscleGroup: muscleGroup,
              date: todayStart,
            ),
          ).thenAnswer((_) async => const Right(null));
        }
      }

      final result = await usecase(TimePeriod.today);
      final visualData = result.getOrElse(
        () => throw StateError('expected data'),
      );
      final quads = visualData[stimulus_constants.MuscleStimulus.quads]!;

      expect(quads.totalStimulus, 8.0);
      expect(quads.bucket, MuscleVisualBucket.maximum);
      expect(quads.coverageState, MuscleVisualCoverageState.full);
    },
  );
}
