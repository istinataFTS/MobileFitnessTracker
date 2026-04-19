import '../../../domain/usecases/muscle_stimulus/rebuild_muscle_stimulus_from_workout_history.dart';
import '../../logging/app_logger.dart';
import '../post_sync_hook.dart';

/// Rebuilds the per-day `muscle_stimulus` projection for the current user
/// after new exercises or workout sets arrive from the cloud.
///
/// The 2D muscle map and fatigue widgets read exclusively from
/// `muscle_stimulus`; a freshly-pulled workout set stays invisible to the
/// UI until this projection is regenerated. The hook must run after
/// [MuscleFactorHealHook] so that any freshly-pulled exercises already
/// have factors by the time the projection is built.
///
/// The rebuild is scoped to [PostSyncContext.userId] — other profiles'
/// records are never touched.
class MuscleStimulusRebuildHook implements PostSyncHook {
  final RebuildMuscleStimulusFromWorkoutHistory rebuild;

  const MuscleStimulusRebuildHook({required this.rebuild});

  @override
  String get name => 'muscle_stimulus_rebuild';

  @override
  Set<String> get triggeringFeatures => const {'exercises', 'workout_sets'};

  @override
  Future<void> run(PostSyncContext context) async {
    final result = await rebuild(context.userId);

    result.fold(
      (failure) => AppLogger.warning(
        'Post-sync muscle stimulus rebuild failed: ${failure.message}',
        category: 'sync',
      ),
      (_) => AppLogger.info(
        'Post-sync muscle stimulus rebuild completed',
        category: 'sync',
      ),
    );
  }
}
