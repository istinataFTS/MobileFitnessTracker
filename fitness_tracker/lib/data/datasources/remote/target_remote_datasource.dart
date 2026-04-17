import '../../../domain/entities/target.dart';

abstract class TargetRemoteDataSource {
  bool get isConfigured;

  Future<List<Target>> getAllTargets();

  Future<Target?> getTargetById(String id);

  Future<Target?> getTargetByTypeAndCategory(
    TargetType type,
    String categoryKey,
    TargetPeriod period,
  );

  Future<Target> upsertTarget(Target target);

  Future<void> deleteTarget({
    required String localId,
    String? serverId,
  });

  /// Returns all targets for [userId] whose `updated_at` is after [since].
  /// Pass [since] = null to fetch all targets (e.g. on initial re-login).
  Future<List<Target>> fetchSince({
    required String userId,
    DateTime? since,
  });
}