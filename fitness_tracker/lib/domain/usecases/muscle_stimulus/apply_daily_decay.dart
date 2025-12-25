import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../config/env_config.dart';
import '../../../core/constants/muscle_stimulus_constants.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/muscle_stimulus_repository.dart';

/// Use case for applying daily decay to rolling weekly loads
class ApplyDailyDecay {
  final MuscleStimulusRepository muscleStimulusRepository;

  const ApplyDailyDecay(this.muscleStimulusRepository);

  Future<Either<Failure, int>> call() async {
    try {
      _logDebug('Starting daily decay application...');
      
      // Apply decay via repository
      // This updates all muscle stimulus records with decay factor
      final result = await muscleStimulusRepository.applyDailyDecayToAll();
      
      return result.fold(
        (failure) {
          _logError('Failed to apply daily decay: ${failure.message}');
          return Left(failure);
        },
        (_) {
          _logDebug('Daily decay applied successfully');
          
          // Count how many muscles were affected
          // Note: The repository handles the actual update count
          // We return a success indicator
          return const Right(20); // All muscle groups
        },
      );
    } catch (e) {
      _logError('Exception during daily decay: $e');
      return Left(UnexpectedFailure('Failed to apply daily decay: $e'));
    }
  }

  /// Apply decay for a specific date (for manual corrections)
  Future<Either<Failure, int>> applyDecayForDate(DateTime date) async {
    try {
      _logDebug('Applying decay for date: ${date.toIso8601String()}');
      
      final dateStart = DateTime(date.year, date.month, date.day);
      
      // Get all stimulus records for this date
      final recordsResult = await muscleStimulusRepository.getAllStimulusForDate(dateStart);
      
      return await recordsResult.fold(
        (failure) async => Left(failure),
        (records) async {
          if (records.isEmpty) {
            _logDebug('No records found for date, skipping decay');
            return const Right(0);
          }

          int updateCount = 0;
          
          // Apply decay to each record
          for (final record in records) {
            final newWeeklyLoad = record.rollingWeeklyLoad * MuscleStimulus.weeklyDecayFactor;
            
            final updateResult = await muscleStimulusRepository.updateStimulusValues(
              id: record.id,
              dailyStimulus: record.dailyStimulus,
              rollingWeeklyLoad: newWeeklyLoad,
              lastSetTimestamp: record.lastSetTimestamp,
              lastSetStimulus: record.lastSetStimulus,
            );
            
            updateResult.fold(
              (failure) {
                _logError('Failed to update record ${record.id}: ${failure.message}');
              },
              (_) {
                updateCount++;
              },
            );
          }

          _logDebug('Applied decay to $updateCount records');
          return Right(updateCount);
        },
      );
    } catch (e) {
      _logError('Exception during date-specific decay: $e');
      return Left(UnexpectedFailure('Failed to apply decay for date: $e'));
    }
  }

  /// Check if decay should be applied today
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      final recordsResult = await muscleStimulusRepository.getAllStimulusForDate(todayStart);
      
      return recordsResult.fold(
        (failure) => Left(failure),
        (records) {
          // If no records exist for today, decay should be applied
          final shouldApply = records.isEmpty;
          
          _logDebug('Should apply decay: $shouldApply (${records.length} records found)');
          
          return Right(shouldApply);
        },
      );
    } catch (e) {
      return Left(UnexpectedFailure('Failed to check decay status: $e'));
    }
  }

  /// Get the decay factor being used
  double getDecayFactor() {
    return MuscleStimulus.weeklyDecayFactor;
  }

  /// Calculate what a value would be after decay

  double previewDecay(double currentLoad) {
    return currentLoad * MuscleStimulus.weeklyDecayFactor;
  }

  /// Estimate recovery time for a given stimulus value

  int estimateRecoveryDays(double currentLoad, {double? threshold}) {
    final targetThreshold = threshold ?? (currentLoad * 0.1);
    
    if (currentLoad <= targetThreshold) {
      return 0;
    }

    double remainingLoad = currentLoad;
    int days = 0;
    
    // Simulate daily decay until threshold reached
    // Cap at 30 days to prevent infinite loops
    while (remainingLoad > targetThreshold && days < 30) {
      remainingLoad *= MuscleStimulus.weeklyDecayFactor;
      days++;
    }
    
    return days;
  }

  // ==================== LOGGING HELPERS ====================

  void _logDebug(String message) {
    if (!EnvConfig.enableDebugLogs) return;
    debugPrint('[DAILY_DECAY] $message');
  }

  void _logError(String message) {
    if (!EnvConfig.enableDebugLogs) return;
    debugPrint('[DAILY_DECAY] ❌ ERROR: $message');
  }
}