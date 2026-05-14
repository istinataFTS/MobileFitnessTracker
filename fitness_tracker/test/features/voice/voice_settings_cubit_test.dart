import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/domain/entities/voice_settings.dart';
import 'package:fitness_tracker/domain/repositories/app_settings_repository.dart';
import 'package:fitness_tracker/domain/usecases/voice/delete_voice_history.dart';
import 'package:fitness_tracker/features/settings/application/app_settings_cubit.dart';
import 'package:fitness_tracker/features/voice/application/voice_settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAppSettingsRepository extends Mock implements AppSettingsRepository {}

class MockDeleteVoiceHistory extends Mock implements DeleteVoiceHistory {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AppSettingsCubit _makeAppSettingsCubit(AppSettingsRepository repo) =>
    AppSettingsCubit(repository: repo);

MockAppSettingsRepository _stubRepo({
  AppSettings settings = const AppSettings.defaults(),
}) {
  final repo = MockAppSettingsRepository();
  when(() => repo.getSettings()).thenAnswer((_) async => Right(settings));
  when(() => repo.saveSettings(any()))
      .thenAnswer((_) async => const Right(null));
  return repo;
}

void main() {
  setUpAll(() {
    registerFallbackValue(const AppSettings.defaults());
  });

  group('VoiceSettingsCubit', () {
    late MockDeleteVoiceHistory deleteVoiceHistory;

    setUp(() {
      deleteVoiceHistory = MockDeleteVoiceHistory();
      when(() => deleteVoiceHistory()).thenAnswer((_) async => const Right(null));
    });

    test(
        'initial state is derived from AppSettingsCubit.state.settings.voiceSettings',
        () async {
      const customVoice = VoiceSettings(
        wakeWordPreset: WakeWordPreset.trainer,
        ttsVolume: 0.7,
      );
      const settings = AppSettings(
        notificationsEnabled: true,
        weekStartDay: WeekStartDay.monday,
        weightUnit: WeightUnit.kilograms,
        voiceSettings: customVoice,
      );

      final repo = _stubRepo(settings: settings);
      final appCubit = _makeAppSettingsCubit(repo);
      await appCubit.ensureLoaded();

      final voiceCubit =
          VoiceSettingsCubit(
            appSettingsCubit: appCubit,
            deleteVoiceHistory: deleteVoiceHistory,
          );
      // Allow _init() to complete.
      await Future<void>.delayed(Duration.zero);

      expect(voiceCubit.state.wakeWordPreset, WakeWordPreset.trainer);
      expect(voiceCubit.state.ttsVolume, 0.7);

      await voiceCubit.close();
      await appCubit.close();
    });

    test('close() cancels stream subscription without double-cancel error',
        () async {
      final repo = _stubRepo();
      final appCubit = _makeAppSettingsCubit(repo);
      final voiceCubit = VoiceSettingsCubit(
            appSettingsCubit: appCubit,
            deleteVoiceHistory: deleteVoiceHistory,
          );

      // Should not throw.
      await voiceCubit.close();
      await appCubit.close();
    });

    test('setWakeWordPreset delegates to AppSettingsCubit', () async {
      final repo = _stubRepo();
      final appCubit = _makeAppSettingsCubit(repo);
      await appCubit.ensureLoaded();
      final voiceCubit = VoiceSettingsCubit(
            appSettingsCubit: appCubit,
            deleteVoiceHistory: deleteVoiceHistory,
          );

      await voiceCubit.setWakeWordPreset(WakeWordPreset.trainer);

      final captured = verify(() => repo.saveSettings(captureAny())).captured;
      final saved = captured.last as AppSettings;
      expect(saved.voiceSettings.wakeWordPreset, WakeWordPreset.trainer);

      await voiceCubit.close();
      await appCubit.close();
    });

    test('setSessionLoggingEnabled delegates to AppSettingsCubit', () async {
      final repo = _stubRepo();
      final appCubit = _makeAppSettingsCubit(repo);
      await appCubit.ensureLoaded();
      final voiceCubit = VoiceSettingsCubit(
            appSettingsCubit: appCubit,
            deleteVoiceHistory: deleteVoiceHistory,
          );

      await voiceCubit.setSessionLoggingEnabled(true);

      final captured = verify(() => repo.saveSettings(captureAny())).captured;
      final saved = captured.last as AppSettings;
      expect(saved.voiceSettings.sessionLoggingEnabled, isTrue);

      await voiceCubit.close();
      await appCubit.close();
    });

    test('setTtsVolume delegates to AppSettingsCubit', () async {
      final repo = _stubRepo();
      final appCubit = _makeAppSettingsCubit(repo);
      await appCubit.ensureLoaded();
      final voiceCubit = VoiceSettingsCubit(
            appSettingsCubit: appCubit,
            deleteVoiceHistory: deleteVoiceHistory,
          );

      await voiceCubit.setTtsVolume(0.6);

      final captured = verify(() => repo.saveSettings(captureAny())).captured;
      final saved = captured.last as AppSettings;
      expect(saved.voiceSettings.ttsVolume, 0.6);

      await voiceCubit.close();
      await appCubit.close();
    });

    test('setTtsSpeechRate delegates to AppSettingsCubit', () async {
      final repo = _stubRepo();
      final appCubit = _makeAppSettingsCubit(repo);
      await appCubit.ensureLoaded();
      final voiceCubit = VoiceSettingsCubit(
            appSettingsCubit: appCubit,
            deleteVoiceHistory: deleteVoiceHistory,
          );

      await voiceCubit.setTtsSpeechRate(0.9);

      final captured = verify(() => repo.saveSettings(captureAny())).captured;
      final saved = captured.last as AppSettings;
      expect(saved.voiceSettings.ttsSpeechRate, 0.9);

      await voiceCubit.close();
      await appCubit.close();
    });

    test('state does not change when non-voice AppSettings field changes',
        () async {
      final repo = _stubRepo();
      final appCubit = _makeAppSettingsCubit(repo);
      await appCubit.ensureLoaded();
      final voiceCubit = VoiceSettingsCubit(
            appSettingsCubit: appCubit,
            deleteVoiceHistory: deleteVoiceHistory,
          );

      final statesBefore = voiceCubit.state;

      // Change a non-voice setting.
      await appCubit.setWeightUnit(WeightUnit.pounds);
      await Future<void>.delayed(Duration.zero);

      // VoiceSettingsCubit state must not have emitted a new value.
      expect(voiceCubit.state, equals(statesBefore));

      await voiceCubit.close();
      await appCubit.close();
    });
  });
}
