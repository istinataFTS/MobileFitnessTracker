import 'clock.dart';

/// Production [Clock] implementation backed by [DateTime.now].
///
/// Registered as a lazy singleton in the core DI module. Tests should
/// register a fake clock via the `registerOverrides` hook on
/// `init(...)` rather than depending on this class directly.
class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
