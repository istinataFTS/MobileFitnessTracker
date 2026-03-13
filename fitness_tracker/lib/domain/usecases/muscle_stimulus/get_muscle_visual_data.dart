import 'package:dartz/dartz.dart';

import '../../../core/constants/muscle_stimulus_constants.dart';
import '../../../core/errors/failures.dart';
import '../../entities/muscle_visual_data.dart';
import '../../entities/stimulus_calculation_rules.dart';
import '../../entities/time_period.dart';
import '../../repositories/muscle_stimulus_repository.dart';

class GetMuscleVisualData {
  final MuscleStimulusRepository muscleStimulusRepository;

  const GetMuscleVisualData(this.muscleStimulusRepository);

  Future<Either<Failure, Map<String, MuscleVisualData>>> call(
    TimePeriod period,
  ) async {
    try {
      switch (period) {
        case TimePeriod.today:
          return _getTodayVisualData();
        case TimePeriod.week:
          return _getWeekVisualData();
        case TimePeriod.month:
          return _getMonthVisualData();
        case TimePeriod.allTime:
          return _getAllTimeVisualData();
      }
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get visual data: $e'));
    }
  }

  Future<Either<Failure, Map<String, MuscleVisualData>>>
      _getTodayVisualData() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final visualData = <String, MuscleVisualData>{};

      for (final muscleGroup in MuscleStimulus.allMuscleGroups) {
        final stimulusResult =
            await muscleStimulusRepository.getStimulusByMuscleAndDate(
          muscleGroup: muscleGroup,
          date: todayStart,
        );

        visualData[muscleGroup] = stimulusResult.fold(
          (_) => MuscleVisualData.untrained(muscleGroup),
          (stimulus) {
            if (stimulus == null) {
              return MuscleVisualData.untrained(muscleGroup);
            }

            final remainingStimulus = stimulus.calculateRemainingStimulus();

            return _buildVisualData(
              muscleGroup: muscleGroup,
              stimulus: remainingStimulus,
              threshold: MuscleStimulus.dailyThreshold,
            );
          },
        );
      }

      return Right(visualData);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get today visual data: $e'));
    }
  }

  Future<Either<Failure, Map<String, MuscleVisualData>>>
      _getWeekVisualData() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final visualData = <String, MuscleVisualData>{};

      for (final muscleGroup in MuscleStimulus.allMuscleGroups) {
        final stimulusResult =
            await muscleStimulusRepository.getStimulusByMuscleAndDate(
          muscleGroup: muscleGroup,
          date: todayStart,
        );

        if (stimulusResult.isLeft()) {
          visualData[muscleGroup] = MuscleVisualData.untrained(muscleGroup);
          continue;
        }

        final stimulus = stimulusResult.getOrElse(() => throw StateError(''));

        if (stimulus == null) {
          visualData[muscleGroup] = await _buildWeekDataWithoutToday(
            muscleGroup: muscleGroup,
            todayStart: todayStart,
          );
          continue;
        }

        visualData[muscleGroup] = _buildVisualData(
          muscleGroup: muscleGroup,
          stimulus: stimulus.rollingWeeklyLoad,
          threshold: MuscleStimulus.weeklyThreshold,
        );
      }

      return Right(visualData);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get week visual data: $e'));
    }
  }

  Future<Either<Failure, Map<String, MuscleVisualData>>>
      _getMonthVisualData() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final monthAgo = todayStart.subtract(const Duration(days: 30));

      final visualData = <String, MuscleVisualData>{};

      for (final muscleGroup in MuscleStimulus.allMuscleGroups) {
        final stimulusResult =
            await muscleStimulusRepository.getStimulusByDateRange(
          muscleGroup: muscleGroup,
          startDate: monthAgo,
          endDate: todayStart,
        );

        visualData[muscleGroup] = stimulusResult.fold(
          (_) => MuscleVisualData.untrained(muscleGroup),
          (stimulusList) {
            final monthlyStimulus = stimulusList.fold<double>(
              0.0,
              (sum, stimulus) => sum + stimulus.dailyStimulus,
            );

            return _buildVisualData(
              muscleGroup: muscleGroup,
              stimulus: monthlyStimulus,
              threshold: MuscleStimulus.monthlyThreshold,
            );
          },
        );
      }

      return Right(visualData);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get month visual data: $e'));
    }
  }

  Future<Either<Failure, Map<String, MuscleVisualData>>>
      _getAllTimeVisualData() async {
    try {
      final visualData = <String, MuscleVisualData>{};
      double maxStimulusAcrossAll = 0.0;

      for (final muscleGroup in MuscleStimulus.allMuscleGroups) {
        final maxResult =
            await muscleStimulusRepository.getMaxStimulusForMuscle(muscleGroup);

        maxResult.fold(
          (_) {},
          (maxStimulus) {
            if (maxStimulus > maxStimulusAcrossAll) {
              maxStimulusAcrossAll = maxStimulus;
            }
          },
        );
      }

      final threshold = maxStimulusAcrossAll > 0
          ? maxStimulusAcrossAll
          : MuscleStimulus.dailyThreshold;

      for (final muscleGroup in MuscleStimulus.allMuscleGroups) {
        final maxResult =
            await muscleStimulusRepository.getMaxStimulusForMuscle(muscleGroup);

        visualData[muscleGroup] = maxResult.fold(
          (_) => MuscleVisualData.untrained(muscleGroup),
          (maxStimulus) {
            if (maxStimulus == 0) {
              return MuscleVisualData.untrained(muscleGroup);
            }

            return _buildVisualData(
              muscleGroup: muscleGroup,
              stimulus: maxStimulus,
              threshold: threshold,
            );
          },
        );
      }

      return Right(visualData);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get all time visual data: $e'));
    }
  }

  Future<MuscleVisualData> _buildWeekDataWithoutToday({
    required String muscleGroup,
    required DateTime todayStart,
  }) async {
    final yesterday = todayStart.subtract(const Duration(days: 1));

    final yesterdayResult =
        await muscleStimulusRepository.getStimulusByMuscleAndDate(
      muscleGroup: muscleGroup,
      date: yesterday,
    );

    return yesterdayResult.fold(
      (_) => MuscleVisualData.untrained(muscleGroup),
      (yesterdayStimulus) {
        if (yesterdayStimulus == null) {
          return MuscleVisualData.untrained(muscleGroup);
        }

        final decayedLoad =
            yesterdayStimulus.rollingWeeklyLoad * MuscleStimulus.weeklyDecayFactor;

        return _buildVisualData(
          muscleGroup: muscleGroup,
          stimulus: decayedLoad,
          threshold: MuscleStimulus.weeklyThreshold,
        );
      },
    );
  }

  MuscleVisualData _buildVisualData({
    required String muscleGroup,
    required double stimulus,
    required double threshold,
  }) {
    final visualIntensity = StimulusCalculationRules.calculateVisualIntensity(
      totalStimulus: stimulus,
      threshold: threshold,
    );

    return MuscleVisualData(
      muscleGroup: muscleGroup,
      totalStimulus: stimulus,
      visualIntensity: visualIntensity,
      color: MuscleVisualData.getColorForIntensity(visualIntensity),
      hasTrained: stimulus > 0,
    );
  }

  Future<Either<Failure, Map<String, MuscleVisualData>>> getVisualDataForMuscles(
    TimePeriod period,
    List<String> muscleGroups,
  ) async {
    final allDataResult = await call(period);

    return allDataResult.fold(
      (failure) => Left(failure),
      (allData) {
        final filteredData = <String, MuscleVisualData>{};

        for (final muscleGroup in muscleGroups) {
          if (allData.containsKey(muscleGroup)) {
            filteredData[muscleGroup] = allData[muscleGroup]!;
          }
        }

        return Right(filteredData);
      },
    );
  }
}