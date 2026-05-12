import 'package:wakelock_plus/wakelock_plus.dart';

/// Thin injectable wrapper around [WakelockPlus] static calls.
///
/// Injecting this interface into [VoiceBloc] instead of calling
/// [WakelockPlus] directly keeps the bloc fully testable — tests
/// provide a mock without needing PowerMock-style reflection.
abstract interface class WakelockService {
  Future<void> enable();
  Future<void> disable();
}

class DefaultWakelockService implements WakelockService {
  const DefaultWakelockService();

  @override
  Future<void> enable() => WakelockPlus.enable();

  @override
  Future<void> disable() => WakelockPlus.disable();
}
