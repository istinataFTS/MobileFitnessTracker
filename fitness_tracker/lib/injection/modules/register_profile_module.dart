import 'package:get_it/get_it.dart';

import '../../core/sync/remote_sync_runtime_policy.dart';
import '../../data/datasources/remote/noop_user_profile_remote_datasource.dart';
import '../../data/datasources/remote/supabase_user_profile_remote_datasource.dart';
import '../../data/datasources/remote/user_profile_remote_datasource.dart';
import '../../data/repositories/user_profile_repository_impl.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../features/profile/application/profile_cubit.dart';

void registerProfileModule(GetIt sl) {
  sl.registerLazySingleton<UserProfileRemoteDataSource>(
    () => sl<RemoteSyncRuntimePolicy>().isRemoteSyncConfigured
        ? SupabaseUserProfileRemoteDataSource(clientProvider: sl())
        : const NoopUserProfileRemoteDataSource(),
  );

  sl.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(remoteDataSource: sl()),
  );

  // Factory so each BlocProvider gets a fresh instance. At app level this means
  // exactly one instance exists for the lifetime of the widget tree; future
  // test harnesses can inject a fresh one per test without teardown concerns.
  sl.registerFactory<ProfileCubit>(
    () => ProfileCubit(
      repository: sl(),
      sessionSyncService: sl(),
      authSessionService: sl(),
      userProfileRepository: sl(),
    ),
  );
}
