import 'package:equatable/equatable.dart';

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

  String get apiValue => name;
}

class VoiceSettings extends Equatable {
  const VoiceSettings({
    required this.sessionLoggingEnabled,
    required this.ttsVoice,
  });

  const VoiceSettings.defaults()
      : sessionLoggingEnabled = false,
        ttsVoice = TtsVoice.nova;

  final bool sessionLoggingEnabled;
  final TtsVoice ttsVoice;

  VoiceSettings copyWith({
    bool? sessionLoggingEnabled,
    TtsVoice? ttsVoice,
  }) {
    return VoiceSettings(
      sessionLoggingEnabled: sessionLoggingEnabled ?? this.sessionLoggingEnabled,
      ttsVoice: ttsVoice ?? this.ttsVoice,
    );
  }

  @override
  List<Object?> get props => <Object?>[sessionLoggingEnabled, ttsVoice];
}
