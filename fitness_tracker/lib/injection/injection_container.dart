import 'package:get_it/get_it.dart';
import '../data/datasources/local/database_helper.dart';
import '../data/datasources/local/target_local_datasource.dart';
import '../data/datasources/local/workout_set_local_datasource.dart';
import '../data/repositories/target_repository_impl.dart';
import '../data/repositories/workout_set_repository_impl.dart';
import '../domain/repositories/target_repository.dart';
import '../domain/repositories/workout_set_repository.dart';
import '../domain/usecases/targets/add_target.dart';
import '../domain/usecases/targets/delete_target.dart';
import '../domain/usecases/targets/get_all_targets.dart';
import '../domain/usecases/targets/update_target.dart';
import '../domain/usecases/workout_sets/add_workout_set.dart';
import '../domain/usecases/workout_sets/get_all_workout_sets.dart';
import '../domain/usecases/workout_sets/get_weekly_sets.dart';
import '../presentation/pages/home/bloc/home_bloc.dart';
import '../presentation/pages/log_set/bloc/log_set_bloc.dart';
import '../presentation/pages/targets/bloc/targets_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ========== BLoCs ==========
  sl.registerFactory(() => TargetsBloc(
        getAllTargets: sl(),
        addTarget: sl(),
        updateTarget: sl(),
        deleteTarget: sl(),
      ));

  sl.registerFactory(() => LogSetBloc(
        addWorkoutSet: sl(),
        getAllTargets: sl(),
        getWeeklySets: sl(),
      ));

  sl.registerFactory(() => HomeBloc(
        getAllTargets: sl(),
        getWeeklySets: sl(),
      ));

  // ========== Use Cases ==========
  // Targets
  sl.registerLazySingleton(() => GetAllTargets(sl()));
  sl.registerLazySingleton(() => AddTarget(sl()));
  sl.registerLazySingleton(() => UpdateTarget(sl()));
  sl.registerLazySingleton(() => DeleteTarget(sl()));

  // Workout Sets
  sl.registerLazySingleton(() => AddWorkoutSet(sl()));
  sl.registerLazySingleton(() => GetAllWorkoutSets(sl()));
  sl.registerLazySingleton(() => GetWeeklySets(sl()));

  // ========== Repositories ==========
  sl.registerLazySingleton<TargetRepository>(
    () => TargetRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<WorkoutSetRepository>(
    () => WorkoutSetRepositoryImpl(localDataSource: sl()),
  );

  // ========== Data Sources ==========
  sl.registerLazySingleton<TargetLocalDataSource>(
    () => TargetLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<WorkoutSetLocalDataSource>(
    () => WorkoutSetLocalDataSourceImpl(databaseHelper: sl()),
  );

  // ========== Core ==========
  sl.registerLazySingleton(() => DatabaseHelper());

  // Initialize database
  await sl<DatabaseHelper>().database;
}