import 'package:dartz/dartz.dart';

import '../entities/app_settings.dart';
import '../entities/voice_budget.dart';
import '../entities/voice_message.dart';
import '../entities/voice_settings.dart';
import '../../core/errors/failures.dart';

abstract class VoiceRepository {
  /// Transcribe audio bytes to text via the voice-stt Edge Function.
  Future<Either<Failure, String>> transcribe({
    required List<int> audioBytes,
    required String sessionId,
    required String mimeType,
    bool sessionLoggingEnabled = false,
  });

  /// Send a user message and receive an assistant reply via voice-chat.
  /// [weightUnit] is mapped to the API string at the datasource boundary.
  Future<Either<Failure, VoiceMessage>> chat({
    required String userMessage,
    required String sessionId,
    required List<VoiceMessage> history,
    required VoiceSettings settings,
    required WeightUnit weightUnit,
  });

  /// Synthesise text to audio bytes via the voice-tts Edge Function.
  Future<Either<Failure, List<int>>> synthesise({
    required String text,
    required String sessionId,
    required TtsVoice voice,
    bool sessionLoggingEnabled = false,
  });

  /// Fetch the current user's daily voice budget.
  Future<Either<Failure, VoiceBudget>> getBudget();

  /// Delete all stored voice session history for the current user.
  Future<Either<Failure, void>> deleteHistory();
}
