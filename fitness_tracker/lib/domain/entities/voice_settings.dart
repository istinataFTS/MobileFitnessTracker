import 'package:equatable/equatable.dart';

enum WakeWordPreset { samoLevski, trainer, thomas }

enum TtsVoice { alloy, echo, fable, nova, onyx, shimmer }

extension TtsVoiceLabel on TtsVoice {
  String get displayName {
    switch (this) {
      case TtsVoice.alloy:
        return 'Alloy';
      case TtsVoice.echo:
        return 'Echo';
      case TtsVoice.fable:
        return 'Fable';
      case TtsVoice.nova:
        return 'Nova';
      case TtsVoice.onyx:
        return 'Onyx';
      case TtsVoice.shimmer:
        return 'Shimmer';
    }
  }

  /// API string sent to the OpenAI TTS endpoint.
  String get apiValue => name;
}

class VoiceSettings extends Equatable {
  const VoiceSettings({
    this.wakeWordPreset = WakeWordPreset.samoLevski,
    this.ttsVoice = TtsVoice.nova,
    this.sessionLoggingEnabled = false,
    this.workoutModeAutoEnable = false,
    this.ttsVolume = 1.0,
    this.wakeWordArmedInForeground = true,
  });

  const VoiceSettings.defaults() : this();

  final WakeWordPreset wakeWordPreset;
  final TtsVoice ttsVoice;
  final bool sessionLoggingEnabled;
  final bool workoutModeAutoEnable;

  /// TTS playback volume in range 0.0–1.0.
  final double ttsVolume;

  final bool wakeWordArmedInForeground;

  VoiceSettings copyWith({
    WakeWordPreset? wakeWordPreset,
    TtsVoice? ttsVoice,
    bool? sessionLoggingEnabled,
    bool? workoutModeAutoEnable,
    double? ttsVolume,
    bool? wakeWordArmedInForeground,
  }) =>
      VoiceSettings(
        wakeWordPreset: wakeWordPreset ?? this.wakeWordPreset,
        ttsVoice: ttsVoice ?? this.ttsVoice,
        sessionLoggingEnabled:
            sessionLoggingEnabled ?? this.sessionLoggingEnabled,
        workoutModeAutoEnable:
            workoutModeAutoEnable ?? this.workoutModeAutoEnable,
        ttsVolume: ttsVolume ?? this.ttsVolume,
        wakeWordArmedInForeground:
            wakeWordArmedInForeground ?? this.wakeWordArmedInForeground,
      );

  @override
  List<Object?> get props => [
        wakeWordPreset,
        ttsVoice,
        sessionLoggingEnabled,
        workoutModeAutoEnable,
        ttsVolume,
        wakeWordArmedInForeground,
      ];
}
