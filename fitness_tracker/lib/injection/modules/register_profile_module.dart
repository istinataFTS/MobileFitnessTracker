import 'package:get_it/get_it.dart';

import '../../core/sync/remote_sync_runtime_policy.dart';
import '../../data/datasources/remote/noop_user_profile_remote_datasource.dart';
import '../../data/datasources/remote/supabase_user_profile_remote_datasource.dart';
import '../../data/datasources/remote/user_profile_remote_datasource.dart';
import '../../data/repositories/user_profile_repository_impl.dart';
import '../../domain/repositories/user_profile_repository.dart';

void registerProfileModule(GetIt sl) {
  sl.registerLazySingleton<UserProfileRemoteDataSource>(
    () => sl<RemoteSyncRuntimePolicy>().isRemoteSyncConfigured
        ? SupabaseUserProfileRemoteDataSource(clientProvider: sl())
        : const NoopUserProfileRemoteDataSource(),
  );

  sl.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(remoteDataSource: sl()),
  );
}
