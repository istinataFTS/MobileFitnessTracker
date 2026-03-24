import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/config/app_sync_policy.dart';
import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/core/enums/sync_trigger.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/core/sync/remote_sync_availability.dart';
import 'package:fitness_tracker/core/sync/sync_feature.dart';
import 'package:fitness_tracker/core/sync/sync_orchestrator.dart';
import 'package:fitness_tracker/core/sync/sync_orchestrator_impl.dart';
import 'package:fitness_tracker/domain/entities/app_session.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/domain/repositories/app_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSessionRepository extends Mock implements AppSessionRepository {}

void main() {
  late MockAppSessionRepository repository;
  late SyncOrchestrator orchestrator;
  late List<String> executionLog;

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

  setUp(() {
    repository = MockAppSessionRepository();
    executionLog = <String>[];

    when(() => repository.syncPolicy)
        .thenReturn(AppSyncPolicy.productionDefault);

    when(() => repository.recordSuccessfulCloudSync(any()))
        .thenAnswer((_) async => const Right(null));

    orchestrator = SyncOrchestratorImpl(
      appSessionRepository: repository,
      syncPolicy: AppSyncPolicy.productionDefault,
      remoteSyncAvailability: const RemoteSyncAvailability(
        hasRemoteConfiguration: true,
      ),
      features: <SyncFeature>[
        SyncFeature(
          name: 'targets',
          syncPendingChanges: () async {
            executionLog.add('targets');
          },
        ),
        SyncFeature(
          name: 'workout_sets',
          syncPendingChanges: () async {
            executionLog.add('workout_sets');
          },
        ),
      ],
    );
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

  test('runs feature sync in registration order for authenticated session', () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(authenticatedSession()),
    );

    final result = await orchestrator.run(SyncTrigger.appLaunch);

    expect(result.status, SyncRunStatus.completed);
    expect(executionLog, <String>['targets', 'workout_sets']);
    verify(() => repository.recordSuccessfulCloudSync(any())).called(1);
  });

  test('fails when session lookup fails', () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => const Left(CacheFailure(message: 'session unavailable')),
    );

    final result = await orchestrator.run(SyncTrigger.appLaunch);

    expect(result.status, SyncRunStatus.failed);
    expect(result.message, contains('session lookup failed'));
    expect(executionLog, isEmpty);
  });

  test('fails when one feature sync throws and does not record sync time', () async {
    orchestrator = SyncOrchestratorImpl(
      appSessionRepository: repository,
      syncPolicy: AppSyncPolicy.productionDefault,
      remoteSyncAvailability: const RemoteSyncAvailability(
        hasRemoteConfiguration: true,
      ),
      features: <SyncFeature>[
        SyncFeature(
          name: 'targets',
          syncPendingChanges: () async {
            executionLog.add('targets');
          },
        ),
        SyncFeature(
          name: 'workout_sets',
          syncPendingChanges: () async {
            throw StateError('boom');
          },
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
  });

  test('allows initial sign-in trigger while migration is pending', () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(
        authenticatedSession(requiresInitialCloudMigration: true),
      ),
    );

    final result = await orchestrator.run(SyncTrigger.initialSignIn);

    expect(result.status, SyncRunStatus.completed);
    expect(executionLog, <String>['targets', 'workout_sets']);
    verify(() => repository.recordSuccessfulCloudSync(any())).called(1);
  });
}