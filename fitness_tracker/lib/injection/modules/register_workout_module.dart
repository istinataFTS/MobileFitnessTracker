import 'package:get_it/get_it.dart';

import '../../data/datasources/local/pending_sync_delete_local_datasource.dart';
import '../../data/datasources/local/pending_sync_delete_local_datasource_impl.dart';
import '../../data/datasources/local/workout_set_local_datasource.dart';
import '../../data/datasources/local/workout_set_local_datasource_impl.dart';
import '../../data/datasources/remote/noop_workout_set_remote_datasource.dart';
import '../../data/datasources/remote/workout_set_remote_datasource.dart';
import '../../data/repositories/workout_set_repository_impl.dart';
import '../../data/sync/workout_set_sync_coordinator.dart';
import '../../data/sync/workout_set_sync_coordinator_impl.dart';
import '../../domain/repositories/workout_set_repository.dart';
import '../../domain/usecases/workout_sets/add_workout_set.dart';
import '../../domain/usecases/workout_sets/delete_workout_set.dart';
import '../../domain/usecases/workout_sets/get_all_workout_sets.dart';
import '../../domain/usecases/workout_sets/get_sets_by_date_range.dart';
import '../../domain/usecases/workout_sets/get_weekly_sets.dart';
import '../../domain/usecases/workout_sets/update_workout_set.dart';
import '../../presentation/pages/log/bloc/workout_bloc.dart';

void registerWorkoutModule(GetIt sl) {
  sl.registerFactory(
    () => WorkoutBloc(
      addWorkoutSet: sl(),
      getWeeklySets: sl(),
      recordWorkoutSet: sl(),
    ),
  );

  sl.registerLazySingleton(() => AddWorkoutSet(sl()));
  sl.registerLazySingleton(() => GetAllWorkoutSets(sl()));
  sl.registerLazySingleton(() => GetWeeklySets(sl()));
  sl.registerLazySingleton(
    () => GetSetsByDateRange(
      workoutSetRepository: sl(),
      exerciseRepository: sl(),
    ),
  );
  sl.registerLazySingleton(() => DeleteWorkoutSet(sl()));
  sl.registerLazySingleton(() => UpdateWorkoutSet(sl()));

  sl.registerLazySingleton<WorkoutSetRepository>(
    () => WorkoutSetRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      syncCoordinator: sl(),
    ),
  );

  sl.registerLazySingleton<WorkoutSetSyncCoordinator>(
    () => WorkoutSetSyncCoordinatorImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      pendingSyncDeleteLocalDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<WorkoutSetLocalDataSource>(
    () => WorkoutSetLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<PendingSyncDeleteLocalDataSource>(
    () => PendingSyncDeleteLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<WorkoutSetRemoteDataSource>(
    NoopWorkoutSetRemoteDataSource.new,
  );
}