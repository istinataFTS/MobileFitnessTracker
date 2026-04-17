import '../../domain/entities/workout_set.dart';

abstract class WorkoutSetSyncCoordinator {
  bool get isRemoteSyncEnabled;

  Future<void> prepareForInitialCloudMigration(String userId);

  Future<void> persistAddedSet(WorkoutSet set);

  Future<void> persistUpdatedSet(WorkoutSet set);

  Future<void> persistDeletedSet(String id);

  Future<void> syncPendingChanges();

  /// Pulls remote workout sets modified after [since] into local storage.
  /// Pass [since] = null for a full pull (e.g. on initial re-login).
  Future<void> pullRemoteChanges({required String userId, DateTime? since});
}
