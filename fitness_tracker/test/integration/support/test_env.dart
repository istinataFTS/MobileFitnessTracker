/// Environment-variable facade for the integration-test harness.
///
/// All `String.fromEnvironment` calls in the integration suite are funnelled
/// through this class so overriding any of them at `flutter test` time is a
/// single `--dart-define` away:
///
///     flutter test --dart-define=INTEGRATION_DB_MODE=file \
///                  --dart-define=INTEGRATION_TIMEOUT_MS=30000 \
///                  test/integration/
///
/// What deliberately does NOT live here (and why):
///
/// - The **reference clock** `DateTime(2026, 4, 20, 12, 0)` — integration
///   assertions pin specific week boundaries and decay windows; a varying
///   wall-clock would make test failures irreproducible across machines.
/// - **Muscle-group slugs** (`chest`, `lats`, `quads`, …) — they are
///   part of the domain contract defined in
///   `lib/core/constants/muscle_stimulus_constants.dart`; overriding them
///   would break the presentation mapper's asset resolution.
/// - **Test-fixture user ids** (`user-a`, `user-b`) — internal to tests,
///   not environment-specific; env-izing them adds noise without value.
/// - **Domain enum values** (`SyncTrigger.initialSignIn`, etc.) — domain,
///   not environment.
class TestEnv {
  const TestEnv._();

  /// `memory` (default) keeps the integration DB in RAM for speed and
  /// isolation; set `file` when debugging a failing test with
  /// `sqlite3` CLI introspection.
  static const String dbMode = String.fromEnvironment(
    'INTEGRATION_DB_MODE',
    defaultValue: 'memory',
  );

  /// Seed for any randomised fixture generation (e.g. shuffled set orders).
  /// Integration tests are otherwise deterministic; this is a knob for
  /// quickly varying order during local flakiness investigation.
  static const int fixtureSeed = int.fromEnvironment(
    'INTEGRATION_TEST_SEED',
    defaultValue: 42,
  );

  /// Per-test timeout in milliseconds. CI environments with slow I/O can
  /// bump this without touching source.
  static const int timeoutMs = int.fromEnvironment(
    'INTEGRATION_TIMEOUT_MS',
    defaultValue: 10000,
  );

  /// Suppresses info/debug logging noise in CI without touching production
  /// logging gates. Honoured by [configureLogging] on the harness.
  static const String logLevel = String.fromEnvironment(
    'INTEGRATION_LOG_LEVEL',
    defaultValue: 'warning',
  );

  /// Canonical "now" used across the integration suite. Lives here so one
  /// test cannot accidentally diverge from another. Deliberately not
  /// overridable via env — see class-level docs for rationale.
  static final DateTime referenceNow = DateTime(2026, 4, 20, 12, 0);
}
