import '../../../core/constants/voice_constants.dart';
import '../../../domain/entities/app_settings.dart' show WeightUnit;
import '../../../domain/entities/voice_budget.dart';
import '../../../domain/entities/voice_message.dart';
import '../../../domain/entities/voice_settings.dart';
import 'voice_remote_datasource.dart';

/// Used when Supabase is not configured (local-only builds).
class NoopVoiceRemoteDataSource implements VoiceRemoteDataSource {
  const NoopVoiceRemoteDataSource();

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
  Future<VoiceBudget> getBudget() async => const VoiceBudget(
        usedUsd: 0,
        dailyCapUsd: VoiceConstants.dailyBudgetCapUsd,
      );

  @override
  Future<void> deleteHistory() async {}
}
