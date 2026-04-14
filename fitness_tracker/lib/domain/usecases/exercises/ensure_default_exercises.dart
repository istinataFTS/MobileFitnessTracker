import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/failures.dart';
import '../../repositories/app_session_repository.dart';
import '../muscle_factors/seed_exercise_factors.dart';
import 'seed_exercises.dart';

/// Ensures the current user always has a set of default exercises available.
///
/// This is the per-user counterpart to the global [AppDataSeeder] that runs
/// at bootstrap. It is designed to be called whenever the [ExerciseBloc]
/// finds an empty exercise list after a successful load, acting as a
/// safety-net for these scenarios:
///
/// - A new device/fresh install where the initial cloud sync fetched a user
///   account that has no exercises in the cloud.
/// - A second user logging in on a shared device after the first user's
///   cloud migration claimed the system (null-owner) exercises.
///
/// **Idempotent**: if the user already has at least one visible exercise
/// (system-owned or user-owned), the method returns immediately without
/// touching the database.
///
/// **Factor seeding**: when exercises are freshly inserted the muscle-factor
/// seeding is also triggered, so the fatigue map and stimulus tracking work
/// for the new exercises right away.
class EnsureDefaultExercises {
  const EnsureDefaultExercises({
    required this.appSessionRepository,
    required this.seedExercises,
    required this.seedExerciseFactors,
  });

  final AppSessionRepository appSessionRepository;
  final SeedExercises seedExercises;
  final SeedExerciseFactors seedExerciseFactors;

  /// Ensures the current user has default exercises, seeding them if needed.
  ///
  /// Returns the number of exercises that were seeded (0 means the user
  /// already had exercises and no action was taken).
  Future<Either<Failure, int>> call() async {
    try {
      // Resolve the current user id (null for guest sessions).
      final sessionResult = await appSessionRepository.getCurrentSession();
      final String? userId = sessionResult.fold(
        (_) => null,
        (session) => session.user?.id,
      );

      debugPrint(
        '[EnsureDefaultExercises] Checking exercises for '
        '${userId != null ? 'user $userId' : 'guest session'}',
      );

      // Delegate to SeedExercises — it checks internally whether exercises
      // already exist (user-scoped: NULL-owner + user-owned) and skips if
      // there are any. We pass the userId so new exercises are owned by this
      // user rather than being shared NULL-owner exercises.
      final seedResult = await seedExercises(ownerUserId: userId);

      return await seedResult.fold(
        (failure) async {
          debugPrint(
            '[EnsureDefaultExercises] Exercise seeding failed: '
            '${failure.message}',
          );
          return Left(failure);
        },
        (seededCount) async {
          if (seededCount == 0) {
            // User already had exercises — nothing more to do.
            debugPrint(
              '[EnsureDefaultExercises] User already has exercises, skipping.',
            );
            return const Right(0);
          }

          debugPrint(
            '[EnsureDefaultExercises] Seeded $seededCount exercises. '
            'Now seeding muscle factors...',
          );

          // Seed muscle factors so stimulus / fatigue tracking works for the
          // freshly inserted exercises.
          final factorsResult = await seedExerciseFactors();
          factorsResult.fold(
            (failure) => debugPrint(
              '[EnsureDefaultExercises] Factor seeding failed: '
              '${failure.message}',
            ),
            (factorCount) => debugPrint(
              '[EnsureDefaultExercises] Seeded $factorCount muscle factors.',
            ),
          );

          return Right(seededCount);
        },
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[EnsureDefaultExercises] Unexpected error: $e\n$stackTrace',
      );
      return Left(DatabaseFailure('EnsureDefaultExercises failed: $e'));
    }
  }
}
