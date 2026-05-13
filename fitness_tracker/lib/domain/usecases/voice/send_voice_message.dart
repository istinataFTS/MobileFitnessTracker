import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/app_settings.dart' show WeightUnit;
import '../../entities/voice_chat_context.dart';
import '../../entities/voice_chat_result.dart';
import '../../entities/voice_message.dart';
import '../../entities/voice_settings.dart';
import '../../repositories/voice_repository.dart';

/// Sends the user's spoken text plus a 3-turn history to the
/// `voice-chat` Edge Function and returns the structured result:
/// a text reply, a mutation tool call for confirmation, or a query
/// tool call for local execution.
///
/// This is the **only** use case in the voice feature that hits the
/// network in v1. STT and TTS run on-device through service ports.
class SendVoiceMessage {
  const SendVoiceMessage(this._repository);

  final VoiceRepository _repository;

  Future<Either<Failure, VoiceChatResult>> call({
    required String userMessage,
    required String sessionId,
    required List<VoiceMessage> history,
    required VoiceSettings settings,
    required WeightUnit weightUnit,
    List<RecentSetContext>? recentSets,
    List<RecentNutritionLogContext>? recentNutritionLogs,
  }) {
    return _repository.chat(
      userMessage: userMessage,
      sessionId: sessionId,
      history: history,
      settings: settings,
      weightUnit: weightUnit,
      recentSets: recentSets,
      recentNutritionLogs: recentNutritionLogs,
    );
  }
}
