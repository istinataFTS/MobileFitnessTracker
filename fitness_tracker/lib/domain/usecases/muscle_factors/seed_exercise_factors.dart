import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../config/env_config.dart';
import '../../../core/constants/exercise_muscle_factors_data.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/exercise_repository.dart';
import '../../repositories/muscle_factor_repository.dart';

/// Use case to seed exercise muscle factors into the database
/// 
/// This populates the exercise_muscle_factors table with comprehensive
/// biomechanically-accurate factor assignments for all seeded exercises.
/// 
/// Should be executed after exercises are seeded.
class SeedExerciseFactors {
  final MuscleFactorRepository muscleFactorRepository;
  final ExerciseRepository exerciseRepository;
  final _uuid = const Uuid();

  const SeedExerciseFactors({
    required this.muscleFactorRepository,
    required this.exerciseRepository,
  });

  Future<Either<Failure, int>> call() async {
    try {
      // Step 1: Check if seeding is enabled
      if (!EnvConfig.seedDefaultData) {
        _log('Muscle factor seeding disabled in environment config');
        return const Right(0);
      }

      _log('Starting exercise muscle factors seeding...');
      _log('Seed data version: ${EnvConfig.seedDataVersion}');

      // Step 2: Get all exercises from database
      final exercisesResult = await exerciseRepository.getAllExercises();
      
      return await exercisesResult.fold(
        // Error getting exercises
        (failure) async {
          _logError('Failed to get exercises: ${failure.message}');
          return Left(failure);
        },
        // Successfully got exercises
        (exercises) async {
          if (exercises.isEmpty) {
            _logWarning('No exercises found in database. Seed exercises first.');
            return const Left(DatabaseFailure('No exercises to assign factors to'));
          }

          _log('Found ${exercises.length} exercises in database');

          // Step 3: Check if factors already exist
          final existingFactorsResult = await muscleFactorRepository.getAllFactors();
          
          return await existingFactorsResult.fold(
            (failure) async {
              _logError('Failed to check existing factors: ${failure.message}');
              return Left(failure);
            },
            (existingFactors) async {
              final hasExistingData = existingFactors.isNotEmpty;

              // Step 4: Decide if we should seed
              if (hasExistingData && !EnvConfig.forceReseed) {
                _log('Database already has ${existingFactors.length} muscle factors');
                _log('Skipping seeding (set FORCE_RESEED=true to override)');
                return const Right(0);
              }

              if (hasExistingData && EnvConfig.forceReseed) {
                _logWarning('Force reseed enabled - clearing existing factors');
                await _clearExistingFactors();
              }

              // Step 5: Perform seeding
              return await _seedFactors(exercises);
            },
          );
        },
      );
    } catch (e) {
      _logError('Unexpected error during factor seeding: $e');
      return Left(DatabaseFailure('Factor seeding failed: $e'));
    }
  }

  /// Clear existing muscle factor data (used with force reseed)
  Future<void> _clearExistingFactors() async {
    _log('Clearing existing muscle factor data...');
    
    try {
      await muscleFactorRepository.clearAllFactors();
      _log('Successfully cleared existing factors');
    } catch (e) {
      _logError('Failed to clear existing factors: $e');
      rethrow;
    }
  }

  /// Seed muscle factors for all exercises
  Future<Either<Failure, int>> _seedFactors(List<dynamic> exercises) async {
    _log('Seeding exercise muscle factors...');
    
    final allFactorsData = ExerciseMuscleFactorsData.getAllFactors();
    _log('Total exercises with factors: ${allFactorsData.length}');
    _log('Total factor assignments: ${ExerciseMuscleFactorsData.totalFactorAssignments}');

    // Create a map of exercise name to exercise ID for quick lookup
    final exerciseNameToId = <String, String>{};
    for (final exercise in exercises) {
      exerciseNameToId[exercise.name] = exercise.id;
    }

    int successCount = 0;
    int failureCount = 0;
    int skippedCount = 0;

    // Process each exercise
    for (final entry in allFactorsData.entries) {
      final exerciseName = entry.key;
      final factorsData = entry.value;

      // Check if exercise exists in database
      if (!exerciseNameToId.containsKey(exerciseName)) {
        _logWarning('Exercise "$exerciseName" not found in database, skipping');
        skippedCount++;
        continue;
      }

      final exerciseId = exerciseNameToId[exerciseName]!;

      // Insert factors for this exercise
      try {
        for (final factorData in factorsData) {
          final factor = factorData.toEntity(
            id: _uuid.v4(),
            exerciseId: exerciseId,
          );

          final result = await muscleFactorRepository.addMuscleFactor(factor);
          
          result.fold(
            (failure) {
              failureCount++;
              _logError('Failed to seed factor for "$exerciseName" - ${factorData.muscleGroup}: ${failure.message}');
            },
            (_) {
              successCount++;
              _logVerbose('✓ Seeded: $exerciseName → ${factorData.muscleGroup} (${factorData.factor})');
            },
          );
        }
      } catch (e) {
        failureCount++;
        _logError('Exception seeding factors for "$exerciseName": $e');
      }
    }

    // Step 6: Log results
    _log('========== Factor Seeding Complete ==========');
    _log('Successfully seeded: $successCount muscle factors');
    if (skippedCount > 0) {
      _logWarning('Skipped: $skippedCount exercises (not in database)');
    }
    if (failureCount > 0) {
      _logWarning('Failed to seed: $failureCount factors');
    }
    _log('============================================');

    // Step 7: Validation
    await _validateSeeding(exercises);

    // Return success if at least some factors were seeded
    if (successCount > 0) {
      return Right(successCount);
    } else {
      return const Left(DatabaseFailure('Failed to seed any muscle factors'));
    }
  }

  /// Validate that all exercises have at least one muscle factor
  Future<void> _validateSeeding(List<dynamic> exercises) async {
    _log('Validating muscle factor seeding...');

    int exercisesWithoutFactors = 0;

    for (final exercise in exercises) {
      final factorsResult = await muscleFactorRepository.getFactorsForExercise(exercise.id);
      
      factorsResult.fold(
        (failure) {
          _logError('Failed to validate factors for "${exercise.name}": ${failure.message}');
        },
        (factors) {
          if (factors.isEmpty) {
            _logWarning('⚠️  Exercise "${exercise.name}" has no muscle factors!');
            exercisesWithoutFactors++;
          }
        },
      );
    }

    if (exercisesWithoutFactors == 0) {
      _log('✅ All exercises have muscle factors assigned');
    } else {
      _logWarning('⚠️  $exercisesWithoutFactors exercises missing muscle factors');
    }
  }

  /// Validate seeding environment (optional pre-check)
  bool validateEnvironment() {
    if (EnvConfig.isProduction && EnvConfig.forceReseed) {
      _logError('CRITICAL: Force reseed enabled in production!');
      return false;
    }

    if (!EnvConfig.seedDefaultData) {
      _log('Factor seeding is disabled');
      return false;
    }

    return true;
  }

  // ==================== LOGGING HELPERS ====================

  void _log(String message) {
    if (!EnvConfig.enableSeedingLogs) return;
    debugPrint('[SEED_FACTORS] $message');
  }

  void _logVerbose(String message) {
    if (!EnvConfig.enableSeedingLogs || !EnvConfig.enableDebugLogs) return;
    debugPrint('[SEED_FACTORS] $message');
  }

  void _logWarning(String message) {
    if (!EnvConfig.enableSeedingLogs) return;
    debugPrint('[SEED_FACTORS] ⚠️  WARNING: $message');
  }

  void _logError(String message) {
    if (!EnvConfig.enableSeedingLogs) return;
    debugPrint('[SEED_FACTORS] ❌ ERROR: $message');
  }
}