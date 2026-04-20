import 'package:dartz/dartz.dart';

import '../../../core/constants/muscle_stimulus_constants.dart';
import '../../../core/errors/failures.dart';
import '../../entities/muscle_visual_data.dart';
import '../../entities/time_period.dart';
import '../../muscle_visual/muscle_visual_contract.dart';
import '../../muscle_visual/normalized_muscle_load.dart';
import '../../repositories/muscle_stimulus_repository.dart';

class GetMuscleVisualData {
  final MuscleStimulusRepository muscleStimulusRepository;

  const GetMuscleVisualData(this.muscleStimulusRepository);

  Future<Either<Failure, Map<String, MuscleVisualData>>> call(
    TimePeriod period,
    String userId,
  ) async {
    try {
      switch (period) {
        case TimePeriod.today:
          return _getTodayVisualData(userId);
        case TimePeriod.week:
          return _getWeekVisualData(userId);
        case TimePeriod.month:
          return _getMonthVisualData(userId);
        case TimePeriod.allTime:
          return _getAllTimeVisualData(userId);
      }
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get visual data: $e'));
    }
  }

  Future<Either<Failure, Map<String, MuscleVisualData>>> _getTodayVisualData(
    String userId,
  ) async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final aggregationMode = MuscleVisualContract.aggregationModeForPeriod(
        TimePeriod.today,
      );

      final visualData = <String, MuscleVisualData>{};

      for (final muscleGroup in MuscleStimulus.allMuscleGroups) {
        final stimulusResult =
            await muscleStimulusRepository.getStimulusByMuscleAndDate(
          userId: userId,
          muscleGroup: muscleGroup,
          date: todayStart,
        );

        visualData[muscleGroup] = stimulusResult.fold(
          (_) => MuscleVisualData.untrained(
            muscleGroup,
            aggregationMode: aggregationMode,
          ),
          (stimulus) {
            if (stimulus == null) {
              return MuscleVisualData.untrained(
                muscleGroup,
                aggregationMode: aggregationMode,
              );
            }

            return _buildVisualData(
              muscleGroup: muscleGroup,
              stimulus: stimulus.dailyStimulus,
              threshold: MuscleStimulus.dailyThreshold,
              aggregationMode: aggregationMode,
            );
          },
        );
      }

      return Right(visualData);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get today visual data: $e'));
    }
  }

  Future<Either<Failure, Map<String, MuscleVisualData>>> _getWeekVisualData(
    String userId,
  ) async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final aggregationMode = MuscleVisualContract.aggregationModeForPeriod(
        TimePeriod.week,
      );

      final visualData = <String, MuscleVisualData>{};

      for (final muscleGroup in MuscleStimulus.allMuscleGroups) {
        final stimulusResult =
            await muscleStimulusRepository.getStimulusByMuscleAndDate(
          userId: userId,
          muscleGroup: muscleGroup,
          date: todayStart,
        );

        if (stimulusResult.isLeft()) {
          visualData[muscleGroup] = MuscleVisualData.untrained(
            muscleGroup,
            aggregationMode: aggregationMode,
          );
          continue;
        }

        final stimulus = stimulusResult.getOrElse(() => throw StateError(''));

        if (stimulus == null) {
          visualData[muscleGroup] = await _buildWeekDataWithoutToday(
            userId: userId,
            muscleGroup: muscleGroup,
            todayStart: todayStart,
          );
          continue;
        }

        visualData[muscleGroup] = _buildVisualData(
          muscleGroup: muscleGroup,
          stimulus: stimulus.rollingWeeklyLoad,
          threshold: MuscleStimulus.weeklyThreshold,
          aggregationMode: aggregationMode,
        );
      }

      return Right(visualData);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get week visual data: $e'));
    }
  }

  Future<Either<Failure, Map<String, MuscleVisualData>>> _getMonthVisualData(
    String userId,
  ) async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final monthAgo = todayStart.subtract(const Duration(days: 30));
      final aggregationMode = MuscleVisualContract.aggregationModeForPeriod(
        TimePeriod.month,
      );

      final visualData = <String, MuscleVisualData>{};

      for (final muscleGroup in MuscleStimulus.allMuscleGroups) {
        final stimulusResult =
            await muscleStimulusRepository.getStimulusByDateRange(
          userId: userId,
          muscleGroup: muscleGroup,
          startDate: monthAgo,
          endDate: todayStart,
        );

        visualData[muscleGroup] = stimulusResult.fold(
          (_) => MuscleVisualData.untrained(
            muscleGroup,
            aggregationMode: aggregationMode,
          ),
          (stimulusList) {
            final monthlyStimulus = stimulusList.fold<double>(
              0.0,
              (sum, stimulus) => sum + stimulus.dailyStimulus,
            );

            return _buildVisualData(
              muscleGroup: muscleGroup,
              stimulus: monthlyStimulus,
              threshold: MuscleStimulus.monthlyThreshold,
              aggregationMode: aggregationMode,
            );
          },
        );
      }

      return Right(visualData);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get month visual data: $e'));
    }
  }

  Future<Either<Failure, Map<String, MuscleVisualData>>> _getAllTimeVisualData(
    String userId,
  ) async {
    try {
      final aggregationMode = MuscleVisualContract.aggregationModeForPeriod(
        TimePeriod.allTime,
      );

      final visualData = <String, MuscleVisualData>{};
      double maxStimulusAcrossAll = 0.0;

      for (final muscleGroup in MuscleStimulus.allMuscleGroups) {
        final maxResult = await muscleStimulusRepository.getMaxStimulusForMuscle(
          userId,
          muscleGroup,
        );

        maxResult.fold((_) {}, (maxStimulus) {
          if (maxStimulus > maxStimulusAcrossAll) {
            maxStimulusAcrossAll = maxStimulus;
          }
        });
      }

      final threshold = maxStimulusAcrossAll > 0
          ? maxStimulusAcrossAll
          : MuscleStimulus.dailyThreshold;

      for (final muscleGroup in MuscleStimulus.allMuscleGroups) {
        final maxResult = await muscleStimulusRepository.getMaxStimulusForMuscle(
          userId,
          muscleGroup,
        );

        visualData[muscleGroup] = maxResult.fold(
          (_) => MuscleVisualData.untrained(
            muscleGroup,
            aggregationMode: aggregationMode,
          ),
          (maxStimulus) {
            if (maxStimulus == 0) {
              return MuscleVisualData.untrained(
                muscleGroup,
                aggregationMode: aggregationMode,
              );
            }

            return _buildVisualData(
              muscleGroup: muscleGroup,
              stimulus: maxStimulus,
              threshold: threshold,
              aggregationMode: aggregationMode,
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
    required String userId,
    required String muscleGroup,
    required DateTime todayStart,
  }) async {
    final aggregationMode = MuscleVisualContract.aggregationModeForPeriod(
      TimePeriod.week,
    );

    // Look back up to 30 days for the most recent stored record and compute
    // decayedLoad = storedLoad * 0.6^daysSince (passive time-based decay).
    final lookbackStart = todayStart.subtract(const Duration(days: 30));
    final pastRecordsResult =
        await muscleStimulusRepository.getStimulusByDateRange(
      userId: userId,
      muscleGroup: muscleGroup,
      startDate: lookbackStart,
      endDate: todayStart.subtract(const Duration(days: 1)),
    );

    return pastRecordsResult.fold(
      (_) => MuscleVisualData.untrained(
        muscleGroup,
        aggregationMode: aggregationMode,
      ),
      (records) {
        if (records.isEmpty) {
          return MuscleVisualData.untrained(
            muscleGroup,
            aggregationMode: aggregationMode,
          );
        }

        // Records are returned DESC by date — first is most recent.
        final mostRecent = records.first;
        final daysSince = todayStart
            .difference(
              DateTime(
                mostRecent.date.year,
                mostRecent.date.month,
                mostRecent.date.day,
              ),
            )
            .inDays;

        // Route through [NormalizedMuscleLoad] so that both the decay and
        // the recovery comparison happen in consistent units.  The raw
        // rollingWeeklyLoad is ~1–30; [MuscleStimulus.recoveredThreshold]
        // is expressed against the *normalized* 0..1 scale, so comparing
        // raw to threshold directly would leave muscles "fatigued" for
        // days after they have actually recovered.
        final load = NormalizedMuscleLoad(
          raw: mostRecent.rollingWeeklyLoad,
          threshold: MuscleStimulus.weeklyThreshold,
        ).decayed(daysSince);

        if (load.isRecovered) {
          return MuscleVisualData.untrained(
            muscleGroup,
            aggregationMode: aggregationMode,
          );
        }

        return _buildVisualData(
          muscleGroup: muscleGroup,
          stimulus: load.raw,
          threshold: load.threshold,
          aggregationMode: aggregationMode,
        );
      },
    );
  }

  MuscleVisualData _buildVisualData({
    required String muscleGroup,
    required double stimulus,
    required double threshold,
    required MuscleVisualAggregationMode aggregationMode,
  }) {
    return MuscleVisualData.fromStimulus(
      muscleGroup: muscleGroup,
      stimulus: stimulus,
      threshold: threshold,
      aggregationMode: aggregationMode,
    );
  }

  Future<Either<Failure, Map<String, MuscleVisualData>>>
      getVisualDataForMuscles(
    TimePeriod period,
    String userId,
    List<String> muscleGroups,
  ) async {
    final allDataResult = await call(period, userId);

    return allDataResult.fold((failure) => Left(failure), (allData) {
      final filteredData = <String, MuscleVisualData>{};

      for (final muscleGroup in muscleGroups) {
        if (allData.containsKey(muscleGroup)) {
          filteredData[muscleGroup] = allData[muscleGroup]!;
        }
      }

      return Right(filteredData);
    });
  }
}
