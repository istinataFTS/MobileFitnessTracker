typedef InitialCloudMigrationRunner = Future<void> Function(String userId);

class InitialCloudMigrationStep {
  final String key;
  final InitialCloudMigrationRunner run;

  const InitialCloudMigrationStep({
    required this.key,
    required this.run,
  });
}