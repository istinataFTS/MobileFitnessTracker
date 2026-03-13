import 'package:get_it/get_it.dart';

import '../../data/datasources/local/meal_local_datasource.dart';
import '../../data/datasources/local/meal_local_datasource_impl.dart';
import '../../data/datasources/local/nutrition_log_local_datasource.dart';
import '../../data/repositories/meal_repository_impl.dart';
import '../../data/repositories/nutrition_log_repository_impl.dart';
import '../../domain/repositories/meal_repository.dart';
import '../../domain/repositories/nutrition_log_repository.dart';
import '../../domain/usecases/meals/add_meal.dart';
import '../../domain/usecases/meals/delete_meal.dart';
import '../../domain/usecases/meals/get_all_meals.dart';
import '../../domain/usecases/meals/get_meal_by_id.dart';
import '../../domain/usecases/meals/get_meal_by_name.dart';
import '../../domain/usecases/meals/update_meal.dart';
import '../../domain/usecases/nutrition_logs/add_nutrition_log.dart';
import '../../domain/usecases/nutrition_logs/delete_nutrition_log.dart';
import '../../domain/usecases/nutrition_logs/get_daily_macros.dart';
import '../../domain/usecases/nutrition_logs/get_logs_by_date_range.dart';
import '../../domain/usecases/nutrition_logs/get_logs_for_date.dart';
import '../../domain/usecases/nutrition_logs/update_nutrition_log.dart';
import '../../presentation/pages/meals/bloc/meal_bloc.dart';
import '../../presentation/pages/nutrition_log/bloc/nutrition_log_bloc.dart';

void registerMealsNutritionModule(GetIt sl) {
  sl.registerFactory(
    () => MealBloc(
      getAllMeals: sl(),
      getMealById: sl(),
      getMealByName: sl(),
      addMeal: sl(),
      updateMeal: sl(),
      deleteMeal: sl(),
    ),
  );

  sl.registerFactory(
    () => NutritionLogBloc(
      getLogsForDate: sl(),
      addNutritionLog: sl(),
      updateNutritionLog: sl(),
      deleteNutritionLog: sl(),
      getDailyMacros: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetAllMeals(sl()));
  sl.registerLazySingleton(() => GetMealById(sl()));
  sl.registerLazySingleton(() => GetMealByName(sl()));
  sl.registerLazySingleton(() => AddMeal(sl()));
  sl.registerLazySingleton(() => UpdateMeal(sl()));
  sl.registerLazySingleton(() => DeleteMeal(sl()));

  sl.registerLazySingleton(() => GetLogsForDate(sl()));
  sl.registerLazySingleton(() => GetLogsByDateRange(sl()));
  sl.registerLazySingleton(() => AddNutritionLog(sl()));
  sl.registerLazySingleton(() => UpdateNutritionLog(sl()));
  sl.registerLazySingleton(() => DeleteNutritionLog(sl()));
  sl.registerLazySingleton(() => GetDailyMacros(sl()));

  sl.registerLazySingleton<MealRepository>(
    () => MealRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<NutritionLogRepository>(
    () => NutritionLogRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<MealLocalDataSource>(
    () => MealLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<NutritionLogLocalDataSource>(
    () => NutritionLogLocalDataSourceImpl(databaseHelper: sl()),
  );
}