import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../repositories/voice_repository.dart';

class TranscribeAudio {
  const TranscribeAudio(this._repository);

  final VoiceRepository _repository;

  Future<Either<Failure, String>> call({
    required List<int> audioBytes,
    required String sessionId,
    required String mimeType,
    required bool sessionLoggingEnabled,
  }) =>
      _repository.transcribe(
        audioBytes: audioBytes,
        sessionId: sessionId,
        mimeType: mimeType,
        sessionLoggingEnabled: sessionLoggingEnabled,
      );
}
