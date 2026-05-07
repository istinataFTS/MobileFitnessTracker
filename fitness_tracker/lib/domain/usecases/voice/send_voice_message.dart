import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/app_settings.dart';
import '../../entities/voice_message.dart';
import '../../entities/voice_settings.dart';
import '../../repositories/voice_repository.dart';

class SendVoiceMessage {
  const SendVoiceMessage(this._repository);

  final VoiceRepository _repository;

  Future<Either<Failure, VoiceMessage>> call({
    required String userMessage,
    required String sessionId,
    required List<VoiceMessage> history,
    required VoiceSettings settings,
    required WeightUnit weightUnit,
  }) =>
      _repository.chat(
        userMessage: userMessage,
        sessionId: sessionId,
        history: history,
        settings: settings,
        weightUnit: weightUnit,
      );
}
