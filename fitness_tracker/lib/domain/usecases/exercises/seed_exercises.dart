import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../config/env_config.dart';
import '../../../core/constants/default_exercises_data.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/exercise_repository.dart';

class SeedExercises {
  final ExerciseRepository repository;
  final _uuid = const Uuid();

  const SeedExercises(this.repository);

  Future<Either<Failure, int>> call() async {
    try {
      // Step 1: Check if seeding is enabled
      if (!EnvConfig.seedDefaultData) {
        _log('Seeding disabled in environment config');
        return const Right(0);
      }

      _log('Starting database seeding process...');
      _log('Seed data version: ${EnvConfig.seedDataVersion}');

      // Step 2: Check if database already has exercises
      final existingExercisesResult = await repository.getAllExercises();
      
      return await existingExercisesResult.fold(
        // Error getting existing exercises
        (failure) async {
          _logError('Failed to check existing exercises: ${failure.message}');
          return Left(failure);
        },
        // Successfully got existing exercises
        (existingExercises) async {
          final hasExistingData = existingExercises.isNotEmpty;

          // Step 3: Decide if we should seed
          if (hasExistingData && !EnvConfig.forceReseed) {
            _log('Database already has ${existingExercises.length} exercises');
            _log('Skipping seeding (set FORCE_RESEED=true to override)');
            return const Right(0);
          }

          if (hasExistingData && EnvConfig.forceReseed) {
            _logWarning('Force reseed enabled - clearing existing data');
            // Note: In production, you might want to backup data first
            await _clearExistingData();
          }

          // Step 4: Perform seeding
          return await _seedDefaultExercises();
        },
      );
    } catch (e) {
      _logError('Unexpected error during seeding: $e');
      return Left(DatabaseFailure('Seeding failed: $e'));
    }
  }

  /// Clear existing exercise data (used with force reseed)
  Future<void> _clearExistingData() async {
    _log('Clearing existing exercise data...');
    
    try {
      await repository.clearAllExercises();
      _log('Successfully cleared existing data');
    } catch (e) {
      _logError('Failed to clear existing data: $e');
      rethrow;
    }
  }

  /// Seed all default exercises
  Future<Either<Failure, int>> _seedDefaultExercises() async {
    _log('Seeding default exercises...');
    
    final defaultExercises = DefaultExercisesData.getDefaultExercises();
    _log('Total exercises to seed: ${defaultExercises.length}');

    int successCount = 0;
    int failureCount = 0;
    final now = DateTime.now();

    // Seed exercises one by one
    // Note: In a production app, you might want to use batch insert
    for (final exerciseData in defaultExercises) {
      try {
        final exercise = exerciseData.toEntity(
          _uuid.v4(), 
          now,
        );

        final result = await repository.addExercise(exercise);
        
        result.fold(
          (failure) {
            failureCount++;
            _logError('Failed to seed "${exercise.name}": ${failure.message}');
          },
          (_) {
            successCount++;
            _logVerbose('✓ Seeded: ${exercise.name}');
          },
        );
      } catch (e) {
        failureCount++;
        _logError('Exception seeding "${exerciseData.name}": $e');
      }
    }

    // Step 5: Log results
    _log('========== Seeding Complete ==========');
    _log('Successfully seeded: $successCount exercises');
    if (failureCount > 0) {
      _logWarning('Failed to seed: $failureCount exercises');
    }
    _log('======================================');

    // Return success if at least some exercises were seeded
    if (successCount > 0) {
      return Right(successCount);
    } else {
      return const Left(DatabaseFailure('Failed to seed any exercises'));
    }
  }

  /// Validate seeding environment (optional pre-check)
  bool validateEnvironment() {
    if (EnvConfig.isProduction && EnvConfig.forceReseed) {
      _logError('CRITICAL: Force reseed enabled in production!');
      return false;
    }

    if (!EnvConfig.seedDefaultData) {
      _log('Seeding is disabled');
      return false;
    }

    return true;
  }

  // ==================== Logging Helpers ====================

  void _log(String message) {
    if (!EnvConfig.enableSeedingLogs) return;
    debugPrint('[SEED] $message');
  }

  void _logVerbose(String message) {
    if (!EnvConfig.enableSeedingLogs || !EnvConfig.enableDebugLogs) return;
    debugPrint('[SEED] $message');
  }

  void _logWarning(String message) {
    if (!EnvConfig.enableSeedingLogs) return;
    debugPrint('[SEED] ⚠️  WARNING: $message');
  }

  void _logError(String message) {
    if (!EnvConfig.enableSeedingLogs) return;
    debugPrint('[SEED] ❌ ERROR: $message');
  }
}
