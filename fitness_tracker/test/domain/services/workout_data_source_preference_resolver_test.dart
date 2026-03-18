import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/config/app_sync_policy.dart';
import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/core/enums/conflict_resolution_strategy.dart';
import 'package:fitness_tracker/core/enums/data_source_preference.dart';
import 'package:fitness_tracker/core/enums/sync_trigger.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/domain/entities/app_session.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/domain/repositories/app_session_repository.dart';
import 'package:fitness_tracker/domain/services/workout_data_source_preference_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSessionRepository extends Mock implements AppSessionRepository {}

void main() {
  late MockAppSessionRepository repository;
  late WorkoutDataSourcePreferenceResolver resolver;

  const remoteSourceOfTruthPolicy = AppSyncPolicy(
    offlineFirst: true,
    localStoreAcceptsWrites: true,
    remoteIsSourceOfTruthWhenAuthenticated: true,
    guestModeUsesLocalStorageOnly: true,
    authenticatedModeUsesUserScopedData: true,
    initialCloudSyncUploadsLocalData: true,
    conflictResolutionStrategy: ConflictResolutionStrategy.serverWins,
    syncTriggers: <SyncTrigger>[
      SyncTrigger.appLaunch,
    ],
  );

  const localOnlyPolicy = AppSyncPolicy(
    offlineFirst: true,
    localStoreAcceptsWrites: true,
    remoteIsSourceOfTruthWhenAuthenticated: false,
    guestModeUsesLocalStorageOnly: true,
    authenticatedModeUsesUserScopedData: true,
    initialCloudSyncUploadsLocalData: true,
    conflictResolutionStrategy: ConflictResolutionStrategy.serverWins,
    syncTriggers: <SyncTrigger>[
      SyncTrigger.appLaunch,
    ],
  );

  setUp(() {
    repository = MockAppSessionRepository();
    resolver = WorkoutDataSourcePreferenceResolver(
      appSessionRepository: repository,
    );
  });

  test('returns remoteThenLocal for authenticated session when remote is source of truth', () async {
    when(() => repository.syncPolicy).thenReturn(remoteSourceOfTruthPolicy);
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(
        AppSession(
          authMode: AuthMode.authenticated,
          user: const AppUser(id: 'user-1', email: 'user@test.com'),
        ),
      ),
    );

    final result = await resolver.resolveReadPreference();

    expect(result, DataSourcePreference.remoteThenLocal);
  });

  test('returns localOnly for guest session', () async {
    when(() => repository.syncPolicy).thenReturn(remoteSourceOfTruthPolicy);
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => const Right(AppSession.guest()),
    );

    final result = await resolver.resolveReadPreference();

    expect(result, DataSourcePreference.localOnly);
  });

  test('returns localOnly when session lookup fails', () async {
    when(() => repository.syncPolicy).thenReturn(remoteSourceOfTruthPolicy);
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Left(CacheFailure(message: 'failed')),
    );

    final result = await resolver.resolveReadPreference();

    expect(result, DataSourcePreference.localOnly);
  });

  test('returns localOnly when policy does not prefer remote', () async {
    when(() => repository.syncPolicy).thenReturn(localOnlyPolicy);
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(
        AppSession(
          authMode: AuthMode.authenticated,
          user: const AppUser(id: 'user-1', email: 'user@test.com'),
        ),
      ),
    );

    final result = await resolver.resolveReadPreference();

    expect(result, DataSourcePreference.localOnly);
  });
}