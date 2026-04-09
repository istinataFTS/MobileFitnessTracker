import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/config/app_sync_policy.dart';
import 'package:fitness_tracker/core/enums/sync_trigger.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/core/session/session_sync_service.dart';
import 'package:fitness_tracker/core/session/session_sync_service_impl.dart';
import 'package:fitness_tracker/core/sync/sync_feature.dart';
import 'package:fitness_tracker/core/sync/sync_orchestrator.dart';
import 'package:fitness_tracker/data/datasources/local/meal_local_datasource.dart';
import 'package:fitness_tracker/data/datasources/local/nutrition_log_local_datasource.dart';
import 'package:fitness_tracker/data/datasources/local/target_local_datasource.dart';
import 'package:fitness_tracker/data/datasources/local/workout_set_local_datasource.dart';
import 'package:fitness_tracker/data/datasources/remote/auth_remote_datasource.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/domain/repositories/app_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSessionRepository extends Mock implements AppSessionRepository {}

class MockSyncOrchestrator extends Mock implements SyncOrchestrator {}

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockMealLocalDataSource extends Mock implements MealLocalDataSource {}

class MockNutritionLogLocalDataSource extends Mock
    implements NutritionLogLocalDataSource {}

class MockTargetLocalDataSource extends Mock implements TargetLocalDataSource {}

class MockWorkoutSetLocalDataSource extends Mock
    implements WorkoutSetLocalDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(const AppUser(id: '', email: ''));
    registerFallbackValue(SyncTrigger.initialSignIn);
  });

  late MockAppSessionRepository repository;
  late MockSyncOrchestrator syncOrchestrator;
  late MockAuthRemoteDataSource authRemoteDataSource;
  late MockMealLocalDataSource mealLocalDataSource;
  late MockNutritionLogLocalDataSource nutritionLogLocalDataSource;
  late MockTargetLocalDataSource targetLocalDataSource;
  late MockWorkoutSetLocalDataSource workoutSetLocalDataSource;
  late SessionSyncService service;

  const user = AppUser(
    id: 'user-1',
    email: 'user@test.com',
    displayName: 'Marin',
  );

  setUp(() {
    repository = MockAppSessionRepository();
    syncOrchestrator = MockSyncOrchestrator();
    authRemoteDataSource = MockAuthRemoteDataSource();
    mealLocalDataSource = MockMealLocalDataSource();
    nutritionLogLocalDataSource = MockNutritionLogLocalDataSource();
    targetLocalDataSource = MockTargetLocalDataSource();
    workoutSetLocalDataSource = MockWorkoutSetLocalDataSource();

    when(() => repository.syncPolicy).thenReturn(AppSyncPolicy.productionDefault);

    // Default stubs so tests that don't exercise these paths don't crash
    when(() => authRemoteDataSource.signOut()).thenAnswer((_) async {});
    when(() => repository.clearSession())
        .thenAnswer((_) async => const Right(null));
    when(() => mealLocalDataSource.clearAllMeals()).thenAnswer((_) async {});
    when(() => nutritionLogLocalDataSource.clearAllLogs())
        .thenAnswer((_) async {});
    when(() => targetLocalDataSource.clearAllTargets())
        .thenAnswer((_) async {});
    when(() => workoutSetLocalDataSource.clearAllSets())
        .thenAnswer((_) async {});

    service = SessionSyncServiceImpl(
      appSessionRepository: repository,
      authRemoteDataSource: authRemoteDataSource,
      syncOrchestrator: syncOrchestrator,
      mealLocalDataSource: mealLocalDataSource,
      nutritionLogLocalDataSource: nutritionLogLocalDataSource,
      targetLocalDataSource: targetLocalDataSource,
      workoutSetLocalDataSource: workoutSetLocalDataSource,
    );
  });

  test('persists session and delegates initial sign-in flow to orchestrator',
      () async {
    when(
      () => repository.startAuthenticatedSession(
        any(),
        requiresInitialCloudMigration:
            any(named: 'requiresInitialCloudMigration'),
      ),
    ).thenAnswer((_) async => const Right(null));

    when(() => syncOrchestrator.run(SyncTrigger.initialSignIn)).thenAnswer(
      (_) async => const SyncRunResult(
        status: SyncRunStatus.completed,
        trigger: SyncTrigger.initialSignIn,
        message: 'initial cloud migration completed successfully',
        featureResults: <SyncFeatureRunResult>[],
      ),
    );

    final result = await service.establishAuthenticatedSession(user);

    expect(result.isSuccess, isTrue);
    expect(result.message, 'authenticated session established');

    verify(
      () => repository.startAuthenticatedSession(
        user,
        requiresInitialCloudMigration: true,
      ),
    ).called(1);
    verify(() => syncOrchestrator.run(SyncTrigger.initialSignIn)).called(1);
    verifyNever(() => repository.completeInitialCloudMigration());
  });

  test('fails when authenticated session cannot be persisted', () async {
    when(
      () => repository.startAuthenticatedSession(
        any(),
        requiresInitialCloudMigration:
            any(named: 'requiresInitialCloudMigration'),
      ),
    ).thenAnswer(
      (_) async => const Left(CacheFailure('write failed')),
    );

    final result = await service.establishAuthenticatedSession(user);

    expect(result.isFailure, isTrue);
    expect(
      result.message,
      'failed to persist authenticated session: write failed',
    );

    verifyNever(() => syncOrchestrator.run(any()));
    verifyNever(() => repository.completeInitialCloudMigration());
  });

  test('fails when initial sign-in orchestration fails', () async {
    when(
      () => repository.startAuthenticatedSession(
        any(),
        requiresInitialCloudMigration:
            any(named: 'requiresInitialCloudMigration'),
      ),
    ).thenAnswer((_) async => const Right(null));

    when(() => syncOrchestrator.run(SyncTrigger.initialSignIn)).thenAnswer(
      (_) async => const SyncRunResult(
        status: SyncRunStatus.failed,
        trigger: SyncTrigger.initialSignIn,
        message: 'initial cloud migration failed',
        featureResults: <SyncFeatureRunResult>[],
      ),
    );

    final result = await service.establishAuthenticatedSession(user);

    expect(result.isFailure, isTrue);
    expect(
      result.message,
      'initial sign-in sync failed: initial cloud migration failed',
    );
  });

  test('skips when initial sign-in orchestration is skipped', () async {
    when(
      () => repository.startAuthenticatedSession(
        any(),
        requiresInitialCloudMigration:
            any(named: 'requiresInitialCloudMigration'),
      ),
    ).thenAnswer((_) async => const Right(null));

    when(() => syncOrchestrator.run(SyncTrigger.initialSignIn)).thenAnswer(
      (_) async => const SyncRunResult(
        status: SyncRunStatus.skipped,
        trigger: SyncTrigger.initialSignIn,
        message: 'initial cloud migration already completed',
        featureResults: <SyncFeatureRunResult>[],
      ),
    );

    final result = await service.establishAuthenticatedSession(user);

    expect(result.isSkipped, isTrue);
    expect(
      result.message,
      'initial sign-in sync skipped: initial cloud migration already completed',
    );
  });

  test('manual refresh delegates to manual refresh sync trigger', () async {
    when(() => syncOrchestrator.run(SyncTrigger.manualRefresh)).thenAnswer(
      (_) async => const SyncRunResult(
        status: SyncRunStatus.completed,
        trigger: SyncTrigger.manualRefresh,
        message: 'refresh ok',
        featureResults: <SyncFeatureRunResult>[],
      ),
    );

    final result = await service.runManualRefresh();

    expect(result.isSuccess, isTrue);
    expect(result.message, 'manual refresh completed successfully');

    verify(() => syncOrchestrator.run(SyncTrigger.manualRefresh)).called(1);
  });

  test(
    'manual refresh returns skipped result when orchestration is skipped',
    () async {
      when(() => syncOrchestrator.run(SyncTrigger.manualRefresh)).thenAnswer(
        (_) async => const SyncRunResult(
          status: SyncRunStatus.skipped,
          trigger: SyncTrigger.manualRefresh,
          message: 'session is not authenticated',
          featureResults: <SyncFeatureRunResult>[],
        ),
      );

      final result = await service.runManualRefresh();

      expect(result.isSkipped, isTrue);
      expect(
        result.message,
        'manual refresh skipped: session is not authenticated',
      );
    },
  );

  test('signOut signs out remotely, clears session, and wipes local data',
      () async {
    final result = await service.signOut();

    expect(result.isSuccess, isTrue);
    expect(result.message, 'sign-out completed successfully');

    verify(() => authRemoteDataSource.signOut()).called(1);
    verify(() => repository.clearSession()).called(1);
    verify(() => mealLocalDataSource.clearAllMeals()).called(1);
    verify(() => nutritionLogLocalDataSource.clearAllLogs()).called(1);
    verify(() => targetLocalDataSource.clearAllTargets()).called(1);
    verify(() => workoutSetLocalDataSource.clearAllSets()).called(1);
  });

  test('signOut fails when remote sign-out throws', () async {
    when(() => authRemoteDataSource.signOut())
        .thenThrow('remote sign-out failed');

    final result = await service.signOut();

    expect(result.isFailure, isTrue);
    expect(result.message, 'sign-out failed: remote sign-out failed');

    verifyNever(() => repository.clearSession());
    verifyNever(() => mealLocalDataSource.clearAllMeals());
    verifyNever(() => nutritionLogLocalDataSource.clearAllLogs());
    verifyNever(() => targetLocalDataSource.clearAllTargets());
    verifyNever(() => workoutSetLocalDataSource.clearAllSets());
  });

  test('signOut fails when local session clear fails', () async {
    when(() => repository.clearSession()).thenAnswer(
      (_) async => const Left(CacheFailure('session reset failed')),
    );

    final result = await service.signOut();

    expect(result.isFailure, isTrue);
    expect(
      result.message,
      'sign-out succeeded remotely but local session reset failed: session reset failed',
    );

    // Data clearing must not happen if the session itself failed to clear
    verifyNever(() => mealLocalDataSource.clearAllMeals());
    verifyNever(() => nutritionLogLocalDataSource.clearAllLogs());
    verifyNever(() => targetLocalDataSource.clearAllTargets());
    verifyNever(() => workoutSetLocalDataSource.clearAllSets());
  });
}
