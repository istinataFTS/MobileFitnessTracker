import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/voice_settings.dart';
import '../../../domain/usecases/voice/delete_voice_history.dart';
import '../../settings/application/app_settings_cubit.dart';

/// Thin facade exposing the voice-specific slice of [AppSettingsCubit].
///
/// Why a separate cubit:
/// - The Voice Settings page (C-3) needs a focused stream of just
///   the voice fields, not the whole `AppSettingsState`.
/// - Widget tests for voice settings should be able to inject a
///   simpler cubit than the full settings one.
///
/// Why it delegates instead of holding its own state:
/// - Persistence lives in one place (`AppSettings` repository) — a
///   separate writer would let the two states drift.
/// - `AppSettingsCubit` is registered as a lazy singleton in DI so
///   every consumer sees the same instance — toggling a voice
///   setting from the Voice Settings page is immediately reflected
///   in the main Settings page and vice versa.
class VoiceSettingsCubit extends Cubit<VoiceSettings> {
  VoiceSettingsCubit({
    required AppSettingsCubit appSettingsCubit,
    required DeleteVoiceHistory deleteVoiceHistory,
  })  : _appSettingsCubit = appSettingsCubit,
        _deleteVoiceHistory = deleteVoiceHistory,
        super(appSettingsCubit.state.settings.voiceSettings) {
    // Ensure settings are loaded from disk before the UI starts
    // reading from this cubit. If a load is already in flight or
    // completed, `ensureLoaded` is a no-op.
    unawaited(_init());

    // Mirror downstream changes from AppSettingsCubit so the Voice
    // Settings page reacts to writes made elsewhere (e.g. main
    // Settings page changes weight unit while this cubit is alive).
    _subscription = _appSettingsCubit.stream
        .map((s) => s.settings.voiceSettings)
        .distinct()
        .listen(_emitIfOpen);
  }

  final AppSettingsCubit _appSettingsCubit;
  final DeleteVoiceHistory _deleteVoiceHistory;
  late final StreamSubscription<VoiceSettings> _subscription;

  Future<void> _init() async {
    await _appSettingsCubit.ensureLoaded();
    _emitIfOpen(_appSettingsCubit.state.settings.voiceSettings);
  }

  void _emitIfOpen(VoiceSettings next) {
    if (isClosed) return;
    if (next == state) return;
    emit(next);
  }

  // ---------------------------------------------------------------------------
  // Setters — all delegate to AppSettingsCubit, which owns persistence.
  // Each returns Future<bool> mirroring the underlying save result so the
  // UI can show a "couldn't save" toast if disk write fails.
  // ---------------------------------------------------------------------------

  Future<bool> setWakeWordPreset(WakeWordPreset preset) =>
      _appSettingsCubit.setVoiceWakeWordPreset(preset);

  Future<bool> setSessionLoggingEnabled(bool enabled) =>
      _appSettingsCubit.setVoiceSessionLoggingEnabled(enabled);

  Future<bool> setWorkoutModeAutoEnable(bool enabled) =>
      _appSettingsCubit.setVoiceWorkoutModeAutoEnable(enabled);

  Future<bool> setTtsVolume(double volume) =>
      _appSettingsCubit.setVoiceTtsVolume(volume);

  Future<bool> setTtsSpeechRate(double rate) =>
      _appSettingsCubit.setVoiceTtsSpeechRate(rate);

  Future<bool> setWakeWordArmedInForeground(bool armed) =>
      _appSettingsCubit.setVoiceWakeWordArmedInForeground(armed);

  // ---------------------------------------------------------------------------
  // Slider previews — emit local state without writing to disk.
  // Use on [Slider.onChanged] for instant visual feedback; pair with the
  // persisting setter on [Slider.onChangeEnd].
  // ---------------------------------------------------------------------------

  /// Live volume preview — does NOT persist. Pair with [setTtsVolume].
  void previewTtsVolume(double volume) {
    _emitIfOpen(state.copyWith(ttsVolume: volume));
  }

  /// Live speech-rate preview — does NOT persist. Pair with [setTtsSpeechRate].
  void previewTtsSpeechRate(double rate) {
    _emitIfOpen(state.copyWith(ttsSpeechRate: rate));
  }

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------

  /// Deletes all stored voice conversation history.
  /// Returns `true` on success, `false` on failure.
  Future<bool> clearHistory() async {
    final result = await _deleteVoiceHistory();
    return result.isRight();
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
