import 'package:get_it/get_it.dart';

import '../../core/sync/remote_sync_runtime_policy.dart';
import '../../data/datasources/remote/noop_voice_remote_datasource.dart';
import '../../data/datasources/remote/supabase_voice_remote_datasource.dart';
import '../../data/datasources/remote/voice_remote_datasource.dart';
import '../../data/repositories/voice_repository_impl.dart';
import '../../domain/repositories/voice_repository.dart';
import '../../domain/usecases/voice/delete_voice_history.dart';
import '../../domain/usecases/voice/get_voice_budget.dart';
import '../../features/voice/application/voice_bloc.dart';
import '../../features/voice/application/voice_settings_cubit.dart';

void registerVoiceModule(GetIt sl) {
  sl.registerFactory(
    () => VoiceBloc(
      repository: sl(),
      getVoiceBudget: sl(),
      deleteVoiceHistory: sl(),
    ),
  );

  sl.registerFactory(() => VoiceSettingsCubit());

  sl.registerLazySingleton(() => GetVoiceBudget(sl()));
  sl.registerLazySingleton(() => DeleteVoiceHistory(sl()));

  sl.registerLazySingleton<VoiceRepository>(
    () => VoiceRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<VoiceRemoteDataSource>(
    () => sl<RemoteSyncRuntimePolicy>().isRemoteSyncConfigured
        ? SupabaseVoiceRemoteDataSource(clientProvider: sl())
        : const NoopVoiceRemoteDataSource(),
  );
}
