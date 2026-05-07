import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/domain/entities/voice_settings.dart';
import 'package:fitness_tracker/domain/repositories/app_settings_repository.dart';
import 'package:fitness_tracker/features/settings/application/app_settings_cubit.dart';
import 'package:fitness_tracker/features/voice/application/voice_settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAppSettingsRepository extends Mock implements AppSettingsRepository {}

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
    test(
        'initial state is derived from AppSettingsCubit.state.settings.voiceSettings',
        () async {
      const customVoice = VoiceSettings(ttsVoice: TtsVoice.echo);
      const settings = AppSettings(
        notificationsEnabled: true,
        weekStartDay: WeekStartDay.monday,
        weightUnit: WeightUnit.kilograms,
        voiceSettings: customVoice,
      );

      final repo = _stubRepo(settings: settings);
      final appCubit = _makeAppSettingsCubit(repo);
      await appCubit.ensureLoaded();

      final voiceCubit = VoiceSettingsCubit(appCubit);
      // After _init() fires and AppSettingsCubit is loaded:
      await Future<void>.delayed(Duration.zero);

      expect(voiceCubit.state.ttsVoice, TtsVoice.echo);

      await voiceCubit.close();
      await appCubit.close();
    });

    test('close() cancels stream subscription without double-cancel error',
        () async {
      final repo = _stubRepo();
      final appCubit = _makeAppSettingsCubit(repo);
      final voiceCubit = VoiceSettingsCubit(appCubit);

      // Should not throw
      await voiceCubit.close();
      await appCubit.close();
    });

    test('setTtsVoice delegates to AppSettingsCubit', () async {
      final repo = _stubRepo();
      final appCubit = _makeAppSettingsCubit(repo);
      await appCubit.ensureLoaded();
      final voiceCubit = VoiceSettingsCubit(appCubit);

      await voiceCubit.setTtsVoice(TtsVoice.shimmer);

      final captured = verify(() => repo.saveSettings(captureAny())).captured;
      final saved = captured.last as AppSettings;
      expect(saved.voiceSettings.ttsVoice, TtsVoice.shimmer);

      await voiceCubit.close();
      await appCubit.close();
    });

    test('setSessionLogging delegates to AppSettingsCubit', () async {
      final repo = _stubRepo();
      final appCubit = _makeAppSettingsCubit(repo);
      await appCubit.ensureLoaded();
      final voiceCubit = VoiceSettingsCubit(appCubit);

      await voiceCubit.setSessionLogging(true);

      final captured = verify(() => repo.saveSettings(captureAny())).captured;
      final saved = captured.last as AppSettings;
      expect(saved.voiceSettings.sessionLoggingEnabled, isTrue);

      await voiceCubit.close();
      await appCubit.close();
    });

    test('setWakeWordPreset delegates to AppSettingsCubit', () async {
      final repo = _stubRepo();
      final appCubit = _makeAppSettingsCubit(repo);
      await appCubit.ensureLoaded();
      final voiceCubit = VoiceSettingsCubit(appCubit);

      await voiceCubit.setWakeWordPreset(WakeWordPreset.trainer);

      final captured = verify(() => repo.saveSettings(captureAny())).captured;
      final saved = captured.last as AppSettings;
      expect(saved.voiceSettings.wakeWordPreset, WakeWordPreset.trainer);

      await voiceCubit.close();
      await appCubit.close();
    });

    test('state does not change when non-voice AppSettings field changes',
        () async {
      final repo = _stubRepo();
      final appCubit = _makeAppSettingsCubit(repo);
      await appCubit.ensureLoaded();
      final voiceCubit = VoiceSettingsCubit(appCubit);

      final statesBefore = voiceCubit.state;

      // Change a non-voice setting (weightUnit)
      await appCubit.setWeightUnit(WeightUnit.pounds);
      await Future<void>.delayed(Duration.zero);

      // VoiceSettingsCubit state should not have emitted a new value
      expect(voiceCubit.state, equals(statesBefore));

      await voiceCubit.close();
      await appCubit.close();
    });
  });
}
