import 'package:dartz/dartz.dart';
import '../../../core/constants/muscle_stimulus_constants.dart';
import '../../../core/errors/failures.dart';
import '../../entities/muscle_visual_data.dart';
import '../../entities/stimulus_calculation_rules.dart';
import '../../entities/time_period.dart';
import '../../repositories/muscle_stimulus_repository.dart';

/// Use case for retrieving muscle visualization data
/// 
/// Fetches stimulus data for a given time period and converts it
/// into visual representation data (color, intensity) for the home page.
/// 
/// Handles different time periods with appropriate thresholds:
/// - Today: Real-time with recovery decay
/// - Week: Rolling weekly load
/// - Month: 30-day aggregation
/// - All Time: Maximum ever recorded
class GetMuscleVisualData {
  final MuscleStimulusRepository muscleStimulusRepository;

  const GetMuscleVisualData(this.muscleStimulusRepository);

  /// Get visual data for all muscle groups for a given time period
  /// 
  /// Parameters:
  /// - period: Time period to analyze (today/week/month/allTime)
  /// 
  /// Returns: Map of muscle group to visual data
  /// 
  /// Example:
  /// ```dart
  /// final result = await getVisualData(TimePeriod.week);
  /// // Returns visual data with colors based on weekly training volume
  /// ```
  Future<Either<Failure, Map<String, MuscleVisualData>>> call(
    TimePeriod period,
  ) async {
    try {
      // Get stimulus data based on period
      switch (period) {
        case TimePeriod.today:
          return await _getTodayVisualData();
        case TimePeriod.week:
          return await _getWeekVisualData();
        case TimePeriod.month:
          return await _getMonthVisualData();
        case TimePeriod.allTime:
          return await _getAllTimeVisualData();
      }
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get visual data: $e'));
    }
  }

  /// Get visual data for today with real-time recovery decay
  Future<Either<Failure, Map<String, MuscleVisualData>>> _getTodayVisualData() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final Map<String, MuscleVisualData> visualData = {};

      // Process each muscle group
      for (final muscleGroup in MuscleStimulus.allMuscleGroups) {
        final stimulusResult = await muscleStimulusRepository.getStimulusByMuscleAndDate(
          muscleGroup: muscleGroup,
          date: todayStart,
        );

        stimulusResult.fold(
          (failure) {
            // On error, show muscle as untrained
            visualData[muscleGroup] = MuscleVisualData.untrained(muscleGroup);
          },
          (stimulus) {
            if (stimulus == null) {
              // No training today
              visualData[muscleGroup] = MuscleVisualData.untrained(muscleGroup);
            } else {
              // Calculate remaining stimulus after recovery decay
              final remainingStimulus = stimulus.calculateRemainingStimulus();
              
              // Calculate visual intensity based on daily threshold
              final visualIntensity = StimulusCalculationRules.calculateVisualIntensity(
                totalStimulus: remainingStimulus,
                threshold: MuscleStimulus.dailyThreshold,
              );

              visualData[muscleGroup] = MuscleVisualData(
                muscleGroup: muscleGroup,
                totalStimulus: remainingStimulus,
                visualIntensity: visualIntensity,
                color: MuscleVisualData.getColorForIntensity(visualIntensity),
                hasTrained: remainingStimulus > 0,
              );
            }
          },
        );
      }

      return Right(visualData);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get today visual data: $e'));
    }
  }

  /// Get visual data for the past week using rolling weekly load
  Future<Either<Failure, Map<String, MuscleVisualData>>> _getWeekVisualData() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final Map<String, MuscleVisualData> visualData = {};

      // Process each muscle group
      for (final muscleGroup in MuscleStimulus.allMuscleGroups) {
        final stimulusResult = await muscleStimulusRepository.getStimulusByMuscleAndDate(
          muscleGroup: muscleGroup,
          date: todayStart,
        );

        stimulusResult.fold(
          (failure) {
            // On error, show muscle as untrained
            visualData[muscleGroup] = MuscleVisualData.untrained(muscleGroup);
          },
          (stimulus) {
            if (stimulus == null) {
              // No recent training, check yesterday
              _handleNoRecentTraining(muscleGroup, todayStart, visualData);
            } else {
              // Use rolling weekly load
              final weeklyLoad = stimulus.rollingWeeklyLoad;
              
              // Calculate visual intensity based on weekly threshold
              final visualIntensity = StimulusCalculationRules.calculateVisualIntensity(
                totalStimulus: weeklyLoad,
                threshold: MuscleStimulus.weeklyThreshold,
              );

              visualData[muscleGroup] = MuscleVisualData(
                muscleGroup: muscleGroup,
                totalStimulus: weeklyLoad,
                visualIntensity: visualIntensity,
                color: MuscleVisualData.getColorForIntensity(visualIntensity),
                hasTrained: weeklyLoad > 0,
              );
            }
          },
        );
      }

      return Right(visualData);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get week visual data: $e'));
    }
  }

  /// Get visual data for the past month (30 days aggregation)
  Future<Either<Failure, Map<String, MuscleVisualData>>> _getMonthVisualData() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final monthAgo = todayStart.subtract(const Duration(days: 30));

      final Map<String, MuscleVisualData> visualData = {};

      // Process each muscle group
      for (final muscleGroup in MuscleStimulus.allMuscleGroups) {
        final stimulusResult = await muscleStimulusRepository.getStimulusByDateRange(
          muscleGroup: muscleGroup,
          startDate: monthAgo,
          endDate: todayStart,
        );

        stimulusResult.fold(
          (failure) {
            // On error, show muscle as untrained
            visualData[muscleGroup] = MuscleVisualData.untrained(muscleGroup);
          },
          (stimulusList) {
            // Sum all daily stimulus values for the month
            final monthlyStimulus = stimulusList.fold<double>(
              0.0,
              (sum, stimulus) => sum + stimulus.dailyStimulus,
            );

            // Calculate visual intensity based on monthly threshold
            final visualIntensity = StimulusCalculationRules.calculateVisualIntensity(
              totalStimulus: monthlyStimulus,
              threshold: MuscleStimulus.monthlyThreshold,
            );

            visualData[muscleGroup] = MuscleVisualData(
              muscleGroup: muscleGroup,
              totalStimulus: monthlyStimulus,
              visualIntensity: visualIntensity,
              color: MuscleVisualData.getColorForIntensity(visualIntensity),
              hasTrained: monthlyStimulus > 0,
            );
          },
        );
      }

      return Right(visualData);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get month visual data: $e'));
    }
  }

  /// Get visual data for all time (maximum stimulus ever recorded)
  Future<Either<Failure, Map<String, MuscleVisualData>>> _getAllTimeVisualData() async {
    try {
      final Map<String, MuscleVisualData> visualData = {};
      double maxStimulusAcrossAll = 0.0;

      // First pass: Find maximum stimulus across all muscles
      for (final muscleGroup in MuscleStimulus.allMuscleGroups) {
        final maxResult = await muscleStimulusRepository.getMaxStimulusForMuscle(muscleGroup);
        
        maxResult.fold(
          (failure) {
            // Skip on error
          },
          (maxStimulus) {
            if (maxStimulus > maxStimulusAcrossAll) {
              maxStimulusAcrossAll = maxStimulus;
            }
          },
        );
      }

      // Use the global maximum as threshold, or default if no data
      final threshold = maxStimulusAcrossAll > 0 
          ? maxStimulusAcrossAll 
          : MuscleStimulus.dailyThreshold;

      // Second pass: Calculate visual intensity for each muscle
      for (final muscleGroup in MuscleStimulus.allMuscleGroups) {
        final maxResult = await muscleStimulusRepository.getMaxStimulusForMuscle(muscleGroup);
        
        maxResult.fold(
          (failure) {
            // On error, show muscle as untrained
            visualData[muscleGroup] = MuscleVisualData.untrained(muscleGroup);
          },
          (maxStimulus) {
            if (maxStimulus == 0) {
              // Never trained
              visualData[muscleGroup] = MuscleVisualData.untrained(muscleGroup);
            } else {
              // Calculate relative intensity
              final visualIntensity = StimulusCalculationRules.calculateVisualIntensity(
                totalStimulus: maxStimulus,
                threshold: threshold,
              );

              visualData[muscleGroup] = MuscleVisualData(
                muscleGroup: muscleGroup,
                totalStimulus: maxStimulus,
                visualIntensity: visualIntensity,
                color: MuscleVisualData.getColorForIntensity(visualIntensity),
                hasTrained: true,
              );
            }
          },
        );
      }

      return Right(visualData);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get all time visual data: $e'));
    }
  }

  /// Handle case where no stimulus data exists for today
  /// 
  /// Checks yesterday's data to show decayed weekly load
  void _handleNoRecentTraining(
    String muscleGroup,
    DateTime todayStart,
    Map<String, MuscleVisualData> visualData,
  ) async {
    // Check yesterday for rolling weekly load
    final yesterday = todayStart.subtract(const Duration(days: 1));
    final yesterdayResult = await muscleStimulusRepository.getStimulusByMuscleAndDate(
      muscleGroup: muscleGroup,
      date: yesterday,
    );

    yesterdayResult.fold(
      (failure) {
        visualData[muscleGroup] = MuscleVisualData.untrained(muscleGroup);
      },
      (yesterdayStimulus) {
        if (yesterdayStimulus == null) {
          visualData[muscleGroup] = MuscleVisualData.untrained(muscleGroup);
        } else {
          // Apply decay to yesterday's weekly load
          final decayedLoad = yesterdayStimulus.rollingWeeklyLoad * 
                             MuscleStimulus.weeklyDecayFactor;
          
          final visualIntensity = StimulusCalculationRules.calculateVisualIntensity(
            totalStimulus: decayedLoad,
            threshold: MuscleStimulus.weeklyThreshold,
          );

          visualData[muscleGroup] = MuscleVisualData(
            muscleGroup: muscleGroup,
            totalStimulus: decayedLoad,
            visualIntensity: visualIntensity,
            color: MuscleVisualData.getColorForIntensity(visualIntensity),
            hasTrained: decayedLoad > 0,
          );
        }
      },
    );
  }

  /// Get visual data for a specific list of muscle groups
  /// 
  /// Useful for filtering visualization to specific muscles
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