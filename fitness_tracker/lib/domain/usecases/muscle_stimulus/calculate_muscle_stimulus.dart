import 'package:dartz/dartz.dart';
import '../../../core/constants/muscle_stimulus_constants.dart';
import '../../../core/errors/failures.dart';
import '../../entities/stimulus_calculation_rules.dart';
import '../../repositories/muscle_factor_repository.dart';

/// Use case for calculating muscle stimulus from workout sets
class CalculateMuscleStimulus {
  final MuscleFactorRepository muscleFactorRepository;

  const CalculateMuscleStimulus(this.muscleFactorRepository);

  /// Calculate stimulus for a single set of an exercise

  Future<Either<Failure, Map<String, double>>> calculateSetStimulus({
    required String exerciseId,
    required int sets,
    required int intensity,
  }) async {
    try {
      // Validate inputs
      if (sets < 0) {
        return const Left(ValidationFailure('Sets cannot be negative'));
      }

      if (!StimulusCalculationRules.validateIntensity(intensity)) {
        return Left(ValidationFailure(
          'Intensity must be between ${MuscleStimulus.minIntensity} and ${MuscleStimulus.maxIntensity}',
        ));
      }

      // Get muscle factors for this exercise
      final factorsResult = await muscleFactorRepository.getFactorsForExercise(exerciseId);
      
      return factorsResult.fold(
        (failure) => Left(failure),
        (factors) {
          // If no factors exist, return empty map (exercise has no muscle engagement)
          if (factors.isEmpty) {
            return const Right({});
          }

          // Calculate intensity factor using non-linear scaling
          final intensityFactor = StimulusCalculationRules.calculateIntensityFactor(
            intensity: intensity,
          );

          // Calculate stimulus for each muscle
          final Map<String, double> muscleStimuli = {};
          
          for (final factor in factors) {
            final stimulus = StimulusCalculationRules.calculateSetStimulus(
              sets: sets,
              intensityFactor: intensityFactor,
              exerciseFactor: factor.factor,
            );
            
            muscleStimuli[factor.muscleGroup] = stimulus;
          }

          return Right(muscleStimuli);
        },
      );
    } catch (e) {
      return Left(UnexpectedFailure('Failed to calculate stimulus: $e'));
    }
  }

  /// Calculate total stimulus for multiple sets of the same exercise

  Future<Either<Failure, Map<String, double>>> calculateMultipleSetStimulus({
    required String exerciseId,
    required int sets,
    required int intensity,
  }) async {
    // Calculate single set stimulus, then multiply by number of sets
    // Note: The sets parameter is already included in calculateSetStimulus
    return await calculateSetStimulus(
      exerciseId: exerciseId,
      sets: sets,
      intensity: intensity,
    );
  }

  /// Calculate aggregate stimulus across multiple exercises (for workout summary)

  Future<Either<Failure, Map<String, double>>> calculateWorkoutStimulus(
    List<Map<String, dynamic>> workoutSets,
  ) async {
    try {
      final Map<String, double> totalStimuli = {};

      for (final setData in workoutSets) {
        final exerciseId = setData['exerciseId'] as String;
        final sets = setData['sets'] as int;
        final intensity = setData['intensity'] as int;

        final result = await calculateSetStimulus(
          exerciseId: exerciseId,
          sets: sets,
          intensity: intensity,
        );

        result.fold(
          (failure) {
            // Log error but continue processing other sets
            // In production, you might want to collect these failures
          },
          (muscleStimuli) {
            // Aggregate stimulus for each muscle
            for (final entry in muscleStimuli.entries) {
              totalStimuli[entry.key] = 
                  (totalStimuli[entry.key] ?? 0.0) + entry.value;
            }
          },
        );
      }

      return Right(totalStimuli);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to calculate workout stimulus: $e'));
    }
  }

  /// Get intensity factor value for a given intensity level

  double getIntensityFactor(int intensity) {
    if (!StimulusCalculationRules.validateIntensity(intensity)) {
      return 0.0;
    }

    return StimulusCalculationRules.calculateIntensityFactor(
      intensity: intensity,
    );
  }

  /// Validate that stimulus calculation inputs are valid
  bool validateInputs({
    required int sets,
    required int intensity,
    double? exerciseFactor,
  }) {
    return StimulusCalculationRules.validateStimulusInputs(
      sets: sets,
      intensity: intensity,
      exerciseFactor: exerciseFactor ?? 1.0,
    );
  }
}