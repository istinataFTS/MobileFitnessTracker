import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../config/env_config.dart';
import '../../../core/constants/muscle_stimulus_constants.dart';
import '../../../core/errors/failures.dart';
import '../../entities/muscle_stimulus.dart';
import '../../repositories/muscle_factor_repository.dart';
import '../../repositories/muscle_stimulus_repository.dart';
import 'calculate_muscle_stimulus.dart';

/// Use case for recording a workout set and updating muscle stimulus.
class RecordWorkoutSet {
  final MuscleFactorRepository muscleFactorRepository;
  final MuscleStimulusRepository muscleStimulusRepository;
  final CalculateMuscleStimulus calculateMuscleStimulus;
  final _uuid = const Uuid();

  const RecordWorkoutSet({
    required this.muscleFactorRepository,
    required this.muscleStimulusRepository,
    required this.calculateMuscleStimulus,
  });

  Future<Either<Failure, List<String>>> call({
    required String exerciseId,
    required int sets,
    required int intensity,
    DateTime? timestamp,
  }) async {
    try {
      final setTimestamp = timestamp ?? DateTime.now();
      final now = DateTime.now();

      final stimulusResult = await calculateMuscleStimulus.calculateForSet(
        exerciseId: exerciseId,
        sets: sets,
        intensity: intensity,
      );

      return await stimulusResult.fold(
        (failure) async => Left(failure),
        (muscleStimuli) async {
          if (muscleStimuli.isEmpty) {
            return const Right([]);
          }

          final shouldApplyDecay = await _shouldApplyDailyDecay(setTimestamp);
          if (shouldApplyDecay) {
            await _applyDailyDecay();
          }

          final affectedMuscles = <String>[];

          for (final entry in muscleStimuli.entries) {
            final muscleGroup = entry.key;
            final setStimulus = entry.value;

            final updateResult = await _updateMuscleStimulus(
              muscleGroup: muscleGroup,
              setStimulus: setStimulus,
              setTimestamp: setTimestamp.millisecondsSinceEpoch,
              now: now,
            );

            updateResult.fold(
              (failure) {
                if (EnvConfig.enableDebugLogs) {
                  print(
                    'Failed to update stimulus for $muscleGroup: ${failure.message}',
                  );
                }
              },
              (_) {
                affectedMuscles.add(muscleGroup);
              },
            );
          }

          return Right(affectedMuscles);
        },
      );
    } catch (e) {
      return Left(UnexpectedFailure('Failed to record workout set: $e'));
    }
  }

  Future<Either<Failure, void>> _updateMuscleStimulus({
    required String muscleGroup,
    required double setStimulus,
    required int setTimestamp,
    required DateTime now,
  }) async {
    try {
      final today = DateTime(now.year, now.month, now.day);

      final existingResult =
          await muscleStimulusRepository.getStimulusByMuscleAndDate(
        muscleGroup: muscleGroup,
        date: today,
      );

      return await existingResult.fold(
        (failure) async => Left(failure),
        (existingStimulus) async {
          if (existingStimulus == null) {
            return await _createNewStimulusRecord(
              muscleGroup: muscleGroup,
              setStimulus: setStimulus,
              setTimestamp: setTimestamp,
              date: today,
            );
          } else {
            return await _updateExistingStimulusRecord(
              existing: existingStimulus,
              setStimulus: setStimulus,
              setTimestamp: setTimestamp,
            );
          }
        },
      );
    } catch (e) {
      return Left(UnexpectedFailure('Failed to update muscle stimulus: $e'));
    }
  }

  Future<Either<Failure, void>> _createNewStimulusRecord({
    required String muscleGroup,
    required double setStimulus,
    required int setTimestamp,
    required DateTime date,
  }) async {
    try {
      final yesterday = date.subtract(const Duration(days: 1));
      final yesterdayResult =
          await muscleStimulusRepository.getStimulusByMuscleAndDate(
        muscleGroup: muscleGroup,
        date: yesterday,
      );

      double previousWeeklyLoad = 0.0;
      yesterdayResult.fold(
        (_) {},
        (yesterdayStimulus) {
          if (yesterdayStimulus != null) {
            previousWeeklyLoad = yesterdayStimulus.rollingWeeklyLoad;
          }
        },
      );

      final newWeeklyLoad =
          (previousWeeklyLoad * MuscleStimulusConstants.weeklyDecayFactor) +
              setStimulus;

      final stimulus = MuscleStimulus(
        id: _uuid.v4(),
        muscleGroup: muscleGroup,
        date: date,
        dailyStimulus: setStimulus,
        rollingWeeklyLoad: newWeeklyLoad,
        lastSetTimestamp: setTimestamp,
        lastSetStimulus: setStimulus,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await muscleStimulusRepository.upsertStimulus(stimulus);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to create stimulus record: $e'));
    }
  }

  Future<Either<Failure, void>> _updateExistingStimulusRecord({
    required MuscleStimulus existing,
    required double setStimulus,
    required int setTimestamp,
  }) async {
    try {
      final newDailyStimulus = existing.dailyStimulus + setStimulus;
      final newWeeklyLoad = existing.rollingWeeklyLoad + setStimulus;

      return await muscleStimulusRepository.updateStimulusValues(
        id: existing.id,
        dailyStimulus: newDailyStimulus,
        rollingWeeklyLoad: newWeeklyLoad,
        lastSetTimestamp: setTimestamp,
        lastSetStimulus: setStimulus,
      );
    } catch (e) {
      return Left(UnexpectedFailure('Failed to update stimulus record: $e'));
    }
  }

  Future<bool> _shouldApplyDailyDecay(DateTime setTimestamp) async {
    try {
      final today = DateTime(
        setTimestamp.year,
        setTimestamp.month,
        setTimestamp.day,
      );

      final todayResult =
          await muscleStimulusRepository.getAllStimulusForDate(today);

      return todayResult.fold(
        (_) => false,
        (todayRecords) => todayRecords.isEmpty,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> _applyDailyDecay() async {
    try {
      await muscleStimulusRepository.applyDailyDecayToAll();

      if (EnvConfig.enableDebugLogs) {
        print('[STIMULUS] Applied daily decay to all muscle groups');
      }
    } catch (e) {
      if (EnvConfig.enableDebugLogs) {
        print('[STIMULUS] Failed to apply daily decay: $e');
      }
    }
  }

  bool validateInputs({
    required String exerciseId,
    required int sets,
    required int intensity,
  }) {
    return calculateMuscleStimulus.validateInputs(
      exerciseId: exerciseId,
      sets: sets,
      intensity: intensity,
    );
  }
}