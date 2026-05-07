import '../../../core/constants/voice_constants.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/voice_budget.dart';
import '../../../domain/entities/voice_message.dart';
import '../../../domain/entities/voice_settings.dart';
import 'voice_remote_datasource.dart';

/// Used when Supabase is not configured (local-only builds).
class NoopVoiceRemoteDataSource implements VoiceRemoteDataSource {
  const NoopVoiceRemoteDataSource();

  @override
  Future<String> transcribe({
    required List<int> audioBytes,
    required String sessionId,
    required String mimeType,
    bool sessionLoggingEnabled = false,
  }) async =>
      '';

  @override
  Future<VoiceMessage> chat({
    required String userMessage,
    required String sessionId,
    required List<VoiceMessage> history,
    required VoiceSettings settings,
    required WeightUnit weightUnit,
  }) async =>
      VoiceMessage(
        role: VoiceRole.assistant,
        content: '',
        createdAt: DateTime.now(),
      );

  @override
  Future<List<int>> synthesise({
    required String text,
    required String sessionId,
    required TtsVoice voice,
    bool sessionLoggingEnabled = false,
  }) async =>
      const <int>[];

  @override
  Future<VoiceBudget> getBudget() async => const VoiceBudget(
        usedUsd: 0,
        dailyCapUsd: VoiceConstants.dailyBudgetCapUsd,
      );

  @override
  Future<void> deleteHistory() async {}
}
