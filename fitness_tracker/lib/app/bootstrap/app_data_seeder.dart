import 'package:flutter/foundation.dart' show debugPrint;

import '../../config/env_config.dart';
import '../../domain/usecases/exercises/seed_exercises.dart';
import '../../domain/usecases/muscle_factors/seed_exercise_factors.dart';
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

        factorsResult.fold(
          (failure) {
            debugPrint(
              '⚠️ Muscle factor seeding failed: ${failure.message}',
            );
          },
          (factorCount) {
            final factorDuration =
                DateTime.now().difference(factorSeedStart);
            debugPrint(
              '✅ Seeded $factorCount muscle factors in: ${factorDuration.inMilliseconds}ms',
            );
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