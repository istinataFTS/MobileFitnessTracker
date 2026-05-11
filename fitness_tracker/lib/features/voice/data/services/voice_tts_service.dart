/// Abstract port for device-native text-to-speech playback.
///
/// C-4 provides the `flutter_tts` implementation
/// ([FlutterTtsVoiceTtsService]). Tests can swap in a [NoopVoiceTtsService]
/// or a hand-rolled fake without touching the bloc.
abstract class VoiceTtsService {
  /// Speak [text] using the device TTS engine at the currently configured
  /// volume and speech rate. Completes when speech finishes or is
  /// interrupted by a subsequent [stop] call.
  Future<void> speak(String text);

  /// Interrupt any in-progress speech immediately.
  Future<void> stop();

  /// Set playback volume (0.0 – 1.0). Applied before the next [speak] call.
  Future<void> setVolume(double volume);

  /// Set speech rate (0.5 – 2.0; 1.0 = normal). Applied before the next
  /// [speak] call.
  Future<void> setSpeechRate(double rate);
}
