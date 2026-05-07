import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/voice_settings.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../datasources/local/app_metadata_local_datasource.dart';

class AppSettingsRepositoryImpl implements AppSettingsRepository {
  static const String _notificationsEnabledKey =
      'settings.notifications_enabled';
  static const String _weekStartDayKey = 'settings.week_start_day';
  static const String _weightUnitKey = 'settings.weight_unit';
  static const String _uiExpansionStateKey = 'settings.ui_expansion_state';

  // Voice settings keys
  static const String _kVoiceWakeWordPreset = 'settings.voice_wake_word_preset';
  static const String _kVoiceTtsVoice = 'settings.voice_tts_voice';
  static const String _kVoiceSessionLogging = 'settings.voice_session_logging';
  static const String _kVoiceWorkoutModeAuto = 'settings.voice_workout_mode_auto';
  static const String _kVoiceTtsVolume = 'settings.voice_tts_volume';
  static const String _kVoiceWakeWordArmed = 'settings.voice_wake_word_armed';

  final AppMetadataLocalDataSource localDataSource;

  const AppSettingsRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, AppSettings>> getSettings() {
    return RepositoryGuard.run(() async {
      final notificationsEnabled =
          await localDataSource.readBool(_notificationsEnabledKey);
      final weekStartDayRaw =
          await localDataSource.readString(_weekStartDayKey);
      final weightUnitRaw = await localDataSource.readString(_weightUnitKey);
      final uiExpansionRaw =
          await localDataSource.readJsonObject(_uiExpansionStateKey);

      // Voice settings
      final wakeWordStr =
          await localDataSource.readString(_kVoiceWakeWordPreset);
      final ttsVoiceStr = await localDataSource.readString(_kVoiceTtsVoice);
      final sessionLog = await localDataSource.readBool(_kVoiceSessionLogging);
      final workoutAuto =
          await localDataSource.readBool(_kVoiceWorkoutModeAuto);
      final ttsVolStr = await localDataSource.readString(_kVoiceTtsVolume);
      final wakeArmed = await localDataSource.readBool(_kVoiceWakeWordArmed);

      final voiceSettings = VoiceSettings(
        wakeWordPreset: _parseEnum(
          WakeWordPreset.values,
          wakeWordStr,
          WakeWordPreset.samoLevski,
        ),
        ttsVoice: _parseEnum(TtsVoice.values, ttsVoiceStr, TtsVoice.nova),
        sessionLoggingEnabled: sessionLog ?? false,
        workoutModeAutoEnable: workoutAuto ?? false,
        ttsVolume: double.tryParse(ttsVolStr ?? '') ?? 1.0,
        wakeWordArmedInForeground: wakeArmed ?? true,
      );

      return AppSettings(
        notificationsEnabled: notificationsEnabled ?? true,
        weekStartDay: _parseWeekStartDay(weekStartDayRaw),
        weightUnit: _parseWeightUnit(weightUnitRaw),
        uiExpansionState: _parseUiExpansionState(uiExpansionRaw),
        voiceSettings: voiceSettings,
      );
    });
  }

  @override
  Future<Either<Failure, void>> saveSettings(AppSettings settings) {
    return RepositoryGuard.run(() async {
      await localDataSource.writeBool(
        _notificationsEnabledKey,
        settings.notificationsEnabled,
      );
      await localDataSource.writeString(
        _weekStartDayKey,
        settings.weekStartDay.name,
      );
      await localDataSource.writeString(
        _weightUnitKey,
        settings.weightUnit.name,
      );
      await localDataSource.writeJsonObject(
        _uiExpansionStateKey,
        settings.uiExpansionState.cast<String, dynamic>(),
      );

      // Voice settings
      await localDataSource.writeString(
        _kVoiceWakeWordPreset,
        settings.voiceSettings.wakeWordPreset.name,
      );
      await localDataSource.writeString(
        _kVoiceTtsVoice,
        settings.voiceSettings.ttsVoice.name,
      );
      await localDataSource.writeBool(
        _kVoiceSessionLogging,
        settings.voiceSettings.sessionLoggingEnabled,
      );
      await localDataSource.writeBool(
        _kVoiceWorkoutModeAuto,
        settings.voiceSettings.workoutModeAutoEnable,
      );
      await localDataSource.writeString(
        _kVoiceTtsVolume,
        settings.voiceSettings.ttsVolume.toString(),
      );
      await localDataSource.writeBool(
        _kVoiceWakeWordArmed,
        settings.voiceSettings.wakeWordArmedInForeground,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Parsers
  // ---------------------------------------------------------------------------

  static T _parseEnum<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    if (name == null) return fallback;
    return values.firstWhere((e) => e.name == name, orElse: () => fallback);
  }

  Map<String, bool> _parseUiExpansionState(Map<String, dynamic>? raw) {
    if (raw == null) return const <String, bool>{};
    try {
      return raw.map(
        (String k, dynamic v) => MapEntry(k, v == true),
      );
    } catch (_) {
      return const <String, bool>{};
    }
  }

  WeekStartDay _parseWeekStartDay(String? rawValue) {
    switch (rawValue) {
      case 'sunday':
        return WeekStartDay.sunday;
      case 'monday':
      default:
        return WeekStartDay.monday;
    }
  }

  WeightUnit _parseWeightUnit(String? rawValue) {
    switch (rawValue) {
      case 'pounds':
        return WeightUnit.pounds;
      case 'kilograms':
      default:
        return WeightUnit.kilograms;
    }
  }
}
