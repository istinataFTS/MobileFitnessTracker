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
}