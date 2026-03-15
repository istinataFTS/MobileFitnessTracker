import '../../domain/entities/target.dart';

abstract class TargetSyncCoordinator {
  bool get isRemoteSyncEnabled;

  Future<void> persistAddedTarget(Target target);

  Future<void> persistUpdatedTarget(Target target);

  Future<void> persistDeletedTarget(String id);

  Future<void> syncPendingChanges();
}