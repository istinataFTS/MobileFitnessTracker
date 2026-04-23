import '../../../domain/usecases/muscle_stimulus/rebuild_muscle_stimulus_from_workout_history.dart';
import '../../logging/app_logger.dart';
import '../post_sync_hook.dart';

/// Rebuilds the per-day `muscle_stimulus` projection for the current user
/// after every successful sync run.
///
/// The 2D muscle map and fatigue widgets read exclusively from
/// `muscle_stimulus`; a freshly-pulled workout set stays invisible to the
/// UI until this projection is regenerated. The hook must run after
/// [MuscleFactorHealHook] so that any freshly-pulled exercises already
/// have factors by the time the projection is built.
///
/// Why always-run (no [triggeringFeatures] gating): stale rows can end up
/// in `muscle_stimulus` from prior sessions (historic bug where factors
/// were wiped by `INSERT OR REPLACE` cascades, or rows owned by a
/// previous account). Gating the rebuild on "exercises or workout_sets
/// was pulled" meant a clean sync with no remote deltas could not clean
/// them up — users saw phantom muscles (e.g. lats highlighted despite
/// never training lats) until a remote change forced a rebuild. The
/// underlying use case wipes-then-rebuilds scoped to
/// [PostSyncContext.userId], so running it every sync is idempotent and
/// cheap; other profiles' records are never touched.
class MuscleStimulusRebuildHook implements PostSyncHook {
  final RebuildMuscleStimulusFromWorkoutHistory rebuild;

  const MuscleStimulusRebuildHook({required this.rebuild});

  @override
  String get name => 'muscle_stimulus_rebuild';

  @override
  Set<String> get triggeringFeatures => const <String>{};

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
