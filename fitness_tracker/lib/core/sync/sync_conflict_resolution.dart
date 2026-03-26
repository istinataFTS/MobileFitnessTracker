enum SyncConflictOutcome {
  remoteOnly,
  localOnly,
  localPendingDelete,
  localPendingUpload,
  localPendingUpdate,
  remoteNewer,
  localNewer,
  sameTimestampPreferLocal,
}

class SyncConflictResolution<T> {
  final T winner;
  final T? local;
  final T? remote;
  final SyncConflictOutcome outcome;

  const SyncConflictResolution({
    required this.winner,
    required this.outcome,
    this.local,
    this.remote,
  });

  bool get hasConflict => local != null && remote != null;

  bool get keepsLocalChange =>
      outcome == SyncConflictOutcome.localPendingDelete ||
      outcome == SyncConflictOutcome.localPendingUpload ||
      outcome == SyncConflictOutcome.localPendingUpdate ||
      outcome == SyncConflictOutcome.localNewer ||
      outcome == SyncConflictOutcome.sameTimestampPreferLocal;

  bool get appliesRemoteChange => outcome == SyncConflictOutcome.remoteNewer;
}
