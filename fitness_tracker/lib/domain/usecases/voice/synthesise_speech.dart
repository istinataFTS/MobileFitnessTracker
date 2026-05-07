import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/voice_settings.dart';
import '../../repositories/voice_repository.dart';

class SynthesizeSpeech {
  const SynthesizeSpeech(this._repository);

  final VoiceRepository _repository;

  Future<Either<Failure, List<int>>> call({
    required String text,
    required String sessionId,
    required TtsVoice voice,
    required bool sessionLoggingEnabled,
  }) =>
      _repository.synthesise(
        text: text,
        sessionId: sessionId,
        voice: voice,
        sessionLoggingEnabled: sessionLoggingEnabled,
      );
}
