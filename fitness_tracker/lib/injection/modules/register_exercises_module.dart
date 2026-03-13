import 'package:get_it/get_it.dart';

import '../../data/datasources/local/exercise_local_datasource.dart';
import '../../data/repositories/exercise_repository_impl.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../../domain/usecases/exercises/add_exercise.dart';
import '../../domain/usecases/exercises/delete_exercise.dart';
import '../../domain/usecases/exercises/get_all_exercises.dart';
import '../../domain/usecases/exercises/get_exercise_by_id.dart';
import '../../domain/usecases/exercises/get_exercises_for_muscle.dart';
import '../../domain/usecases/exercises/seed_exercises.dart';
import '../../domain/usecases/exercises/update_exercise.dart';
import '../../presentation/pages/exercises/bloc/exercise_bloc.dart';

void registerExercisesModule(GetIt sl) {
  sl.registerFactory(
    () => ExerciseBloc(
      getAllExercises: sl(),
      getExerciseById: sl(),
      getExercisesForMuscle: sl(),
      addExercise: sl(),
      updateExercise: sl(),
      deleteExercise: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetAllExercises(sl()));
  sl.registerLazySingleton(() => GetExerciseById(sl()));
  sl.registerLazySingleton(() => GetExercisesForMuscle(sl()));
  sl.registerLazySingleton(() => AddExercise(sl()));
  sl.registerLazySingleton(() => UpdateExercise(sl()));
  sl.registerLazySingleton(() => DeleteExercise(sl()));
  sl.registerLazySingleton(() => SeedExercises(sl()));

  sl.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<ExerciseLocalDataSource>(
    () => ExerciseLocalDataSourceImpl(databaseHelper: sl()),
  );
}