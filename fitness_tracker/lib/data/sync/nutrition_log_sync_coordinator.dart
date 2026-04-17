import '../../domain/entities/nutrition_log.dart';

abstract class NutritionLogSyncCoordinator {
  bool get isRemoteSyncEnabled;

  Future<void> prepareForInitialCloudMigration(String userId);

  Future<void> persistAddedLog(NutritionLog log);

  Future<void> persistUpdatedLog(NutritionLog log);

  Future<void> persistDeletedLog(String id);

  Future<void> syncPendingChanges();

  /// Pulls remote nutrition logs modified after [since] into local storage.
  /// Pass [since] = null for a full pull (e.g. on initial re-login).
  Future<void> pullRemoteChanges({required String userId, DateTime? since});
}
