/// A thin abstraction over the wall clock.
///
/// Production code that depends on "now" (week-window math, decay curves,
/// cache timestamps, sync bookkeeping) should inject a [Clock] instead of
/// calling [DateTime.now] directly. Integration tests register a
/// `FakeClock` so assertions about time-windowed behaviour are
/// deterministic; production code registers [SystemClock].
///
/// Scope note (Phase 6.1): only the six hot call sites that drive
/// cross-layer integration tests are migrated to this abstraction.
/// Other `DateTime.now()` usages (widget timestamps, DB audit columns,
/// logging) are left untouched so the diff stays minimal. See the
/// Phase 6 plan §4 for the exact list.
abstract class Clock {
  const Clock();

  /// The current wall-clock time.
  DateTime now();
}
