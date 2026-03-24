import '../../domain/entities/initial_cloud_migration_state.dart';

enum InitialCloudMigrationStatus {
  skipped,
  inProgress,
  completed,
  failed,
}

class InitialCloudMigrationResult {
  final InitialCloudMigrationStatus status;
  final String message;
  final InitialCloudMigrationState? state;

  const InitialCloudMigrationResult({
    required this.status,
    required this.message,
    this.state,
  });
}

abstract class InitialCloudMigrationCoordinator {
  Future<InitialCloudMigrationResult> runIfRequired();
}