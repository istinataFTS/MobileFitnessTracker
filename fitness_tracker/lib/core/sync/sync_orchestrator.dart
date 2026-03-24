import '../enums/sync_trigger.dart';
import 'sync_feature.dart';

enum SyncRunStatus {
  completed,
  skipped,
  failed,
}

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
}