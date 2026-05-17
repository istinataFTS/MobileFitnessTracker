import '../enums/sync_trigger.dart';
import 'sync_feature.dart';

enum SyncRunStatus { completed, skipped, failed }

class SyncRunResult {
  final SyncRunStatus status;
  final SyncTrigger trigger;
  final String message;
  final List<SyncFeatureRunResult> featureResults;

  const SyncRunResult({
    required this.status,
    required this.trigger,
    required this.message,
    this.featureResults = const <SyncFeatureRunResult>[],
  });

  bool get isSuccess => status == SyncRunStatus.completed;
  bool get isSkipped => status == SyncRunStatus.skipped;
  bool get isFailure => status == SyncRunStatus.failed;
}

abstract class SyncOrchestrator {
  Future<SyncRunResult> run(SyncTrigger trigger);

  /// Broadcasts a [SyncRunResult] every time a sync run reaches a terminal
  /// state ([SyncRunStatus.completed] or [SyncRunStatus.failed]). Skipped
  /// runs are not emitted — nothing changed, so there is nothing for the UI
  /// to refresh. Listeners use this to invalidate cached, sync-derived
  /// state (e.g. the muscle-map projection) the moment a background sync
  /// finishes, instead of waiting for a cache TTL or a manual interaction.
  Stream<SyncRunResult> get onSyncCompleted;
}
