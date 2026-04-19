import '../../../domain/usecases/muscle_factors/seed_exercise_factors.dart';
import '../../logging/app_logger.dart';
import '../post_sync_hook.dart';

/// Ensures every exercise in local storage — including those freshly
/// pulled from the cloud — has its biomechanical muscle factor rows
/// populated.
///
/// Without this hook, exercises whose IDs arrive from Supabase with no
/// matching pre-seeded factors would render silently on the 2D muscle
/// map: every workout set logged against them would emit a
/// `[WARNING][stimulus] No muscle factors for exerciseId=…` and leave
/// the map blank.
///
/// The underlying [SeedExerciseFactors] use case is per-exercise
/// idempotent — it performs a single `getAllFactors` query and only
/// inserts rows for exercises that currently have none, so running this
/// after every sync is cheap in the steady state.
class MuscleFactorHealHook implements PostSyncHook {
  final SeedExerciseFactors seedExerciseFactors;

  const MuscleFactorHealHook({required this.seedExerciseFactors});

  @override
  String get name => 'muscle_factor_heal';

  @override
  Set<String> get triggeringFeatures => const {'exercises'};

  @override
  Future<void> run(PostSyncContext context) async {
    final result = await seedExerciseFactors(allowHealingWhenEmpty: true);

    result.fold(
      (failure) => AppLogger.warning(
        'Post-sync muscle factor heal failed: ${failure.message}',
        category: 'sync',
      ),
      (healedCount) {
        if (healedCount > 0) {
          AppLogger.info(
            'Post-sync muscle factor heal inserted $healedCount factor rows',
            category: 'sync',
          );
        }
      },
    );
  }
}
