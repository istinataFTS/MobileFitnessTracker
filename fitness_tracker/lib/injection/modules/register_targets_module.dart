import 'package:get_it/get_it.dart';

import '../../core/sync/remote_sync_runtime_policy.dart';
import '../../data/datasources/local/pending_sync_delete_local_datasource.dart';
import '../../data/datasources/local/target_local_datasource.dart';
import '../../data/datasources/remote/noop_target_remote_datasource.dart';
import '../../data/datasources/remote/supabase_target_remote_datasource.dart';
import '../../data/datasources/remote/target_remote_datasource.dart';
import '../../data/repositories/target_repository_impl.dart';
import '../../data/sync/target_sync_coordinator.dart';
import '../../data/sync/target_sync_coordinator_impl.dart';
import '../../domain/repositories/target_repository.dart';
import '../../domain/usecases/targets/add_target.dart';
import '../../domain/usecases/targets/delete_target.dart';
import '../../domain/usecases/targets/get_all_targets.dart';
import '../../domain/usecases/targets/update_target.dart';
import '../../features/targets/application/targets_bloc.dart';

void registerTargetsModule(GetIt sl) {
  sl.registerFactory(
    () => TargetsBloc(
      getAllTargets: sl(),
      addTarget: sl(),
      updateTarget: sl(),
      deleteTarget: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => AddTarget(
      sl(),
      appSessionRepository: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => GetAllTargets(
      sl(),
      sourcePreferenceResolver: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => UpdateTarget(
      sl(),
      appSessionRepository: sl(),
    ),
  );
  sl.registerLazySingleton(() => DeleteTarget(sl()));

  sl.registerLazySingleton<TargetRepository>(
    () => TargetRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      syncCoordinator: sl(),
    ),
  );

  sl.registerLazySingleton<TargetSyncCoordinator>(
    () => TargetSyncCoordinatorImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      pendingSyncDeleteLocalDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<TargetLocalDataSource>(
    () => TargetLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<TargetRemoteDataSource>(
    () => sl<RemoteSyncRuntimePolicy>().isRemoteSyncConfigured
        ? SupabaseTargetRemoteDataSource(clientProvider: sl())
        : const NoopTargetRemoteDataSource(),
  );
}
