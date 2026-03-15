import '../../../domain/entities/workout_set.dart';

abstract class WorkoutSetRemoteDataSource {
  bool get isConfigured;

  Future<List<WorkoutSet>> getAllSets();

  Future<WorkoutSet?> getSetById(String id);

  Future<WorkoutSet> upsertSet(WorkoutSet set);

  Future<void> deleteSet({
    required String localId,
    String? serverId,
  });
}