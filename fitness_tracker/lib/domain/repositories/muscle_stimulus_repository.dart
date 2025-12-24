import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/muscle_stimulus.dart';

/// Repository interface for MuscleStimulus operations
abstract class MuscleStimulusRepository {
  /// Get stimulus for a specific muscle on a specific date
  Future<Either<Failure, MuscleStimulus?>> getStimulusByMuscleAndDate({
    required String muscleGroup,
    required DateTime date,
  });
  
  /// Get all stimulus records for a muscle within a date range
  Future<Either<Failure, List<MuscleStimulus>>> getStimulusByDateRange({
    required String muscleGroup,
    required DateTime startDate,
    required DateTime endDate,
  });
  
  /// Get today's stimulus for a specific muscle
  Future<Either<Failure, MuscleStimulus?>> getTodayStimulus(String muscleGroup);
  
  /// Get all stimulus records for all muscles on a specific date
  Future<Either<Failure, List<MuscleStimulus>>> getAllStimulusForDate(DateTime date);
  
  /// Insert or update a stimulus record
  Future<Either<Failure, void>> upsertStimulus(MuscleStimulus stimulus);
  
  /// Update stimulus values for an existing record
  Future<Either<Failure, void>> updateStimulusValues({
    required String id,
    required double dailyStimulus,
    required double rollingWeeklyLoad,
    int? lastSetTimestamp,
    double? lastSetStimulus,
  });
  
  /// Apply daily decay to all muscle groups
  Future<Either<Failure, void>> applyDailyDecayToAll();
  
  /// Get maximum daily stimulus ever recorded for a muscle
  Future<Either<Failure, double>> getMaxStimulusForMuscle(String muscleGroup);
  
  /// Delete stimulus records older than a certain date
  Future<Either<Failure, void>> deleteOlderThan(DateTime date);
  
  /// Clear all stimulus records
  Future<Either<Failure, void>> clearAllStimulus();
}