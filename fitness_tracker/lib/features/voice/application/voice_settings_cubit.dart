import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/voice_settings.dart';

class VoiceSettingsCubit extends Cubit<VoiceSettings> {
  VoiceSettingsCubit() : super(const VoiceSettings.defaults());

  void setSessionLogging({required bool enabled}) {
    emit(state.copyWith(sessionLoggingEnabled: enabled));
  }

  void setTtsVoice(TtsVoice voice) {
    emit(state.copyWith(ttsVoice: voice));
  }
}
