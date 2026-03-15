import '../../../domain/entities/target.dart';
import 'target_remote_datasource.dart';

class NoopTargetRemoteDataSource implements TargetRemoteDataSource {
  const NoopTargetRemoteDataSource();

  @override
  bool get isConfigured => false;

  @override
  Future<List<Target>> getAllTargets() async {
    return const <Target>[];
  }

  @override
  Future<Target?> getTargetById(String id) async {
    return null;
  }

  @override
  Future<Target?> getTargetByTypeAndCategory(
    TargetType type,
    String categoryKey,
    TargetPeriod period,
  ) async {
    return null;
  }

  @override
  Future<Target> upsertTarget(Target target) async {
    return target;
  }

  @override
  Future<void> deleteTarget({
    required String localId,
    String? serverId,
  }) async {}
}