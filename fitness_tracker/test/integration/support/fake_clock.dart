import 'package:fitness_tracker/core/time/clock.dart';

/// Deterministic [Clock] for integration tests.
///
/// Starts at a fixed [DateTime] and only advances when the test explicitly
/// calls [advance] / [setTo]. This guarantees that week-window math,
/// decay curves, and cache-age checks see the same "now" regardless of
/// wall-clock drift, test interleaving, or machine speed.
class FakeClock extends Clock {
  FakeClock(DateTime initial) : _current = initial;

  DateTime _current;

  @override
  DateTime now() => _current;

  /// Move the clock forward by [delta]. Negative durations are rejected
  /// so tests cannot accidentally rewind time and mask a bug.
  void advance(Duration delta) {
    if (delta.isNegative) {
      throw ArgumentError.value(
        delta,
        'delta',
        'FakeClock.advance requires a non-negative duration',
      );
    }
    _current = _current.add(delta);
  }

  /// Jump directly to [target]. Useful for simulating a full week rollover
  /// without computing deltas. Rejects targets earlier than the current
  /// reading for the same reason [advance] rejects negatives.
  void setTo(DateTime target) {
    if (target.isBefore(_current)) {
      throw ArgumentError.value(
        target,
        'target',
        'FakeClock.setTo cannot move the clock backwards '
            '(current=$_current, target=$target)',
      );
    }
    _current = target;
  }
}
