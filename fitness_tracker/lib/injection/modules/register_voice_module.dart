import 'package:get_it/get_it.dart';

import '../../core/sync/remote_sync_runtime_policy.dart';
import '../../data/datasources/remote/noop_voice_remote_datasource.dart';
import '../../data/datasources/remote/supabase_voice_remote_datasource.dart';
import '../../data/datasources/remote/voice_remote_datasource.dart';
import '../../data/repositories/voice_repository_impl.dart';
import '../../domain/repositories/voice_repository.dart';
import '../../domain/usecases/voice/delete_voice_history.dart';
import '../../domain/usecases/voice/get_voice_budget.dart';
import '../../domain/usecases/voice/send_voice_message.dart';
import '../../features/settings/application/app_settings_cubit.dart';
import '../../features/voice/application/voice_bloc.dart';
import '../../features/voice/application/voice_settings_cubit.dart';
import '../../features/voice/data/services/flutter_tts_voice_tts_service.dart';
import '../../features/voice/data/services/speech_to_text_voice_stt_service.dart';
import '../../features/voice/data/services/voice_stt_service.dart';
import '../../features/voice/data/services/voice_tts_service.dart';

/// Wires up the voice feature.
///
/// Ordering note: `registerCoreModule` must run before this module
/// (it owns the lazy-singleton `AppSettingsCubit` and the
/// `AppSettingsRepository`). The injection bootstrap (`injection.dart`)
/// already enforces this order.
void registerVoiceModule(GetIt sl) {
  // ── Device services (STT + TTS) ────────────────────────────────
  // Lazy singletons: the underlying plugins hold native resources
  // (microphone session, TTS engine) and must not be torn down /
  // re-created per page.
  sl.registerLazySingleton<VoiceSttService>(SpeechToTextVoiceSttService.new);
  sl.registerLazySingleton<VoiceTtsService>(FlutterTtsVoiceTtsService.new);

  // ── Repository + datasource ────────────────────────────────────
  sl.registerLazySingleton<VoiceRepository>(
    () => VoiceRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<VoiceRemoteDataSource>(
    () => sl<RemoteSyncRuntimePolicy>().isRemoteSyncConfigured
        ? SupabaseVoiceRemoteDataSource(clientProvider: sl())
        : const NoopVoiceRemoteDataSource(),
  );

  // ── Use cases ──────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetVoiceBudget(sl()));
  sl.registerLazySingleton(() => DeleteVoiceHistory(sl()));
  sl.registerLazySingleton(() => SendVoiceMessage(sl()));

  // ── Cubits / blocs ─────────────────────────────────────────────
  // VoiceSettingsCubit is a factory so each page gets its own
  // subscription to AppSettingsCubit's stream — but the *state* it
  // mirrors comes from the shared singleton, so all instances see
  // the same values.
  sl.registerFactory(
    () => VoiceSettingsCubit(appSettingsCubit: sl<AppSettingsCubit>()),
  );

  // VoiceBloc is also a factory (per voice overlay). The injected
  // `currentVoiceSettings` callback reads the latest values from
  // the singleton AppSettingsCubit at every chat turn — no stale
  // snapshot.
  sl.registerFactory(
    () => VoiceBloc(
      sendVoiceMessage: sl(),
      getVoiceBudget: sl(),
      deleteVoiceHistory: sl(),
      sttService: sl(),
      ttsService: sl(),
      appSettingsRepository: sl(),
      currentVoiceSettings: () =>
          sl<AppSettingsCubit>().state.settings.voiceSettings,
    ),
  );
}
