import 'package:get_it/get_it.dart';
import '../data/datasources/local/database_helper.dart';
import '../data/datasources/local/target_local_datasource.dart';
import '../data/datasources/local/workout_set_local_datasource.dart';
import '../data/datasources/local/exercise_local_datasource.dart';
import '../data/repositories/target_repository_impl.dart';
import '../data/repositories/workout_set_repository_impl.dart';
import '../data/repositories/exercise_repository_impl.dart';
import '../domain/repositories/target_repository.dart';
import '../domain/repositories/workout_set_repository.dart';
import '../domain/repositories/exercise_repository.dart';
import '../domain/usecases/targets/add_target.dart';
import '../domain/usecases/targets/delete_target.dart';
import '../domain/usecases/targets/get_all_targets.dart';
import '../domain/usecases/targets/update_target.dart';
import '../domain/usecases/workout_sets/add_workout_set.dart';
import '../domain/usecases/workout_sets/get_all_workout_sets.dart';
import '../domain/usecases/workout_sets/get_weekly_sets.dart';
import '../domain/usecases/exercises/get_all_exercises.dart';
import '../domain/usecases/exercises/get_exercise_by_id.dart';
import '../domain/usecases/exercises/get_exercises_for_muscle.dart';
import '../domain/usecases/exercises/add_exercise.dart';
import '../domain/usecases/exercises/update_exercise.dart';
import '../domain/usecases/exercises/delete_exercise.dart';
import '../presentation/pages/home/bloc/home_bloc.dart';
import '../presentation/pages/log_set/bloc/log_set_bloc.dart';
import '../presentation/pages/targets/bloc/targets_bloc.dart';
import '../presentation/pages/exercises/bloc/exercise_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ==================== BLoCs ====================
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

  sl.registerFactory(() => ExerciseBloc(
        getAllExercises: sl(),
        getExerciseById: sl(),
        getExercisesForMuscle: sl(),
        addExercise: sl(),
        updateExercise: sl(),
        deleteExercise: sl(),
      ));

  // ==================== Use Cases ====================
  
  // Targets
  sl.registerLazySingleton(() => GetAllTargets(sl()));
  sl.registerLazySingleton(() => AddTarget(sl()));
  sl.registerLazySingleton(() => UpdateTarget(sl()));
  sl.registerLazySingleton(() => DeleteTarget(sl()));

  // Workout Sets
  sl.registerLazySingleton(() => AddWorkoutSet(sl()));
  sl.registerLazySingleton(() => GetAllWorkoutSets(sl()));
  sl.registerLazySingleton(() => GetWeeklySets(sl()));

  // Exercises
  sl.registerLazySingleton(() => GetAllExercises(sl()));
  sl.registerLazySingleton(() => GetExerciseById(sl()));
  sl.registerLazySingleton(() => GetExercisesForMuscle(sl()));
  sl.registerLazySingleton(() => AddExercise(sl()));
  sl.registerLazySingleton(() => UpdateExercise(sl()));
  sl.registerLazySingleton(() => DeleteExercise(sl()));

  // ==================== Repositories ====================
  sl.registerLazySingleton<TargetRepository>(
    () => TargetRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<WorkoutSetRepository>(
    () => WorkoutSetRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepositoryImpl(localDataSource: sl()),
  );

  // ==================== Data Sources ====================
  sl.registerLazySingleton<TargetLocalDataSource>(
    () => TargetLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<WorkoutSetLocalDataSource>(
    () => WorkoutSetLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<ExerciseLocalDataSource>(
    () => ExerciseLocalDataSourceImpl(databaseHelper: sl()),
  );

  // ==================== Core ====================
  sl.registerLazySingleton(() => DatabaseHelper());

  // Initialize database
  await sl<DatabaseHelper>().database;
}
