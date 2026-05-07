import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../core/sync/remote_sync_runtime_policy.dart';
import '../../data/datasources/remote/noop_voice_remote_datasource.dart';
import '../../data/datasources/remote/supabase_voice_remote_datasource.dart';
import '../../data/datasources/remote/voice_remote_datasource.dart';
import '../../data/repositories/voice_repository_impl.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../../domain/repositories/voice_repository.dart';
import '../../domain/usecases/voice/delete_voice_history.dart';
import '../../domain/usecases/voice/get_voice_budget.dart';
import '../../domain/usecases/voice/send_voice_message.dart';
import '../../domain/usecases/voice/synthesise_speech.dart';
import '../../domain/usecases/voice/transcribe_audio.dart';
import '../../features/settings/application/app_settings_cubit.dart';
import '../../features/voice/application/voice_bloc.dart';
import '../../features/voice/application/voice_settings_cubit.dart';
import '../../features/voice/data/services/permission_handler_voice_permission_service.dart';
import '../../features/voice/data/services/secure_storage_voice_credential_service.dart';
import '../../features/voice/data/services/voice_credential_service.dart';
import '../../features/voice/data/services/voice_permission_service.dart';

void registerVoiceModule(GetIt sl) {
  // ── Infrastructure ────────────────────────────────────────────────────────
  // FlutterSecureStorage is stateless — a single instance is sufficient.
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // ── Services ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<VoicePermissionService>(
    () => const PermissionHandlerVoicePermissionService(),
  );
  sl.registerLazySingleton<VoiceCredentialService>(
    () => SecureStorageVoiceCredentialService(sl()),
  );

  // ── Use cases ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetVoiceBudget(sl()));
  sl.registerLazySingleton(() => DeleteVoiceHistory(sl()));
  sl.registerLazySingleton(() => TranscribeAudio(sl()));
  sl.registerLazySingleton(() => SendVoiceMessage(sl()));
  sl.registerLazySingleton(() => SynthesizeSpeech(sl()));

  // ── Blocs / Cubits ────────────────────────────────────────────────────────
  // VoiceBloc: factory — new instance per page (holds transient session state).
  sl.registerFactory(() => VoiceBloc(
        transcribeAudio: sl(),
        sendVoiceMessage: sl(),
        synthesizeSpeech: sl(),
        getVoiceBudget: sl(),
        deleteVoiceHistory: sl(),
        permissionService: sl(),
        credentialService: sl(),
        appSettingsRepository: sl<AppSettingsRepository>(),
      ));

  // VoiceSettingsCubit: factory — each page gets its own, but all delegate
  // writes to the singleton AppSettingsCubit, so state is always consistent.
  sl.registerFactory(
    () => VoiceSettingsCubit(sl<AppSettingsCubit>()),
  );

  // ── Repository ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<VoiceRepository>(
    () => VoiceRepositoryImpl(remoteDataSource: sl()),
  );

  // ── Datasource ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<VoiceRemoteDataSource>(
    () => sl<RemoteSyncRuntimePolicy>().isRemoteSyncConfigured
        ? SupabaseVoiceRemoteDataSource(clientProvider: sl())
        : const NoopVoiceRemoteDataSource(),
  );
}
