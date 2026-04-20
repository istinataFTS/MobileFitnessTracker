import 'package:fitness_tracker/core/sync/sync_feature.dart';

/// A [SyncFeature] whose push/pull runners append to a shared [callLog]
/// instead of doing real work, and optionally throw a configured error.
///
/// Integration tests use this to assert sync-orchestration contracts
/// (ordering, gating, error propagation) without dragging in real
/// datasource wiring.
class RecordingSyncFeature {
  RecordingSyncFeature({
    required this.name,
    required this.callLog,
    this.onPush,
    this.onPull,
    this.pushError,
    this.pullError,
  });

  final String name;

  /// Ordered log of every runner invocation across every recording
  /// feature sharing this list. Entries are `"<featureName>:push"` and
  /// `"<featureName>:pull"` so order assertions are string-comparison.
  final List<String> callLog;

  /// Optional side-effect to run *before* recording the push, e.g. to
  /// insert canned "remote" rows directly into the in-memory DB so the
  /// later pull step has something to find.
  final Future<void> Function()? onPush;

  /// Optional side-effect to run *before* recording the pull. Same
  /// intent as [onPush] — hand-seed the local DB to stand in for a
  /// real remote-to-local copy.
  final Future<void> Function(String userId, DateTime? since)? onPull;

  /// When non-null, the push runner records its call then throws this
  /// error; used to exercise the "one feature failing does not block
  /// others" invariant.
  final Object? pushError;
  final Object? pullError;

  /// Converts this recorder into the production [SyncFeature] shape
  /// expected by `SyncOrchestratorImpl`.
  SyncFeature toSyncFeature() {
    return SyncFeature(
      name: name,
      syncPendingChanges: () async {
        if (onPush != null) await onPush!();
        callLog.add('$name:push');
        if (pushError != null) throw pushError!;
      },
      pullRemoteChanges: (String userId, DateTime? since) async {
        if (onPull != null) await onPull!(userId, since);
        callLog.add('$name:pull');
        if (pullError != null) throw pullError!;
      },
    );
  }
}
