import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/voice_settings.dart';
import '../../settings/application/app_settings_cubit.dart';

/// A thin cubit that mirrors the [VoiceSettings] slice of [AppSettingsCubit].
///
/// All reads come from [AppSettingsCubit] state; all writes delegate to
/// [AppSettingsCubit] setters which persist through [AppSettingsRepository].
/// This cubit is never an independent source of truth.
class VoiceSettingsCubit extends Cubit<VoiceSettings> {
  VoiceSettingsCubit(this._appSettingsCubit)
      : super(_appSettingsCubit.state.settings.voiceSettings) {
    // Ensure AppSettings are loaded from SQLite, then emit the correct state.
    _init();
    // Mirror subsequent AppSettingsCubit changes (voice slice only).
    _sub = _appSettingsCubit.stream
        .map((s) => s.settings.voiceSettings)
        .distinct()
        .listen(emit);
  }

  final AppSettingsCubit _appSettingsCubit;
  late final StreamSubscription<VoiceSettings> _sub;

  Future<void> _init() async {
    await _appSettingsCubit.ensureLoaded();
    if (!isClosed) {
      emit(_appSettingsCubit.state.settings.voiceSettings);
    }
  }

  Future<void> setWakeWordPreset(WakeWordPreset preset) =>
      _appSettingsCubit.setVoiceWakeWordPreset(preset);

  Future<void> setTtsVoice(TtsVoice voice) =>
      _appSettingsCubit.setVoiceTtsVoice(voice);

  Future<void> setSessionLogging(bool enabled) =>
      _appSettingsCubit.setVoiceSessionLogging(enabled);

  Future<void> setWorkoutModeAutoEnable(bool enabled) =>
      _appSettingsCubit.setVoiceWorkoutModeAutoEnable(enabled);

  Future<void> setTtsVolume(double volume) =>
      _appSettingsCubit.setVoiceTtsVolume(volume);

  Future<void> setWakeWordArmedInForeground(bool armed) =>
      _appSettingsCubit.setVoiceWakeWordArmedInForeground(armed);

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
