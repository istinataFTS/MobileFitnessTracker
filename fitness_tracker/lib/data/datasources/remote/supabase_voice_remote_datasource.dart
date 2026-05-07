import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/voice_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/voice_budget.dart';
import '../../../domain/entities/voice_message.dart';
import '../../../domain/entities/voice_settings.dart';
import '../../../config/env_config.dart';
import 'supabase_client_provider.dart';
import 'voice_remote_datasource.dart';

class SupabaseVoiceRemoteDataSource implements VoiceRemoteDataSource {
  SupabaseVoiceRemoteDataSource({required this.clientProvider});

  final SupabaseClientProvider clientProvider;

  SupabaseClient get _supabase => clientProvider.client;

  // EnvConfig.supabaseUrl is the compile-time constant used when initialising
  // the Supabase client, so it is always consistent with the client's base URL.
  static const String _functionsBaseUrl =
      '${EnvConfig.supabaseUrl}/functions/v1';

  Future<String> _bearerToken() async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw const ServerFailure('Not authenticated');
    return session.accessToken;
  }

  // ---------------------------------------------------------------------------
  // Transcribe (voice-stt)
  // ---------------------------------------------------------------------------

  @override
  Future<String> transcribe({
    required List<int> audioBytes,
    required String sessionId,
    required String mimeType,
    bool sessionLoggingEnabled = false,
  }) async {
    final token = await _bearerToken();
    final uri = Uri.parse('$_functionsBaseUrl/voice-stt');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['session_id'] = sessionId
      ..fields['session_logging_enabled'] = sessionLoggingEnabled.toString()
      ..files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: 'recording.${_extensionFor(mimeType)}',
        ),
      );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      _throwFromErrorBody(body, streamed.statusCode);
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['transcript'] as String? ?? '';
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

    // Map enum to the short form the Edge Function expects.
    // This mapping lives only at the datasource boundary.
    final weightUnitString =
        weightUnit == WeightUnit.kilograms ? 'kg' : 'lb';

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
          'weight_unit': weightUnitString,
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
      // Surface tool-call results as-is for now. C-5 (Brain) handles dispatch.
      final toolCall = json['tool_call'] as Map<String, dynamic>? ?? {};
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
  // Synthesise (voice-tts)
  // ---------------------------------------------------------------------------

  @override
  Future<List<int>> synthesise({
    required String text,
    required String sessionId,
    required TtsVoice voice,
    bool sessionLoggingEnabled = false,
  }) async {
    final token = await _bearerToken();
    final uri = Uri.parse('$_functionsBaseUrl/voice-tts');

    final response = await http.post(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'text': text,
        'voice': voice.name,
        'session_id': sessionId,
        'session_logging_enabled': sessionLoggingEnabled,
      }),
    );

    if (response.statusCode != 200) {
      _throwFromErrorBody(
        response.headers['content-type']?.contains('json') == true
            ? response.body
            : '{"error":"TTS failed"}',
        response.statusCode,
      );
    }

    return response.bodyBytes.toList();
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
          sum +
          ((row as Map<String, dynamic>)['cost_usd'] as num).toDouble(),
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

  String _extensionFor(String mimeType) {
    switch (mimeType) {
      case 'audio/wav':
        return 'wav';
      case 'audio/mp4':
      case 'audio/m4a':
        return 'm4a';
      case 'audio/ogg':
        return 'ogg';
      default:
        return 'webm';
    }
  }

  Never _throwFromErrorBody(String body, int statusCode) {
    String message = 'Voice service error ($statusCode)';
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      message = json['error'] as String? ?? message;
    } catch (_) {}
    throw ServerFailure(message);
  }
}
