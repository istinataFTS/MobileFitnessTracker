import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/config/app_sync_policy.dart';
import 'package:fitness_tracker/core/enums/sync_trigger.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/core/session/session_sync_service.dart';
import 'package:fitness_tracker/core/session/session_sync_service_impl.dart';
import 'package:fitness_tracker/core/sync/initial_cloud_migration_coordinator.dart';
import 'package:fitness_tracker/core/sync/sync_feature.dart';
import 'package:fitness_tracker/core/sync/sync_orchestrator.dart';
import 'package:fitness_tracker/data/datasources/remote/auth_remote_datasource.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/domain/repositories/app_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSessionRepository extends Mock implements AppSessionRepository {}

class MockSyncOrchestrator extends Mock implements SyncOrchestrator {}

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockInitialCloudMigrationCoordinator extends Mock
    implements InitialCloudMigrationCoordinator {}

void main() {
  late MockAppSessionRepository repository;
  late MockSyncOrchestrator syncOrchestrator;
  late MockAuthRemoteDataSource authRemoteDataSource;
  late MockInitialCloudMigrationCoordinator initialCloudMigrationCoordinator;
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
    authRemoteDataSource = MockAuthRemoteDataSource();
    initialCloudMigrationCoordinator = MockInitialCloudMigrationCoordinator();

    when(() => repository.syncPolicy)
        .thenReturn(AppSyncPolicy.productionDefault);

    service = SessionSyncServiceImpl(
      appSessionRepository: repository,
      authRemoteDataSource: authRemoteDataSource,
      syncOrchestrator: syncOrchestrator,
      initialCloudMigrationCoordinator: initialCloudMigrationCoordinator,
    );
  });

  test(
    'persists session and runs initial cloud migration when migration is required',
    () async {
      when(
        () => repository.startAuthenticatedSession(
          any(),
          requiresInitialCloudMigration:
              any(named: 'requiresInitialCloudMigration'),
        ),
      ).thenAnswer((_) async => const Right(null));

      when(() => initialCloudMigrationCoordinator.runIfRequired()).thenAnswer(
        (_) async => const InitialCloudMigrationResult(
          status: InitialCloudMigrationStatus.completed,
          message: 'migration complete',
        ),
      );

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
      verify(() => initialCloudMigrationCoordinator.runIfRequired()).called(1);
      verifyNever(() => syncOrchestrator.run(any()));
      verifyNever(() => repository.completeInitialCloudMigration());
    },
  );

  test('fails when authenticated session cannot be persisted', () async {
    when(
      () => repository.startAuthenticatedSession(
        any(),
        requiresInitialCloudMigration:
            any(named: 'requiresInitialCloudMigration'),
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
    verifyNever(() => initialCloudMigrationCoordinator.runIfRequired());
    verifyNever(() => repository.completeInitialCloudMigration());
  });

  test('fails when initial cloud migration fails', () async {
    when(
      () => repository.startAuthenticatedSession(
        any(),
        requiresInitialCloudMigration:
            any(named: 'requiresInitialCloudMigration'),
      ),
    ).thenAnswer((_) async => const Right(null));

    when(() => initialCloudMigrationCoordinator.runIfRequired()).thenAnswer(
      (_) async => const InitialCloudMigrationResult(
        status: InitialCloudMigrationStatus.failed,
        message: 'step upload failed',
      ),
    );

    final result = await service.establishAuthenticatedSession(user);

    expect(result.isFailure, isTrue);
    expect(
      result.message,
      'initial migration failed after session establishment: step upload failed',
    );

    verifyNever(() => syncOrchestrator.run(any()));
    verifyNever(() => repository.completeInitialCloudMigration());
  });

  test('skips when initial cloud migration is skipped', () async {
    when(
      () => repository.startAuthenticatedSession(
        any(),
        requiresInitialCloudMigration:
            any(named: 'requiresInitialCloudMigration'),
      ),
    ).thenAnswer((_) async => const Right(null));

    when(() => initialCloudMigrationCoordinator.runIfRequired()).thenAnswer(
      (_) async => const InitialCloudMigrationResult(
        status: InitialCloudMigrationStatus.skipped,
        message: 'initial cloud migration already completed',
      ),
    );

    final result = await service.establishAuthenticatedSession(user);

    expect(result.isSkipped, isTrue);
    expect(
      result.message,
      'authenticated session established but initial migration was skipped: initial cloud migration already completed',
    );

    verifyNever(() => syncOrchestrator.run(any()));
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

  test('signOut signs out remotely and clears local session', () async {
    when(() => authRemoteDataSource.signOut())
        .thenAnswer((_) async => const Right(null));
    when(() => repository.clearSession())
        .thenAnswer((_) async => const Right(null));

    final result = await service.signOut();

    expect(result.isSuccess, isTrue);
    expect(result.message, 'sign-out completed successfully');

    verify(() => authRemoteDataSource.signOut()).called(1);
    verify(() => repository.clearSession()).called(1);
  });

  test('signOut fails when remote sign-out fails', () async {
    when(() => authRemoteDataSource.signOut()).thenAnswer(
      (_) async => const Left(AuthFailure(message: 'remote sign-out failed')),
    );

    final result = await service.signOut();

    expect(result.isFailure, isTrue);
    expect(result.message, 'sign-out failed: remote sign-out failed');

    verifyNever(() => repository.clearSession());
  });

  test('signOut fails when local session clear fails', () async {
    when(() => authRemoteDataSource.signOut())
        .thenAnswer((_) async => const Right(null));
    when(() => repository.clearSession()).thenAnswer(
      (_) async => const Left(CacheFailure(message: 'session reset failed')),
    );

    final result = await service.signOut();

    expect(result.isFailure, isTrue);
    expect(
      result.message,
      'sign-out succeeded remotely but local session reset failed: session reset failed',
    );
  });
}