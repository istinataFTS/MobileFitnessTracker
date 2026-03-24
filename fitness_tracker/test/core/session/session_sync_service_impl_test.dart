import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/config/app_sync_policy.dart';
import 'package:fitness_tracker/core/enums/sync_trigger.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/core/session/session_sync_service.dart';
import 'package:fitness_tracker/core/session/session_sync_service_impl.dart';
import 'package:fitness_tracker/core/sync/sync_feature.dart';
import 'package:fitness_tracker/core/sync/sync_orchestrator.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/domain/repositories/app_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSessionRepository extends Mock implements AppSessionRepository {}

class MockSyncOrchestrator extends Mock implements SyncOrchestrator {}

void main() {
  late MockAppSessionRepository repository;
  late MockSyncOrchestrator syncOrchestrator;
  late SessionSyncService service;

  const user = AppUser(
    id: 'user-1',
    email: 'user@test.com',
    displayName: 'Marin',
  );

  const completedSyncResult = SyncRunResult(
    status: SyncRunStatus.completed,
    trigger: SyncTrigger.initialSignIn,
    message: 'ok',
    featureResults: <SyncFeatureRunResult>[],
  );

  setUp(() {
    repository = MockAppSessionRepository();
    syncOrchestrator = MockSyncOrchestrator();

    when(() => repository.syncPolicy)
        .thenReturn(AppSyncPolicy.productionDefault);

    service = SessionSyncServiceImpl(
      appSessionRepository: repository,
      syncOrchestrator: syncOrchestrator,
    );
  });

  test('persists session, runs initial sign-in sync, and completes migration', () async {
    when(
      () => repository.startAuthenticatedSession(
        any(),
        requiresInitialCloudMigration: any(named: 'requiresInitialCloudMigration'),
      ),
    ).thenAnswer((_) async => const Right(null));

    when(() => syncOrchestrator.run(SyncTrigger.initialSignIn))
        .thenAnswer((_) async => completedSyncResult);

    when(() => repository.completeInitialCloudMigration())
        .thenAnswer((_) async => const Right(null));

    final result = await service.establishAuthenticatedSession(user);

    expect(result.isSuccess, isTrue);
    expect(
      result.message,
      'authenticated session established and initial migration completed',
    );

    verify(
      () => repository.startAuthenticatedSession(
        user,
        requiresInitialCloudMigration: true,
      ),
    ).called(1);
    verify(() => syncOrchestrator.run(SyncTrigger.initialSignIn)).called(1);
    verify(() => repository.completeInitialCloudMigration()).called(1);
  });

  test('fails when authenticated session cannot be persisted', () async {
    when(
      () => repository.startAuthenticatedSession(
        any(),
        requiresInitialCloudMigration: any(named: 'requiresInitialCloudMigration'),
      ),
    ).thenAnswer(
      (_) async => const Left(CacheFailure(message: 'write failed')),
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

  test('fails when initial sign-in sync fails', () async {
    when(
      () => repository.startAuthenticatedSession(
        any(),
        requiresInitialCloudMigration: any(named: 'requiresInitialCloudMigration'),
      ),
    ).thenAnswer((_) async => const Right(null));

    when(() => syncOrchestrator.run(SyncTrigger.initialSignIn)).thenAnswer(
      (_) async => const SyncRunResult(
        status: SyncRunStatus.failed,
        trigger: SyncTrigger.initialSignIn,
        message: 'sync failed',
        featureResults: <SyncFeatureRunResult>[],
      ),
    );

    final result = await service.establishAuthenticatedSession(user);

    expect(result.isFailure, isTrue);
    expect(result.message, 'initial sign-in sync failed: sync failed');

    verifyNever(() => repository.completeInitialCloudMigration());
  });

  test('fails when migration finalization fails after successful sync', () async {
    when(
      () => repository.startAuthenticatedSession(
        any(),
        requiresInitialCloudMigration: any(named: 'requiresInitialCloudMigration'),
      ),
    ).thenAnswer((_) async => const Right(null));

    when(() => syncOrchestrator.run(SyncTrigger.initialSignIn))
        .thenAnswer((_) async => completedSyncResult);

    when(() => repository.completeInitialCloudMigration()).thenAnswer(
      (_) async => const Left(CacheFailure(message: 'metadata write failed')),
    );

    final result = await service.establishAuthenticatedSession(user);

    expect(result.isFailure, isTrue);
    expect(
      result.message,
      'initial sign-in sync completed but migration finalization failed: metadata write failed',
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

  test('manual refresh returns skipped result when orchestration is skipped', () async {
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
  });
}