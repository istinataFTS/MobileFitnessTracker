import 'package:get_it/get_it.dart';
import '../data/datasources/local/database_helper.dart';
import '../data/datasources/local/target_local_datasource.dart';
import '../data/datasources/local/workout_set_local_datasource.dart';
import '../data/datasources/local/exercise_local_datasource.dart';
import '../data/datasources/local/meal_local_datasource.dart';
import '../data/datasources/local/nutrition_log_local_datasource.dart';
import '../data/datasources/local/muscle_factor_local_datasource.dart';
import '../data/repositories/target_repository_impl.dart';
import '../data/repositories/workout_set_repository_impl.dart';
import '../data/repositories/exercise_repository_impl.dart';
import '../data/repositories/meal_repository_impl.dart';
import '../data/repositories/nutrition_log_repository_impl.dart';
import '../data/repositories/muscle_factor_repository_impl.dart';
import '../domain/repositories/target_repository.dart';
import '../domain/repositories/workout_set_repository.dart';
import '../domain/repositories/exercise_repository.dart';
import '../domain/repositories/meal_repository.dart';
import '../domain/repositories/nutrition_log_repository.dart';
import '../domain/repositories/muscle_factor_repository.dart';
import '../domain/usecases/targets/add_target.dart';
import '../domain/usecases/targets/delete_target.dart';
import '../domain/usecases/targets/get_all_targets.dart';
import '../domain/usecases/targets/update_target.dart';
import '../domain/usecases/workout_sets/add_workout_set.dart';
import '../domain/usecases/workout_sets/get_all_workout_sets.dart';
import '../domain/usecases/workout_sets/get_weekly_sets.dart';
import '../domain/usecases/workout_sets/get_sets_by_date_range.dart';
import '../domain/usecases/workout_sets/delete_workout_set.dart';
import '../domain/usecases/workout_sets/update_workout_set.dart';
import '../domain/usecases/exercises/get_all_exercises.dart';
import '../domain/usecases/exercises/get_exercise_by_id.dart';
import '../domain/usecases/exercises/get_exercises_for_muscle.dart';
import '../domain/usecases/exercises/add_exercise.dart';
import '../domain/usecases/exercises/update_exercise.dart';
import '../domain/usecases/exercises/delete_exercise.dart';
import '../domain/usecases/exercises/seed_exercises.dart';
import '../domain/usecases/meals/get_all_meals.dart';
import '../domain/usecases/meals/get_meal_by_id.dart';
import '../domain/usecases/meals/get_meal_by_name.dart';
import '../domain/usecases/meals/add_meal.dart';
import '../domain/usecases/meals/update_meal.dart';
import '../domain/usecases/meals/delete_meal.dart';
import '../domain/usecases/nutrition_logs/get_logs_for_date.dart';
import '../domain/usecases/nutrition_logs/add_nutrition_log.dart';
import '../domain/usecases/nutrition_logs/update_nutrition_log.dart';
import '../domain/usecases/nutrition_logs/delete_nutrition_log.dart';
import '../domain/usecases/nutrition_logs/get_daily_macros.dart';
import '../domain/usecases/muscle_factors/seed_exercise_factors.dart';
import '../presentation/pages/home/bloc/home_bloc.dart';
import '../presentation/pages/log_set/bloc/log_set_bloc.dart';
import '../presentation/pages/targets/bloc/targets_bloc.dart';
import '../presentation/pages/exercises/bloc/exercise_bloc.dart';
import '../presentation/pages/history/bloc/history_bloc.dart';
import '../presentation/pages/meals/bloc/meal_bloc.dart';
import '../presentation/pages/nutrition_log/bloc/nutrition_log_bloc.dart';

final sl = GetIt.instance;

/// Initialize all dependencies following Clean Architecture principles
/// 
/// Registration order:
/// 1. BLoCs (Factory - new instance per request)
/// 2. Use Cases (Lazy Singleton - single instance, created on first use)
/// 3. Repositories (Lazy Singleton)
/// 4. Data Sources (Lazy Singleton)
/// 5. Core/External (Lazy Singleton)
Future<void> init() async {
  // ==================== BLoCs ====================
  // Factory registration creates new instance for each BlocProvider
  
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

  sl.registerFactory(() => HistoryBloc(
        getAllWorkoutSets: sl(),
        getSetsByDateRange: sl(),
        deleteWorkoutSet: sl(),
        updateWorkoutSet: sl(),
      ));

  sl.registerFactory(() => MealBloc(
        getAllMeals: sl(),
        getMealById: sl(),
        getMealByName: sl(),
        addMeal: sl(),
        updateMeal: sl(),
        deleteMeal: sl(),
      ));

  sl.registerFactory(() => NutritionLogBloc(
        getLogsForDate: sl(),
        addNutritionLog: sl(),
        updateNutritionLog: sl(),
        deleteNutritionLog: sl(),
        getDailyMacros: sl(),
      ));

  // ==================== Use Cases ====================
  // Lazy Singleton registration creates single instance on first use
  
  // Targets
  sl.registerLazySingleton(() => GetAllTargets(sl()));
  sl.registerLazySingleton(() => AddTarget(sl()));
  sl.registerLazySingleton(() => UpdateTarget(sl()));
  sl.registerLazySingleton(() => DeleteTarget(sl()));

  // Workout Sets
  sl.registerLazySingleton(() => AddWorkoutSet(sl()));
  sl.registerLazySingleton(() => GetAllWorkoutSets(sl()));
  sl.registerLazySingleton(() => GetWeeklySets(sl()));
  sl.registerLazySingleton(() => GetSetsByDateRange(
        workoutSetRepository: sl(),
        exerciseRepository: sl(),
      ));
  sl.registerLazySingleton(() => DeleteWorkoutSet(sl()));
  sl.registerLazySingleton(() => UpdateWorkoutSet(sl()));

  // Exercises
  sl.registerLazySingleton(() => GetAllExercises(sl()));
  sl.registerLazySingleton(() => GetExerciseById(sl()));
  sl.registerLazySingleton(() => GetExercisesForMuscle(sl()));
  sl.registerLazySingleton(() => AddExercise(sl()));
  sl.registerLazySingleton(() => UpdateExercise(sl()));
  sl.registerLazySingleton(() => DeleteExercise(sl()));
  sl.registerLazySingleton(() => SeedExercises(sl()));

  // ⭐ NEW: Muscle Factors
  sl.registerLazySingleton(() => SeedExerciseFactors(
        muscleFactorRepository: sl(),
        exerciseRepository: sl(),
      ));

  // Meals
  sl.registerLazySingleton(() => GetAllMeals(sl()));
  sl.registerLazySingleton(() => GetMealById(sl()));
  sl.registerLazySingleton(() => GetMealByName(sl()));
  sl.registerLazySingleton(() => AddMeal(sl()));
  sl.registerLazySingleton(() => UpdateMeal(sl()));
  sl.registerLazySingleton(() => DeleteMeal(sl()));

  // Nutrition Logs
  sl.registerLazySingleton(() => GetLogsForDate(sl()));
  sl.registerLazySingleton(() => AddNutritionLog(sl()));
  sl.registerLazySingleton(() => UpdateNutritionLog(sl()));
  sl.registerLazySingleton(() => DeleteNutritionLog(sl()));
  sl.registerLazySingleton(() => GetDailyMacros(sl()));

  // ==================== Repositories ====================
  // Interface to Implementation mapping
  
  sl.registerLazySingleton<TargetRepository>(
    () => TargetRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<WorkoutSetRepository>(
    () => WorkoutSetRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<MealRepository>(
    () => MealRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<NutritionLogRepository>(
    () => NutritionLogRepositoryImpl(localDataSource: sl()),
  );

  // ⭐ NEW: Muscle Factor Repository
  sl.registerLazySingleton<MuscleFactorRepository>(
    () => MuscleFactorRepositoryImpl(localDataSource: sl()),
  );

  // ==================== Data Sources ====================
  // Local database access layer
  
  sl.registerLazySingleton<TargetLocalDataSource>(
    () => TargetLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<WorkoutSetLocalDataSource>(
    () => WorkoutSetLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<ExerciseLocalDataSource>(
    () => ExerciseLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<MealLocalDataSource>(
    () => MealLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<NutritionLogLocalDataSource>(
    () => NutritionLogLocalDataSourceImpl(databaseHelper: sl()),
  );

  // ⭐ NEW: Muscle Factor Data Source
  sl.registerLazySingleton<MuscleFactorLocalDataSource>(
    () => MuscleFactorLocalDataSourceImpl(databaseHelper: sl()),
  );

  // ==================== Core ====================
  // Shared database helper
  sl.registerLazySingleton(() => DatabaseHelper());

  // Initialize database (ensures tables are created)
  await sl<DatabaseHelper>().database;
}