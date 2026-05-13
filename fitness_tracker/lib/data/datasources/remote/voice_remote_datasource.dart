import '../../../domain/entities/app_settings.dart' show WeightUnit;
import '../../../domain/entities/voice_budget.dart';
import '../../../domain/entities/voice_chat_context.dart';
import '../../../domain/entities/voice_chat_result.dart';
import '../../../domain/entities/voice_message.dart';
import '../../../domain/entities/voice_settings.dart';

abstract class VoiceRemoteDataSource {
  Future<VoiceChatResult> chat({
    required String userMessage,
    required String sessionId,
    required List<VoiceMessage> history,
    required VoiceSettings settings,
    required WeightUnit weightUnit,
    List<RecentSetContext>? recentSets,
    List<RecentNutritionLogContext>? recentNutritionLogs,
  });

  Future<VoiceBudget> getBudget();

  Future<void> deleteHistory();
}
