import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';

/// Single Source of Truth for muscle load data.
///
/// Both the 2D body map and the progress-screen muscle list must derive their
/// values from this service so they can never disagree.  The two consumers
/// differ only in *which* value they need:
///
/// - Body map → [getStimulusByMuscle] (continuous 0.0–N stimulus heat)
/// - Progress list → [getSetCountsByMuscle] (discrete set count per muscle)
abstract class MuscleLoadResolver {
  /// Returns total stimulus accumulated per muscle group in [start]–[end].
  ///
  /// Keys are normalised muscle-group identifiers (lowercase, trimmed).
  /// Only muscles touched by at least one set appear in the result map.
  Future<Either<Failure, Map<String, double>>> getStimulusByMuscle({
    required String userId,
    required DateTime start,
    required DateTime end,
  });

  /// Returns the number of sets that worked each muscle group in [start]–[end].
  ///
  /// A set is counted for a muscle when the exercise's factor for that muscle
  /// is > 0.  Keys are normalised muscle-group identifiers.
  Future<Either<Failure, Map<String, int>>> getSetCountsByMuscle({
    required String userId,
    required DateTime start,
    required DateTime end,
  });
}
