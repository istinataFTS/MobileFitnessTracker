import 'dart:async';

import 'package:get_it/get_it.dart';

import '../data/datasources/local/database_helper.dart';
import '../features/home/application/home_bloc.dart';
import 'modules/register_core_module.dart';
import 'modules/register_exercises_module.dart';
import 'modules/register_history_module.dart';
import 'modules/register_meals_nutrition_module.dart';
import 'modules/register_muscle_stimulus_module.dart';
import 'modules/register_targets_module.dart';
import 'modules/register_workout_module.dart';

final sl = GetIt.instance;

typedef ServiceOverrideRegistrar = FutureOr<void> Function(GetIt sl);

Future<void> init({
  bool openDatabase = false,
  ServiceOverrideRegistrar? registerOverrides,
}) async {
  await sl.reset(dispose: true);

  registerCoreModule(sl);
  registerTargetsModule(sl);
  registerWorkoutModule(sl);
  registerExercisesModule(sl);
  registerMealsNutritionModule(sl);
  registerMuscleStimulusModule(sl);
  registerHistoryModule(sl);
  _registerAppComposition(sl);

  if (registerOverrides != null) {
    await registerOverrides(sl);
  }

  if (openDatabase) {
    await sl<DatabaseHelper>().database;
  }
}

Future<void> resetDependencies() {
  return sl.reset(dispose: true);
}

void _registerAppComposition(GetIt sl) {
  sl.registerFactory(
    () => HomeBloc(
      getAllTargets: sl(),
      getWeeklySets: sl(),
      getLogsForDate: sl(),
      getDailyMacros: sl(),
      getAllExercises: sl(),
    ),
  );
}