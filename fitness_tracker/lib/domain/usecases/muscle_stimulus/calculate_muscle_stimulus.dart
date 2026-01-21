import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/muscle_factor.dart';
import '../../entities/stimulus_calculation_rules.dart';
import '../../repositories/muscle_factor_repository.dart';

/// Use case for calculating muscle stimulus from workout sets
/// 
/// This use case calculates the training stimulus applied to each muscle group
/// based on the exercise performed, number of sets, and intensity level.
class CalculateMuscleStimulus {
  final MuscleFactorRepository muscleFactorRepository;

  CalculateMuscleStimulus({required this.muscleFactorRepository});

  /// Calculate stimulus for a single set of an exercise
  /// 
  /// Returns a map of muscle group -> stimulus value
  Future<Either<Failure, Map<String, double>>> calculateForSet({
    required String exerciseId,
    required int sets,
    required int intensity,
  }) async {
    try {
      // Get muscle factors for this exercise
      final factorsResult = await muscleFactorRepository.getFactorsForExercise(exerciseId);

      return factorsResult.fold(
        (failure) => Left(failure),
        (factors) {
          // Calculate stimulus for each affected muscle
          final muscleStimuli = <String, double>{};

          for (final factor in factors) {
            // Calculate intensity factor: (intensity / 5) ^ 1.35
            final intensityFactor = StimulusCalculationRules.calculateIntensityFactor(intensity);

            // Calculate set stimulus: sets * intensityFactor * exerciseFactor
            final setStimulus = StimulusCalculationRules.calculateSetStimulus(
              sets: sets,
              intensity: intensity, 
              exerciseFactor: factor.factor,
            );

            muscleStimuli[factor.muscleGroup] = setStimulus;
          }

          return Right(muscleStimuli);
        },
      );
    } catch (e) {
      return Left(UnexpectedFailure('Failed to calculate stimulus: $e'));
    }
  }

  /// Calculate total stimulus for an entire workout
  /// 
  /// Takes a list of sets with their exercise IDs and intensities,
  /// returns aggregated stimulus per muscle group
  Future<Either<Failure, Map<String, double>>> calculateForWorkout({
    required List<WorkoutSetInput> workoutSets,
  }) async {
    try {
      final totalStimuli = <String, double>{};

      for (final setInput in workoutSets) {
        final setResult = await calculateForSet(
          exerciseId: setInput.exerciseId,
          sets: 1, // Each entry represents one set
          intensity: setInput.intensity,
        );

        setResult.fold(
          (failure) => null, // Skip failed calculations
          (muscleStimuli) {
            // Aggregate stimuli for each muscle
            for (final entry in muscleStimuli.entries) {
              totalStimuli[entry.key] = (totalStimuli[entry.key] ?? 0.0) + entry.value;
            }
          },
        );
      }

      return Right(totalStimuli);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to calculate workout stimulus: $e'));
    }
  }

  /// Helper method to calculate intensity factor
  /// 
  /// This is a convenience wrapper around the calculation rule
  /// Formula: (intensity / 5) ^ 1.35
  double calculateIntensityFactor(int intensity) {
    return StimulusCalculationRules.calculateIntensityFactor(intensity);
  }
}

/// Input data for a single workout set
class WorkoutSetInput {
  final String exerciseId;
  final int intensity;

  const WorkoutSetInput({
    required this.exerciseId,
    required this.intensity,
  });
}