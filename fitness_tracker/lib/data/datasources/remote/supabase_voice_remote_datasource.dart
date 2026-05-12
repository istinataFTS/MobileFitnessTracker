import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/env_config.dart';
import '../../../core/constants/voice_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/app_settings.dart' show WeightUnit;
import '../../../domain/entities/voice_budget.dart';
import '../../../domain/entities/voice_message.dart';
import '../../../domain/entities/voice_settings.dart';
import 'supabase_client_provider.dart';
import 'voice_remote_datasource.dart';

class SupabaseVoiceRemoteDataSource implements VoiceRemoteDataSource {
  SupabaseVoiceRemoteDataSource({required this.clientProvider});

  final SupabaseClientProvider clientProvider;

  SupabaseClient get _supabase => clientProvider.client;

  /// Edge Functions base URL — constructed from the compile-time Supabase URL
  /// using the standard Supabase pattern: `$supabaseUrl/functions/v1`.
  String get _functionsBaseUrl => '${EnvConfig.supabaseUrl}/functions/v1';

  Future<String> _bearerToken() async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw const ServerFailure('Not authenticated');
    return session.accessToken;
  }

  // ---------------------------------------------------------------------------
  // Chat (voice-chat)
  // ---------------------------------------------------------------------------

  @override
  Future<VoiceMessage> chat({
    required String userMessage,
    required String sessionId,
    required List<VoiceMessage> history,
    required VoiceSettings settings,
    required WeightUnit weightUnit,
  }) async {
    final token = await _bearerToken();
    final uri = Uri.parse('$_functionsBaseUrl/voice-chat');

    final historyJson = history
        .map((m) => <String, String>{
              'role': m.role == VoiceRole.user ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();

    final response = await http.post(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'session_id': sessionId,
        'user_message': userMessage,
        'history': historyJson,
        'context': <String, dynamic>{
          // Explicit mapping at the boundary — never `weightUnit.name`,
          // which would emit 'kilograms' / 'pounds'. The Edge Function
          // expects the short codes 'kg' / 'lb'.
          'weight_unit': _weightUnitCode(weightUnit),
        },
        'session_logging_enabled': settings.sessionLoggingEnabled,
      }),
    );

    if (response.statusCode != 200) {
      _throwFromErrorBody(response.body, response.statusCode);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final kind = json['kind'] as String?;

    if (kind == 'tool_call') {
      // Surface tool-call results as a readable assistant message for now.
      // C-5 (Brain) will handle proper tool dispatch.
      final toolCall = json['tool_call'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final toolName = toolCall['name'] as String? ?? 'action';
      return VoiceMessage(
        role: VoiceRole.assistant,
        content: '[tool: $toolName]',
        createdAt: DateTime.now(),
      );
    }

    return VoiceMessage(
      role: VoiceRole.assistant,
      content: json['message'] as String? ?? '',
      createdAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Budget
  // ---------------------------------------------------------------------------

  @override
  Future<VoiceBudget> getBudget() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const ServerFailure('Not authenticated');

    final now = DateTime.now().toUtc();
    final startOfDay = DateTime.utc(now.year, now.month, now.day);

    final result = await _supabase
        .from('voice_usage_log')
        .select('cost_usd')
        .eq('user_id', userId)
        .gte('created_at', startOfDay.toIso8601String());

    final rows = result as List<dynamic>;
    final usedUsd = rows.fold<double>(
      0.0,
      (sum, row) =>
          sum + ((row as Map<String, dynamic>)['cost_usd'] as num).toDouble(),
    );

    return VoiceBudget(
      usedUsd: usedUsd,
      dailyCapUsd: VoiceConstants.dailyBudgetCapUsd,
    );
  }

  // ---------------------------------------------------------------------------
  // Delete history
  // ---------------------------------------------------------------------------

  @override
  Future<void> deleteHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const ServerFailure('Not authenticated');

    await _supabase.from('voice_sessions').delete().eq('user_id', userId);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Maps the in-app [WeightUnit] enum to the short code the Edge
  /// Function's system prompt expects. This is the **only** place in
  /// `lib/` where 'kg' / 'lb' literals are allowed — every other layer
  /// uses the typed enum.
  String _weightUnitCode(WeightUnit unit) {
    switch (unit) {
      case WeightUnit.kilograms:
        return 'kg';
      case WeightUnit.pounds:
        return 'lb';
    }
  }

  Never _throwFromErrorBody(String body, int statusCode) {
    String message = 'Voice service error ($statusCode)';
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      message = json['error'] as String? ?? message;
    } catch (_) {
      // Body is not JSON — keep the default message.
    }
    throw ServerFailure(message);
  }
}
