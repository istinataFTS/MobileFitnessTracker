import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/config/app_sync_policy.dart';
import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/core/enums/conflict_resolution_strategy.dart';
import 'package:fitness_tracker/core/enums/sync_trigger.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/core/errors/sync_exceptions.dart';
import 'package:fitness_tracker/core/network/network_status_service.dart';
import 'package:fitness_tracker/core/sync/initial_cloud_migration_coordinator.dart';
import 'package:fitness_tracker/core/sync/remote_sync_availability.dart';
import 'package:fitness_tracker/core/sync/remote_sync_runtime_policy.dart';
import 'package:fitness_tracker/core/sync/sync_feature.dart';
import 'package:fitness_tracker/core/sync/sync_orchestrator.dart';
import 'package:fitness_tracker/core/sync/sync_orchestrator_impl.dart';
import 'package:fitness_tracker/data/sync/entity_sync_batch_failure.dart';
import 'package:fitness_tracker/domain/entities/app_session.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/domain/repositories/app_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSessionRepository extends Mock implements AppSessionRepository {}

class MockNetworkStatusService extends Mock implements NetworkStatusService {}

class MockInitialCloudMigrationCoordinator extends Mock
    implements InitialCloudMigrationCoordinator {}

void main() {
  late MockAppSessionRepository repository;
  late MockNetworkStatusService networkStatusService;
  late MockInitialCloudMigrationCoordinator initialCloudMigrationCoordinator;
  late SyncOrchestrator orchestrator;
  late List<String> executionLog;

  const runtimePolicy = RemoteSyncRuntimePolicy(
    isSupabaseEnabled: true,
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'anon-key',
  );

  AppSession authenticatedSession({
    bool requiresInitialCloudMigration = false,
  }) {
    return AppSession(
      authMode: AuthMode.authenticated,
      user: const AppUser(
        id: 'user-1',
        email: 'user@test.com',
      ),
      requiresInitialCloudMigration: requiresInitialCloudMigration,
    );
  }

  SyncOrchestratorImpl buildOrchestrator({
    AppSyncPolicy? policy,
    List<SyncFeature>? features,
  }) {
    return SyncOrchestratorImpl(
      appSessionRepository: repository,
      syncPolicy: policy ?? AppSyncPolicy.productionDefault,
      remoteSyncAvailability: RemoteSyncAvailability(
        runtimePolicy: runtimePolicy,
        networkStatusService: networkStatusService,
      ),
      initialCloudMigrationCoordinator: initialCloudMigrationCoordinator,
      features: features ??
          [
            SyncFeature(
              name: 'targets',
              syncPendingChanges: () async => executionLog.add('targets'),
              pullRemoteChanges: (_, __) async {},
            ),
            SyncFeature(
              name: 'workout_sets',
              syncPendingChanges: () async => executionLog.add('workout_sets'),
              pullRemoteChanges: (_, __) async {},
            ),
          ],
    );
  }

  setUp(() {
    repository = MockAppSessionRepository();
    networkStatusService = MockNetworkStatusService();
    initialCloudMigrationCoordinator = MockInitialCloudMigrationCoordinator();
    executionLog = <String>[];

    when(() => repository.syncPolicy)
        .thenReturn(AppSyncPolicy.productionDefault);

    when(() => repository.recordSuccessfulCloudSync(any()))
        .thenAnswer((_) async => const Right(null));

    when(() => networkStatusService.isNetworkAvailable())
        .thenAnswer((_) async => true);

    when(() => initialCloudMigrationCoordinator.runIfRequired()).thenAnswer(
      (_) async => const InitialCloudMigrationResult(
        status: InitialCloudMigrationStatus.completed,
        message: 'initial cloud migration completed successfully',
      ),
    );

    orchestrator = buildOrchestrator();
  });

  test('skips when session is guest', () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => const Right(AppSession.guest()),
    );

    final result = await orchestrator.run(SyncTrigger.appLaunch);

    expect(result.status, SyncRunStatus.skipped);
    expect(executionLog, isEmpty);
    verifyNever(() => repository.recordSuccessfulCloudSync(any()));
  });

  test('runs feature sync in registration order for authenticated session',
      () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(authenticatedSession()),
    );

    final result = await orchestrator.run(SyncTrigger.appLaunch);

    expect(result.status, SyncRunStatus.completed);
    expect(executionLog, <String>['targets', 'workout_sets']);
    verify(() => repository.recordSuccessfulCloudSync(any())).called(1);
    verifyNever(() => initialCloudMigrationCoordinator.runIfRequired());
  });

  test('fails when session lookup fails', () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => const Left(CacheFailure('session unavailable')),
    );

    final result = await orchestrator.run(SyncTrigger.appLaunch);

    expect(result.status, SyncRunStatus.failed);
    expect(result.message, contains('session lookup failed'));
    expect(executionLog, isEmpty);
  });

  test('fails when one feature sync throws and does not record sync time',
      () async {
    orchestrator = buildOrchestrator(
      features: [
        SyncFeature(
          name: 'targets',
          syncPendingChanges: () async => executionLog.add('targets'),
          pullRemoteChanges: (_, __) async {},
        ),
        SyncFeature(
          name: 'workout_sets',
          syncPendingChanges: () async => throw StateError('boom'),
          pullRemoteChanges: (_, __) async {},
        ),
      ],
    );

    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(authenticatedSession()),
    );

    final result = await orchestrator.run(SyncTrigger.appLaunch);

    expect(result.status, SyncRunStatus.failed);
    expect(result.featureResults, hasLength(2));
    expect(result.featureResults.first.isSuccess, isTrue);
    expect(result.featureResults.last.isSuccess, isFalse);
    verifyNever(() => repository.recordSuccessfulCloudSync(any()));
    verifyNever(() => initialCloudMigrationCoordinator.runIfRequired());
  });

  test('preserves structured sync batch failure message for feature result',
      () async {
    orchestrator = buildOrchestrator(
      features: [
        SyncFeature(
          name: 'targets',
          syncPendingChanges: () async => throw const EntitySyncBatchFailure(
            entityLabel: 'target',
            failedUpsertEntityIds: <String>['target-1'],
            failedDeleteEntityIds: <String>['target-7'],
          ),
          pullRemoteChanges: (_, __) async {},
        ),
      ],
    );

    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(authenticatedSession()),
    );

    final result = await orchestrator.run(SyncTrigger.appLaunch);

    expect(result.status, SyncRunStatus.failed);
    expect(result.featureResults, hasLength(1));
    expect(result.featureResults.single.isSuccess, isFalse);
    expect(
      result.featureResults.single.errorMessage,
      'failed to upsert 1 target entry (target-1); '
      'failed to delete 1 target entry (target-7)',
    );
    verifyNever(() => repository.recordSuccessfulCloudSync(any()));
  });

  test('skips app resume while initial migration is pending', () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(
        authenticatedSession(requiresInitialCloudMigration: true),
      ),
    );

    final result = await orchestrator.run(SyncTrigger.appResume);

    expect(result.status, SyncRunStatus.skipped);
    expect(result.message, 'initial cloud migration is pending');
    expect(executionLog, isEmpty);
    verifyNever(() => initialCloudMigrationCoordinator.runIfRequired());
  });

  test('runs initial migration on initial sign-in while migration is pending',
      () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(
        authenticatedSession(requiresInitialCloudMigration: true),
      ),
    );

    final result = await orchestrator.run(SyncTrigger.initialSignIn);

    expect(result.status, SyncRunStatus.completed);
    expect(result.message, 'initial cloud migration completed successfully');
    expect(executionLog, isEmpty);
    verify(() => initialCloudMigrationCoordinator.runIfRequired()).called(1);
    verify(() => repository.recordSuccessfulCloudSync(any())).called(1);
  });

  test('fails when initial migration fails during initial sign-in', () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(
        authenticatedSession(requiresInitialCloudMigration: true),
      ),
    );
    when(() => initialCloudMigrationCoordinator.runIfRequired()).thenAnswer(
      (_) async => const InitialCloudMigrationResult(
        status: InitialCloudMigrationStatus.failed,
        message: 'step nutrition_logs failed',
      ),
    );

    final result = await orchestrator.run(SyncTrigger.initialSignIn);

    expect(result.status, SyncRunStatus.failed);
    expect(result.message, 'step nutrition_logs failed');
    expect(executionLog, isEmpty);
    verifyNever(() => repository.recordSuccessfulCloudSync(any()));
  });

  test('skips when network is unavailable', () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(authenticatedSession()),
    );
    when(() => networkStatusService.isNetworkAvailable())
        .thenAnswer((_) async => false);

    final result = await orchestrator.run(SyncTrigger.appLaunch);

    expect(result.status, SyncRunStatus.skipped);
    expect(result.message, 'network unavailable');
    expect(executionLog, isEmpty);
    verifyNever(() => repository.recordSuccessfulCloudSync(any()));
    verifyNever(() => initialCloudMigrationCoordinator.runIfRequired());
  });

  test('skips when trigger is disabled by sync policy', () async {
    orchestrator = buildOrchestrator(
      policy: const AppSyncPolicy(
        offlineFirst: true,
        localStoreAcceptsWrites: true,
        remoteIsSourceOfTruthWhenAuthenticated: true,
        guestModeUsesLocalStorageOnly: true,
        authenticatedModeUsesUserScopedData: true,
        initialCloudSyncUploadsLocalData: true,
        conflictResolutionStrategy: ConflictResolutionStrategy.serverWins,
        syncTriggers: <SyncTrigger>[],
      ),
    );

    final result = await orchestrator.run(SyncTrigger.appLaunch);

    expect(result.status, SyncRunStatus.skipped);
    expect(result.message, 'trigger is disabled by sync policy');
    verifyNever(() => repository.getCurrentSession());
  });

  test('returns skipped immediately when sync is already in progress', () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(authenticatedSession()),
    );

    // Start first run but do not await — it yields inside getCurrentSession.
    final firstRun = orchestrator.run(SyncTrigger.appLaunch);

    // Second run starts while first is suspended at the getCurrentSession await.
    final secondResult = await orchestrator.run(SyncTrigger.manualRefresh);

    expect(secondResult.status, SyncRunStatus.skipped);
    expect(secondResult.message, 'sync already in progress');

    await firstRun;
  });

  test('releases sync lock after successful run so next run can proceed',
      () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(authenticatedSession()),
    );

    await orchestrator.run(SyncTrigger.appLaunch);
    final secondResult = await orchestrator.run(SyncTrigger.manualRefresh);

    expect(secondResult.status, SyncRunStatus.completed);
    expect(secondResult.message, isNot('sync already in progress'));
  });

  test(
      'releases sync lock after unexpected exception so next run can proceed',
      () async {
    when(() => repository.getCurrentSession())
        .thenThrow(StateError('unexpected db crash'));

    try {
      await orchestrator.run(SyncTrigger.appLaunch);
    } catch (_) {}

    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(authenticatedSession()),
    );

    final secondResult = await orchestrator.run(SyncTrigger.manualRefresh);

    expect(secondResult.status, SyncRunStatus.completed);
  });

  test('resolves NetworkSyncException feature error message', () async {
    orchestrator = buildOrchestrator(
      features: [
        SyncFeature(
          name: 'targets',
          syncPendingChanges: () async =>
              throw const NetworkSyncException('connection refused'),
          pullRemoteChanges: (_, __) async {},
        ),
      ],
    );

    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(authenticatedSession()),
    );

    final result = await orchestrator.run(SyncTrigger.appLaunch);

    expect(result.featureResults.single.isSuccess, isFalse);
    expect(
      result.featureResults.single.errorMessage,
      'network error: connection refused',
    );
  });

  test('resolves AuthSyncException feature error message', () async {
    orchestrator = buildOrchestrator(
      features: [
        SyncFeature(
          name: 'targets',
          syncPendingChanges: () async =>
              throw const AuthSyncException('token expired'),
          pullRemoteChanges: (_, __) async {},
        ),
      ],
    );

    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(authenticatedSession()),
    );

    final result = await orchestrator.run(SyncTrigger.appLaunch);

    expect(result.featureResults.single.isSuccess, isFalse);
    expect(
      result.featureResults.single.errorMessage,
      'auth error: token expired',
    );
  });

  test('resolves RemoteSyncException feature error message', () async {
    orchestrator = buildOrchestrator(
      features: [
        SyncFeature(
          name: 'targets',
          syncPendingChanges: () async =>
              throw const RemoteSyncException('constraint violation'),
          pullRemoteChanges: (_, __) async {},
        ),
      ],
    );

    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(authenticatedSession()),
    );

    final result = await orchestrator.run(SyncTrigger.appLaunch);

    expect(result.featureResults.single.isSuccess, isFalse);
    expect(
      result.featureResults.single.errorMessage,
      'remote error: constraint violation',
    );
  });
}
