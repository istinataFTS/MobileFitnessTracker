import 'package:get_it/get_it.dart';

import '../../core/sync/remote_sync_runtime_policy.dart';
import '../../data/datasources/remote/noop_social_remote_datasource.dart';
import '../../data/datasources/remote/social_remote_datasource.dart';
import '../../data/datasources/remote/supabase_social_remote_datasource.dart';
import '../../data/repositories/social_repository_impl.dart';
import '../../domain/repositories/social_repository.dart';

void registerSocialModule(GetIt sl) {
  sl.registerLazySingleton<SocialRemoteDataSource>(
    () => sl<RemoteSyncRuntimePolicy>().isRemoteSyncConfigured
        ? SupabaseSocialRemoteDataSource(clientProvider: sl())
        : const NoopSocialRemoteDataSource(),
  );

  sl.registerLazySingleton<SocialRepository>(
    () => SocialRepositoryImpl(remoteDataSource: sl()),
  );
}
