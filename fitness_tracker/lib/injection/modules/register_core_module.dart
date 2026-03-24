import 'package:get_it/get_it.dart';

import '../../config/env_config.dart';
import '../../core/config/app_sync_policy.dart';
import '../../core/sync/remote_sync_availability.dart';
import '../../data/datasources/local/app_metadata_local_datasource.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/noop_auth_remote_datasource.dart';
import '../../data/datasources/remote/supabase_auth_remote_datasource.dart';
import '../../data/datasources/remote/supabase_client_provider.dart';
import '../../data/repositories/app_session_repository_impl.dart';
import '../../data/repositories/app_settings_repository_impl.dart';
import '../../domain/repositories/app_session_repository.dart';
import '../../domain/repositories/app_settings_repository.dart';

void registerCoreModule(GetIt sl) {
  sl.registerLazySingleton<DatabaseHelper>(DatabaseHelper.new);

  sl.registerLazySingleton<AppMetadataLocalDataSource>(
    () => AppMetadataLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<SupabaseClientProvider>(
    () => SupabaseClientProvider(
      isConfigured: EnvConfig.isSupabaseConfigured,
    ),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => EnvConfig.isSupabaseConfigured
        ? SupabaseAuthRemoteDataSource(clientProvider: sl())
        : const NoopAuthRemoteDataSource(),
  );

  sl.registerLazySingleton<AppSyncPolicy>(
    () => AppSyncPolicy.productionDefault,
  );

  sl.registerLazySingleton(
    () => RemoteSyncAvailability(
      hasRemoteConfiguration: EnvConfig.isSupabaseConfigured,
    ),
  );

  sl.registerLazySingleton<AppSessionRepository>(
    () => AppSessionRepositoryImpl(
      localDataSource: sl(),
      authRemoteDataSource: sl(),
      syncPolicy: sl(),
    ),
  );

  sl.registerLazySingleton<AppSettingsRepository>(
    () => AppSettingsRepositoryImpl(
      localDataSource: sl(),
    ),
  );
}