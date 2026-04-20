import 'package:fitness_tracker/core/enums/sync_trigger.dart';
import 'package:fitness_tracker/core/sync/sync_orchestrator.dart';

/// A [SyncOrchestrator] that records every [run] invocation and returns a
/// queue of canned [SyncRunResult]s.
///
/// Integration tests use this when they only care that a use case (e.g.
/// sign-in, manual refresh) dispatches the correct [SyncTrigger] and reacts
/// to its [SyncRunResult] — not how the real orchestrator would have
/// behaved. Use [RecordingSyncFeature] + the real [SyncOrchestratorImpl]
/// instead when you want to exercise orchestration itself.
///
/// The default result (when the queue is empty) is a [SyncRunStatus.skipped]
/// with message `"no canned result queued"` so a missing `enqueue` call
/// surfaces obviously in assertions rather than silently succeeding.
class RecordingSyncOrchestrator implements SyncOrchestrator {
  RecordingSyncOrchestrator();

  final List<SyncTrigger> triggers = <SyncTrigger>[];
  final List<SyncRunResult> _queuedResults = <SyncRunResult>[];

  /// Appends a [SyncRunResult] to the queue. The next [run] call will pop
  /// and return this result.
  void enqueue(SyncRunResult result) {
    _queuedResults.add(result);
  }

  /// Convenience for the common case: enqueue a plain completed run.
  void enqueueCompleted(SyncTrigger trigger, {String message = 'ok'}) {
    enqueue(
      SyncRunResult(
        status: SyncRunStatus.completed,
        trigger: trigger,
        message: message,
      ),
    );
  }

  @override
  Future<SyncRunResult> run(SyncTrigger trigger) async {
    triggers.add(trigger);
    if (_queuedResults.isNotEmpty) {
      return _queuedResults.removeAt(0);
    }
    return SyncRunResult(
      status: SyncRunStatus.skipped,
      trigger: trigger,
      message: 'no canned result queued',
    );
  }
}
