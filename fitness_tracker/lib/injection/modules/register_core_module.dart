import 'package:get_it/get_it.dart';

import '../../core/config/app_sync_policy.dart';
import '../../data/datasources/local/app_metadata_local_datasource.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/noop_auth_remote_datasource.dart';
import '../../data/repositories/app_session_repository_impl.dart';
import '../../domain/repositories/app_session_repository.dart';

void registerCoreModule(GetIt sl) {
  sl.registerLazySingleton<DatabaseHelper>(DatabaseHelper.new);

  sl.registerLazySingleton<AppMetadataLocalDataSource>(
    () => AppMetadataLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    NoopAuthRemoteDataSource.new,
  );

  sl.registerLazySingleton<AppSyncPolicy>(
    () => AppSyncPolicy.productionDefault,
  );

  sl.registerLazySingleton<AppSessionRepository>(
    () => AppSessionRepositoryImpl(
      localDataSource: sl(),
      authRemoteDataSource: sl(),
      syncPolicy: sl(),
    ),
  );
}