import '../../domain/entities/exercise.dart';

abstract class ExerciseSyncCoordinator {
  bool get isRemoteSyncEnabled;

  Future<void> prepareForInitialCloudMigration(String userId);

  Future<void> persistAddedExercise(Exercise exercise);

  Future<void> persistUpdatedExercise(Exercise exercise);

  Future<void> persistDeletedExercise(String id);

  Future<void> syncPendingChanges();
}
