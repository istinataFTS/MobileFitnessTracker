import 'package:equatable/equatable.dart';

/// Represents a pending LLM tool call awaiting user confirmation.
///
/// Created by C-5's tool dispatcher when the `voice-chat` Edge Function
/// returns a `tool_call` response. C-3's [VoiceConfirmationCard] renders
/// this to the user; [VoiceBloc] clears it on accept or cancel.
///
/// The bloc never executes the tool itself — the server never executes
/// tools (architectural rule §3.8.3). The client confirms, then
/// dispatches to the appropriate existing bloc (C-5's responsibility).
class VoiceToolCall extends Equatable {
  const VoiceToolCall({
    required this.toolName,
    required this.displaySummary,
    required this.args,
  });

  /// Internal tool identifier returned by the LLM, e.g. `'logWorkoutSet'`.
  /// C-5 reads this to pick the right dispatch target.
  final String toolName;

  /// Human-readable summary shown on the confirmation card,
  /// e.g. "Log: Bench Press — 80 kg × 10 reps".
  final String displaySummary;

  /// Raw argument map returned by the LLM. C-3 renders [displaySummary];
  /// C-5 destructures [args] to construct the bloc event.
  final Map<String, dynamic> args;

  @override
  List<Object?> get props => <Object?>[toolName, displaySummary, args];
}
