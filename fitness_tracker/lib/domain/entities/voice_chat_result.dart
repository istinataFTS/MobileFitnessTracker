import 'voice_message.dart';
import 'voice_tool_call.dart';

/// Union type for the three categories of response from `voice-chat`.
sealed class VoiceChatResult {
  const VoiceChatResult();
}

/// LLM returned a plain text message — speak and add to conversation.
/// Also used when the LLM calls the `clarify` pseudo-tool; the datasource
/// extracts the question and wraps it as a text response.
final class VoiceChatTextResponse extends VoiceChatResult {
  const VoiceChatTextResponse({required this.message});
  final VoiceMessage message;
}

/// LLM returned a mutation tool call (log/edit/delete).
/// Requires user confirmation before the client dispatches to a target bloc.
final class VoiceChatMutationCall extends VoiceChatResult {
  const VoiceChatMutationCall({required this.toolCall});
  final VoiceToolCall toolCall;
}

/// LLM returned a query tool call (read-only).
/// Client executes via local use cases, formats result, speaks directly.
/// No confirmation card; no second LLM call.
final class VoiceChatQueryCall extends VoiceChatResult {
  const VoiceChatQueryCall({
    required this.toolCallId,
    required this.toolName,
    required this.args,
  });

  final String toolCallId;
  final String toolName;
  final Map<String, dynamic> args;
}
