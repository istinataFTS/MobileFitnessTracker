/// Error categories surfaced by [VoiceSttService].
enum VoiceSttErrorKind {
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,
  noSpeech,
  network,
  unknown,
}

/// A single STT result emitted on the [VoiceSttService.listen] stream.
class VoiceSttResult {
  const VoiceSttResult({
    required this.transcript,
    required this.isFinal,
  });

  /// The recognised text so far.
  final String transcript;

  /// True on the final result; false for live partial updates.
  final bool isFinal;
}

/// Thrown on the [VoiceSttService.listen] stream when recognition fails.
class VoiceSttException implements Exception {
  const VoiceSttException(this.kind, [this.message]);

  final VoiceSttErrorKind kind;
  final String? message;

  @override
  String toString() => 'VoiceSttException($kind, $message)';
}

/// Abstract port for device-native speech-to-text.
///
/// C-4 provides the `speech_to_text` implementation
/// ([SpeechToTextVoiceSttService]). The [VoiceBloc] interacts exclusively
/// through this interface so tests can drive it with a simple fake.
abstract class VoiceSttService {
  /// One-time setup. Calling again after successful init is a no-op.
  Future<void> initialize();

  /// Whether the STT engine is available after [initialize].
  bool get isAvailable;

  /// Begin listening and return a stream of partial + final results.
  ///
  /// The stream emits [VoiceSttResult] objects with [isFinal] == false
  /// for live transcripts, then a final one with [isFinal] == true.
  /// On error, the stream adds a [VoiceSttException] via `onError`.
  Stream<VoiceSttResult> listen();

  /// Stop listening. Any pending partial result is discarded.
  Future<void> stop();
}
