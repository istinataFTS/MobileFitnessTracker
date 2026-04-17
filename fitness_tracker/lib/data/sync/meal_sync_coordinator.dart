import '../../domain/entities/meal.dart';

abstract class MealSyncCoordinator {
  bool get isRemoteSyncEnabled;

  Future<void> prepareForInitialCloudMigration(String userId);

  Future<void> persistAddedMeal(Meal meal);

  Future<void> persistUpdatedMeal(Meal meal);

  Future<void> persistDeletedMeal(String id);

  Future<void> syncPendingChanges();

  /// Pulls remote meals modified after [since] into local storage.
  /// Pass [since] = null for a full pull (e.g. on initial re-login).
  Future<void> pullRemoteChanges({required String userId, DateTime? since});
}
