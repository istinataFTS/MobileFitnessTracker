abstract final class VoiceConstants {
  /// Daily budget cap in USD enforced by Edge Functions (master spec §3.4).
  static const double dailyBudgetCapUsd = 1.00;

  /// Maximum conversation turns sent to voice-chat per call.
  static const int maxHistoryTurns = 3;

  /// Maximum characters in a TTS request (Edge Function limit).
  static const int maxTtsCharacters = 800;

  /// Maximum audio file size accepted by voice-stt.
  static const int maxAudioBytes = 4 * 1024 * 1024; // 4 MB

  /// Timeout for OpenAI API calls (matches Edge Function timeout).
  static const Duration openAiTimeout = Duration(seconds: 30);
}
