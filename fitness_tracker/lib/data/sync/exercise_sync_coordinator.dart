import '../../domain/entities/exercise.dart';

abstract class ExerciseSyncCoordinator {
  bool get isRemoteSyncEnabled;

  Future<void> prepareForInitialCloudMigration(String userId);

  Future<void> persistAddedExercise(Exercise exercise);

  Future<void> persistUpdatedExercise(Exercise exercise);

  Future<void> persistDeletedExercise(String id);

  Future<void> syncPendingChanges();

  /// Pulls remote exercises modified after [since] into local storage.
  /// Pass [since] = null for a full pull (e.g. on initial re-login).
  Future<void> pullRemoteChanges({required String userId, DateTime? since});
}
