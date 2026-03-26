import '../../domain/entities/nutrition_log.dart';

abstract class NutritionLogSyncCoordinator {
  bool get isRemoteSyncEnabled;

  Future<void> prepareForInitialCloudMigration(String userId);

  Future<void> persistAddedLog(NutritionLog log);

  Future<void> persistUpdatedLog(NutritionLog log);

  Future<void> persistDeletedLog(String id);

  Future<void> syncPendingChanges();
}
