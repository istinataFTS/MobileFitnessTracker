import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/auth/auth_session_service.dart';
import 'package:fitness_tracker/core/auth/auth_session_service_impl.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/core/session/session_sync_service.dart';
import 'package:fitness_tracker/data/datasources/remote/auth_remote_datasource.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockSessionSyncService extends Mock implements SessionSyncService {}

void main() {
  late MockAuthRemoteDataSource authRemoteDataSource;
  late MockSessionSyncService sessionSyncService;
  late AuthSessionService service;

  const user = AppUser(
    id: 'user-1',
    email: 'marin@test.com',
    displayName: 'Marin',
  );

  setUp(() {
    authRemoteDataSource = MockAuthRemoteDataSource();
    sessionSyncService = MockSessionSyncService();

    service = AuthSessionServiceImpl(
      authRemoteDataSource: authRemoteDataSource,
      sessionSyncService: sessionSyncService,
    );
  });

  test('signInWithEmail authenticates remotely then establishes app session',
      () async {
    when(
      () => authRemoteDataSource.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Right(user));

    when(
      () => sessionSyncService.establishAuthenticatedSession(user),
    ).thenAnswer(
      (_) async => const SessionSyncActionResult(
        status: SessionSyncActionStatus.completed,
        message: 'authenticated session established',
      ),
    );

    final result = await service.signInWithEmail(
      email: ' marin@test.com ',
      password: 'secret-password',
    );

    expect(result.isSuccess, isTrue);
    expect(result.message, 'sign-in completed successfully');
    expect(result.user, user);

    verify(
      () => authRemoteDataSource.signInWithEmail(
        email: 'marin@test.com',
        password: 'secret-password',
      ),
    ).called(1);

    verify(
      () => sessionSyncService.establishAuthenticatedSession(user),
    ).called(1);
  });

  test('returns failure when remote sign-in fails', () async {
    when(
      () => authRemoteDataSource.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const Left(AuthFailure(message: 'invalid credentials')),
    );

    final result = await service.signInWithEmail(
      email: 'marin@test.com',
      password: 'bad-password',
    );

    expect(result.isFailure, isTrue);
    expect(result.message, 'sign-in failed: invalid credentials');

    verifyNever(
      () => sessionSyncService.establishAuthenticatedSession(any()),
    );
  });

  test('returns failure when session initialization fails after remote sign-in',
      () async {
    when(
      () => authRemoteDataSource.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Right(user));

    when(
      () => sessionSyncService.establishAuthenticatedSession(user),
    ).thenAnswer(
      (_) async => const SessionSyncActionResult(
        status: SessionSyncActionStatus.failed,
        message: 'initial sign-in sync failed: sync failed',
      ),
    );

    final result = await service.signInWithEmail(
      email: 'marin@test.com',
      password: 'secret-password',
    );

    expect(result.isFailure, isTrue);
    expect(
      result.message,
      'sign-in succeeded but session initialization failed: initial sign-in sync failed: sync failed',
    );
    expect(result.user, user);
  });

  test('returns failure when session initialization is skipped', () async {
    when(
      () => authRemoteDataSource.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Right(user));

    when(
      () => sessionSyncService.establishAuthenticatedSession(user),
    ).thenAnswer(
      (_) async => const SessionSyncActionResult(
        status: SessionSyncActionStatus.skipped,
        message: 'initial sign-in sync skipped: migration pending',
      ),
    );

    final result = await service.signInWithEmail(
      email: 'marin@test.com',
      password: 'secret-password',
    );

    expect(result.isFailure, isTrue);
    expect(
      result.message,
      'sign-in succeeded but session initialization was skipped: initial sign-in sync skipped: migration pending',
    );
    expect(result.user, user);
  });
}