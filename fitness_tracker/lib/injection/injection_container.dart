import 'dart:async';

import 'package:get_it/get_it.dart';

import '../core/auth/auth_session_service.dart';
import '../core/auth/auth_session_service_impl.dart';
import '../core/session/session_sync_service.dart';
import '../core/session/session_sync_service_impl.dart';
import '../core/sync/initial_cloud_migration_coordinator.dart';
import '../core/sync/initial_cloud_migration_coordinator_impl.dart';
import '../core/sync/initial_cloud_migration_step.dart';
import '../core/sync/sync_feature.dart';
import '../core/sync/sync_orchestrator.dart';
import '../core/sync/sync_orchestrator_impl.dart';
import '../data/datasources/local/database_helper.dart';
import '../data/sync/exercise_sync_coordinator.dart';
import '../data/sync/meal_sync_coordinator.dart';
import '../data/sync/nutrition_log_sync_coordinator.dart';
import '../data/sync/target_sync_coordinator.dart';
import '../data/sync/workout_set_sync_coordinator.dart';
import '../features/home/application/home_bloc.dart';
import '../features/home/application/usecases/load_home_dashboard_data.dart';
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
  sl.registerLazySingleton<List<InitialCloudMigrationStep>>(
    () => <InitialCloudMigrationStep>[
      InitialCloudMigrationStep(
        key: 'targets',
        run: (_) => sl<TargetSyncCoordinator>().syncPendingChanges(),
      ),
      InitialCloudMigrationStep(
        key: 'workout_sets',
        run: (_) => sl<WorkoutSetSyncCoordinator>().syncPendingChanges(),
      ),
      InitialCloudMigrationStep(
        key: 'exercises',
        run: (_) => sl<ExerciseSyncCoordinator>().syncPendingChanges(),
      ),
      InitialCloudMigrationStep(
        key: 'meals',
        run: (_) => sl<MealSyncCoordinator>().syncPendingChanges(),
      ),
      InitialCloudMigrationStep(
        key: 'nutrition_logs',
        run: (_) => sl<NutritionLogSyncCoordinator>().syncPendingChanges(),
      ),
    ],
  );

  sl.registerLazySingleton<InitialCloudMigrationCoordinator>(
    () => InitialCloudMigrationCoordinatorImpl(
      appSessionRepository: sl(),
      steps: sl(),
    ),
  );

  sl.registerLazySingleton<List<SyncFeature>>(
    () => <SyncFeature>[
      SyncFeature(
        name: 'targets',
        syncPendingChanges: sl<TargetSyncCoordinator>().syncPendingChanges,
      ),
      SyncFeature(
        name: 'workout_sets',
        syncPendingChanges: sl<WorkoutSetSyncCoordinator>().syncPendingChanges,
      ),
      SyncFeature(
        name: 'exercises',
        syncPendingChanges: sl<ExerciseSyncCoordinator>().syncPendingChanges,
      ),
      SyncFeature(
        name: 'meals',
        syncPendingChanges: sl<MealSyncCoordinator>().syncPendingChanges,
      ),
      SyncFeature(
        name: 'nutrition_logs',
        syncPendingChanges:
            sl<NutritionLogSyncCoordinator>().syncPendingChanges,
      ),
    ],
  );

  sl.registerLazySingleton<SyncOrchestrator>(
    () => SyncOrchestratorImpl(
      appSessionRepository: sl(),
      syncPolicy: sl(),
      remoteSyncAvailability: sl(),
      features: sl(),
    ),
  );

  sl.registerLazySingleton<SessionSyncService>(
    () => SessionSyncServiceImpl(
      appSessionRepository: sl(),
      authRemoteDataSource: sl(),
      syncOrchestrator: sl(),
      initialCloudMigrationCoordinator: sl(),
    ),
  );

  sl.registerLazySingleton<AuthSessionService>(
    () => AuthSessionServiceImpl(
      authRemoteDataSource: sl(),
      sessionSyncService: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => LoadHomeDashboardData(
      getAllTargets: sl(),
      getWeeklySets: sl(),
      getLogsForDate: sl(),
      getDailyMacros: sl(),
      getAllExercises: sl(),
    ),
  );

  sl.registerFactory(
    () => HomeBloc(
      loadHomeDashboardData: sl(),
    ),
  );
}