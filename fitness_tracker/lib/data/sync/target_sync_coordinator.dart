import '../../domain/entities/target.dart';

abstract class TargetSyncCoordinator {
  bool get isRemoteSyncEnabled;

  Future<void> prepareForInitialCloudMigration(String userId);

  Future<void> persistAddedTarget(Target target);

  Future<void> persistUpdatedTarget(Target target);

  Future<void> persistDeletedTarget(String id);

  Future<void> syncPendingChanges();

  /// Pulls remote targets modified after [since] into local storage.
  /// Pass [since] = null for a full pull (e.g. on initial re-login).
  Future<void> pullRemoteChanges({required String userId, DateTime? since});
}
