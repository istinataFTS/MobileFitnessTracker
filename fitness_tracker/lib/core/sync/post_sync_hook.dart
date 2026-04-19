import '../enums/sync_trigger.dart';

/// Information handed to every [PostSyncHook] when it runs.
class PostSyncContext {
  /// The authenticated user whose data just synced.
  final String userId;

  /// Names of features whose remote state was pulled in this run.
  /// Hooks use this to decide whether their work is relevant.
  final Set<String> pulledFeatures;

  /// The trigger that initiated this sync run.
  final SyncTrigger trigger;

  const PostSyncContext({
    required this.userId,
    required this.pulledFeatures,
    required this.trigger,
  });
}

/// A side-effect that runs after a successful sync run, once per run.
///
/// Hooks exist to keep derived local projections (muscle factors, muscle
/// stimulus, …) consistent with the authoritative tables the sync layer
/// just refreshed. Keeping them out of the sync coordinators themselves
/// preserves the single-responsibility of each coordinator and makes the
/// cross-entity dependency explicit.
///
/// Contract:
/// * Hooks are invoked in registration order, sequentially.
/// * Each hook declares the feature names whose pull makes its work
///   necessary via [triggeringFeatures]; an empty set means "always run".
/// * Implementations MUST be idempotent — a hook may run many times per
///   session (e.g. on every sync trigger).
/// * Hooks MUST NOT throw. Failures should be caught and logged; the
///   orchestrator treats a hook failure as non-fatal so one misbehaving
///   hook cannot mark an otherwise-successful sync as failed.
abstract class PostSyncHook {
  /// Stable identifier used in logs and tests.
  String get name;

  /// Feature names whose pull must appear in [PostSyncContext.pulledFeatures]
  /// for this hook to have work to do. An empty set means the hook runs on
  /// every successful sync.
  Set<String> get triggeringFeatures;

  Future<void> run(PostSyncContext context);
}
