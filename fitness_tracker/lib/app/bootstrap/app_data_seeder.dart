import 'package:flutter/foundation.dart' show debugPrint;

import '../../config/env_config.dart';
import '../../domain/repositories/app_session_repository.dart';
import '../../domain/usecases/exercises/seed_exercises.dart';
import '../../domain/usecases/muscle_factors/seed_exercise_factors.dart';
import '../../domain/usecases/muscle_stimulus/rebuild_muscle_stimulus_from_workout_history.dart';
import '../../injection/injection_container.dart' as di;

class AppDataSeeder {
  const AppDataSeeder();

  Future<void> seedIfEnabled() async {
    if (!EnvConfig.seedDefaultData) {
      return;
    }

    debugPrint('Seeding database...');
    final seedStart = DateTime.now();

    final seedExercises = di.sl<SeedExercises>();
    final exercisesResult = await seedExercises();

    await exercisesResult.fold(
      (failure) async {
        debugPrint('⚠️ Exercise seeding failed: ${failure.message}');
      },
      (exerciseCount) async {
        final exerciseDuration = DateTime.now().difference(seedStart);
        debugPrint(
          '✅ Seeded $exerciseCount exercises in: ${exerciseDuration.inMilliseconds}ms',
        );

        final factorSeedStart = DateTime.now();
        final seedFactors = di.sl<SeedExerciseFactors>();
        final factorsResult = await seedFactors();

        await factorsResult.fold(
          (failure) async {
            debugPrint(
              '⚠️ Muscle factor seeding failed: ${failure.message}',
            );
          },
          (factorCount) async {
            final factorDuration =
                DateTime.now().difference(factorSeedStart);
            debugPrint(
              '✅ Seeded $factorCount muscle factors in: ${factorDuration.inMilliseconds}ms',
            );

            if (factorCount > 0) {
              // Factors were freshly seeded (DB migration cleared the old ones).
              // Rebuild muscle stimulus history so past workout sets are reflected
              // in the fatigue map and weekly targets immediately on first launch.
              debugPrint('🔄 Rebuilding muscle stimulus from workout history...');
              final rebuildStart = DateTime.now();
              final sessionRepo = di.sl<AppSessionRepository>();
              final sessionResult = await sessionRepo.getCurrentSession();
              final userId = sessionResult.fold(
                (_) => '',
                (session) => session.user?.id ?? '',
              );
              final rebuild =
                  di.sl<RebuildMuscleStimulusFromWorkoutHistory>();
              final rebuildResult = await rebuild(userId);
              final rebuildDuration =
                  DateTime.now().difference(rebuildStart);
              rebuildResult.fold(
                (failure) {
                  debugPrint(
                    '⚠️ Muscle stimulus rebuild failed: ${failure.message}',
                  );
                },
                (_) {
                  debugPrint(
                    '✅ Muscle stimulus rebuilt in: ${rebuildDuration.inMilliseconds}ms',
                  );
                },
              );
            }
          },
        );
      },
    );

    final totalSeedDuration = DateTime.now().difference(seedStart);
    debugPrint(
      '✅ Database seeding completed in: ${totalSeedDuration.inMilliseconds}ms',
    );
  }
}