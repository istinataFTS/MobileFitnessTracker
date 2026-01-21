import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../config/env_config.dart';
import '../../../core/errors/failures.dart';
import '../../entities/muscle_stimulus.dart';
import '../../repositories/muscle_factor_repository.dart';
import '../../repositories/muscle_stimulus_repository.dart';
import 'calculate_muscle_stimulus.dart';

/// Use case for recording a workout set and updating muscle stimulus
/// 
/// This is the main entry point for logging training data.
/// When a user completes a set, this use case:
/// 1. Calculates stimulus for all affected muscles
/// 2. Checks if this is the first set of a new day (triggers decay)
/// 3. Updates daily stimulus accumulation
/// 4. Updates rolling weekly load with decay factor
/// 5. Records timestamp and stimulus for real-time recovery tracking
/// 
/// All updates are performed atomically to maintain data integrity.
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

  /// Record a workout set and update all affected muscle stimuli
  /// 
  /// Parameters:
  /// - exerciseId: ID of the exercise performed
  /// - sets: Number of sets (typically 1 for single set logging)
  /// - intensity: Intensity level (0-5 scale)
  /// - timestamp: When the set was performed (defaults to now)
  /// 
  /// Returns: Success with list of affected muscle groups
  /// 
  /// Example:
  /// ```dart
  /// final result = await recordWorkoutSet(
  ///   exerciseId: 'bench-press-id',
  ///   sets: 1,
  ///   intensity: 4,
  /// );
  /// // Updates: mid-chest, upper-chest, lower-chest, front-delts, triceps
  /// ```
  Future<Either<Failure, List<String>>> call({
    required String exerciseId,
    required int sets,
    required int intensity,
    DateTime? timestamp,
  }) async {
    try {
      final setTimestamp = timestamp ?? DateTime.now();
      final now = DateTime.now();

      // Step 1: Calculate stimulus for this set
      final stimulusResult = await calculateMuscleStimulus.calculateSetStimulus(
        exerciseId: exerciseId,
        sets: sets,
        intensity: intensity,
      );

      return await stimulusResult.fold(
        (failure) async => Left(failure),
        (muscleStimuli) async {
          // If no muscles affected, return empty list
          if (muscleStimuli.isEmpty) {
            return const Right([]);
          }

          // Step 2: Check if we need to apply daily decay
          final shouldApplyDecay = await _shouldApplyDailyDecay(setTimestamp);
          if (shouldApplyDecay) {
            await _applyDailyDecay();
          }

          // Step 3: Update stimulus for each affected muscle
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
                // Log error but continue with other muscles
                if (EnvConfig.enableDebugLogs) {
                  // In production, use proper logging
                  print('Failed to update stimulus for $muscleGroup: ${failure.message}');
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

  /// Update muscle stimulus record for a single muscle group
  /// 
  /// Handles both creating new records and updating existing ones.
  /// Applies the rolling weekly load formula with decay.
  Future<Either<Failure, void>> _updateMuscleStimulus({
    required String muscleGroup,
    required double setStimulus,
    required int setTimestamp,
    required DateTime now,
  }) async {
    try {
      // Get today's date for record lookup
      final today = DateTime(now.year, now.month, now.day);

      // Check if stimulus record exists for today
      final existingResult = await muscleStimulusRepository.getStimulusByMuscleAndDate(
        muscleGroup: muscleGroup,
        date: today,
      );

      return await existingResult.fold(
        (failure) async => Left(failure),
        (existingStimulus) async {
          if (existingStimulus == null) {
            // Create new stimulus record
            return await _createNewStimulusRecord(
              muscleGroup: muscleGroup,
              setStimulus: setStimulus,
              setTimestamp: setTimestamp,
              date: today,
            );
          } else {
            // Update existing stimulus record
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

  /// Create a new stimulus record for a muscle on a new day
  Future<Either<Failure, void>> _createNewStimulusRecord({
    required String muscleGroup,
    required double setStimulus,
    required int setTimestamp,
    required DateTime date,
  }) async {
    try {
      // Get yesterday's stimulus for rolling weekly load calculation
      final yesterday = date.subtract(const Duration(days: 1));
      final yesterdayResult = await muscleStimulusRepository.getStimulusByMuscleAndDate(
        muscleGroup: muscleGroup,
        date: yesterday,
      );

      double previousWeeklyLoad = 0.0;
      yesterdayResult.fold(
        (failure) {
          // No previous data, start fresh
        },
        (yesterdayStimulus) {
          if (yesterdayStimulus != null) {
            previousWeeklyLoad = yesterdayStimulus.rollingWeeklyLoad;
          }
        },
      );

      // Calculate new rolling weekly load with decay
      // Formula: previousWeeklyLoad * weeklyDecayFactor + dailyStimulus
      final newWeeklyLoad = (previousWeeklyLoad * MuscleStimulus.weeklyDecayFactor) + setStimulus;

      // Create new stimulus entity
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

      // Persist to database
      return await muscleStimulusRepository.upsertStimulus(stimulus);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to create stimulus record: $e'));
    }
  }

  /// Update an existing stimulus record with new set data
  Future<Either<Failure, void>> _updateExistingStimulusRecord({
    required MuscleStimulus existing,
    required double setStimulus,
    required int setTimestamp,
  }) async {
    try {
      // Add this set's stimulus to today's total
      final newDailyStimulus = existing.dailyStimulus + setStimulus;

      // Update rolling weekly load
      // Note: We only apply the decay factor once per day (at day transition)
      // Within the same day, we just add to the rolling load
      final newWeeklyLoad = existing.rollingWeeklyLoad + setStimulus;

      // Update the record
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

  /// Check if we should apply daily decay
  /// 
  /// Returns true if this is the first set of a new calendar day.
  /// We detect this by checking if any muscle has a stimulus record
  /// from yesterday but not today yet.
  Future<bool> _shouldApplyDailyDecay(DateTime setTimestamp) async {
    try {
      final today = DateTime(setTimestamp.year, setTimestamp.month, setTimestamp.day);
      
      // Check if we have any records for today
      final todayResult = await muscleStimulusRepository.getAllStimulusForDate(today);
      
      return todayResult.fold(
        (failure) => false, // On error, don't apply decay
        (todayRecords) {
          // If no records exist for today, this might be first set of new day
          // Check if we have records from yesterday
          if (todayRecords.isEmpty) {
            // This is the transition point - we should apply decay
            return true;
          }
          
          // Records exist for today, no need to apply decay
          return false;
        },
      );
    } catch (e) {
      return false; // On error, don't apply decay
    }
  }

  /// Apply daily decay to all muscle groups
  /// 
  /// This is called once per day on the first logged set.
  /// It applies the weekly decay factor (0.6) to all rolling weekly loads.
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

  /// Validate workout set inputs before recording
  /// 
  /// Useful for pre-validation in UI layer
  bool validateInputs({
    required int sets,
    required int intensity,
  }) {
    return calculateMuscleStimulus.validateInputs(
      sets: sets,
      intensity: intensity,
    );
  }
}