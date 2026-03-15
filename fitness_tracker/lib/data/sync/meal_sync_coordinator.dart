import '../../domain/entities/meal.dart';

abstract class MealSyncCoordinator {
  bool get isRemoteSyncEnabled;

  Future<void> persistAddedMeal(Meal meal);

  Future<void> persistUpdatedMeal(Meal meal);

  Future<void> persistDeletedMeal(String id);

  Future<void> syncPendingChanges();
}