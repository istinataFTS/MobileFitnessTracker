import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/logging/app_logger.dart';
import '../entities/muscle_factor.dart';
import '../entities/stimulus_calculation_rules.dart';
import '../repositories/muscle_factor_repository.dart';
import '../repositories/workout_set_repository.dart';
import 'muscle_load_resolver.dart';

class MuscleLoadResolverImpl implements MuscleLoadResolver {
  const MuscleLoadResolverImpl({
    required this.workoutSetRepository,
    required this.muscleFactorRepository,
  });

  final WorkoutSetRepository workoutSetRepository;
  final MuscleFactorRepository muscleFactorRepository;

  @override
  Future<Either<Failure, Map<String, double>>> getStimulusByMuscle({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final setsResult = await workoutSetRepository.getSetsByDateRange(start, end);
      return await setsResult.fold(
        (f) async => Left(f),
        (allSets) async {
          final userSets = allSets.where((s) => s.ownerUserId == userId).toList();
          if (userSets.isEmpty) return const Right({});

          final factorCache = await _loadFactors(userSets.map((s) => s.exerciseId).toSet());

          final stimulus = <String, double>{};
          for (final set in userSets) {
            final factors = factorCache[set.exerciseId];
            if (factors == null || factors.isEmpty) continue;
            for (final factor in factors) {
              if (factor.factor <= 0) continue;
              final value = StimulusCalculationRules.calculateSetStimulus(
                sets: 1,
                intensity: set.intensity,
                exerciseFactor: factor.factor,
              );
              stimulus[factor.muscleGroup] = (stimulus[factor.muscleGroup] ?? 0.0) + value;
            }
          }
          return Right(stimulus);
        },
      );
    } catch (e) {
      AppLogger.error('MuscleLoadResolver.getStimulusByMuscle failed: $e', category: 'resolver');
      return Left(UnexpectedFailure('getStimulusByMuscle failed: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getSetCountsByMuscle({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final setsResult = await workoutSetRepository.getSetsByDateRange(start, end);
      return await setsResult.fold(
        (f) async => Left(f),
        (allSets) async {
          final userSets = allSets.where((s) => s.ownerUserId == userId).toList();
          if (userSets.isEmpty) return const Right({});

          final factorCache = await _loadFactors(userSets.map((s) => s.exerciseId).toSet());

          final counts = <String, int>{};
          for (final set in userSets) {
            final factors = factorCache[set.exerciseId];
            if (factors == null || factors.isEmpty) continue;
            for (final factor in factors) {
              if (factor.factor <= 0) continue;
              counts[factor.muscleGroup] = (counts[factor.muscleGroup] ?? 0) + 1;
            }
          }
          return Right(counts);
        },
      );
    } catch (e) {
      AppLogger.error('MuscleLoadResolver.getSetCountsByMuscle failed: $e', category: 'resolver');
      return Left(UnexpectedFailure('getSetCountsByMuscle failed: $e'));
    }
  }

  /// Batch-loads factors for every exercise in [exerciseIds].
  ///
  /// One repo call per unique exerciseId; exercises that return an error or
  /// empty list are stored as an empty list so callers skip them safely.
  Future<Map<String, List<MuscleFactor>>> _loadFactors(
    Set<String> exerciseIds,
  ) async {
    final cache = <String, List<MuscleFactor>>{};
    for (final id in exerciseIds) {
      final result = await muscleFactorRepository.getFactorsForExercise(id);
      cache[id] = result.fold((_) => const [], (factors) => factors);
    }
    return cache;
  }
}
