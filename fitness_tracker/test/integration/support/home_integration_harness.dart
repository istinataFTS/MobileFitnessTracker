import 'package:fitness_tracker/core/time/clock.dart';

import 'fake_auth_remote_datasource.dart';
import 'fake_clock.dart';
import 'in_memory_db_harness.dart';
import 'recording_sync_orchestrator.dart';
import 'test_env.dart';

/// Top-level composition root for integration tests.
///
/// Bundles the pieces every cross-layer test needs — a seeded in-memory
/// database, a deterministic [Clock], a scriptable sync orchestrator, and
/// a scriptable auth data source — behind one `setUp` call. Later sub-
/// phases (6.2–6.6) will grow this harness with wired-up repositories,
/// use cases, and blocs; 6.1 only stands up the foundations.
///
/// Usage:
///
/// ```dart
/// late HomeIntegrationHarness harness;
///
/// setUp(() async {
///   harness = await HomeIntegrationHarness.create();
/// });
///
/// tearDown(() async {
///   await harness.dispose();
/// });
/// ```
///
/// Why a class and not free functions? Because [dispose] must close the
/// ffi database handle, and the test author should not have to remember
/// which of several `setUp` helpers owns the handle.
class HomeIntegrationHarness {
  HomeIntegrationHarness._({
    required this.db,
    required this.clock,
    required this.auth,
    required this.syncOrchestrator,
  });

  final InMemoryDbHarness db;
  final FakeClock clock;
  final FakeAuthRemoteDataSource auth;
  final RecordingSyncOrchestrator syncOrchestrator;

  /// Builds a fresh harness. Each call yields an independent database so
  /// parallel tests cannot leak rows into one another.
  static Future<HomeIntegrationHarness> create({
    DateTime? now,
    bool authConfigured = true,
  }) async {
    final InMemoryDbHarness db = await InMemoryDbHarness.open();
    final FakeClock clock = FakeClock(now ?? TestEnv.referenceNow);
    final FakeAuthRemoteDataSource auth = FakeAuthRemoteDataSource(
      isConfigured: authConfigured,
    );
    final RecordingSyncOrchestrator syncOrchestrator =
        RecordingSyncOrchestrator();

    return HomeIntegrationHarness._(
      db: db,
      clock: clock,
      auth: auth,
      syncOrchestrator: syncOrchestrator,
    );
  }

  /// Releases every owned resource. Tests MUST call this in `tearDown`.
  Future<void> dispose() async {
    await db.close();
  }
}
