import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/core/session/session_sync_service.dart';
import 'package:fitness_tracker/domain/entities/app_session.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/domain/repositories/app_session_repository.dart';
import 'package:fitness_tracker/features/profile/application/profile_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSessionRepository extends Mock implements AppSessionRepository {}

class MockSessionSyncService extends Mock implements SessionSyncService {}

void main() {
  late MockAppSessionRepository repository;
  late MockSessionSyncService sessionSyncService;
  late ProfileCubit cubit;

  setUp(() {
    repository = MockAppSessionRepository();
    sessionSyncService = MockSessionSyncService();

    cubit = ProfileCubit(
      repository: repository,
      sessionSyncService: sessionSyncService,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  test('initial state starts idle with guest shell before first load', () {
    expect(cubit.state.session, const AppSession.guest());
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.hasLoaded, isFalse);
    expect(cubit.state.errorMessage, isNull);
  });

  test('ensureLoaded triggers first session load', () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => const Right(AppSession.guest()),
    );

    await cubit.ensureLoaded();

    verify(() => repository.getCurrentSession()).called(1);
    expect(cubit.state.session, const AppSession.guest());
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.hasLoaded, isTrue);
  });

  test('ensureLoaded does not load again after successful load', () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => const Right(AppSession.guest()),
    );

    await cubit.ensureLoaded();
    await cubit.ensureLoaded();

    verify(() => repository.getCurrentSession()).called(1);
  });

  test('loadProfile stores authenticated session on success', () async {
    final AppSession session = AppSession(
      authMode: AuthMode.authenticated,
      user: const AppUser(
        id: 'user-1',
        email: 'user@test.com',
        displayName: 'Marin',
      ),
      requiresInitialCloudMigration: true,
      lastCloudSyncAt: DateTime(2026, 3, 18, 9, 30),
    );

    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(session),
    );

    await cubit.loadProfile();

    expect(cubit.state.session, session);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.hasLoaded, isTrue);
    expect(cubit.state.errorMessage, isNull);
  });

  test('loadProfile falls back to guest shell on failure', () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => const Left(CacheFailure(message: 'session unavailable')),
    );

    await cubit.loadProfile();

    expect(cubit.state.session, const AppSession.guest());
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.hasLoaded, isTrue);
    expect(cubit.state.errorMessage, 'session unavailable');
  });

  test('refreshProfile runs manual sync and reloads session on success', () async {
    when(() => sessionSyncService.runManualRefresh()).thenAnswer(
      (_) async => const SessionSyncActionResult(
        status: SessionSyncActionStatus.completed,
        message: 'manual refresh completed successfully',
      ),
    );

    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(
        AppSession(
          authMode: AuthMode.authenticated,
          user: const AppUser(
            id: 'user-1',
            email: 'marin@test.com',
            displayName: 'Marin',
          ),
          requiresInitialCloudMigration: false,
          lastCloudSyncAt: DateTime(2026, 3, 24, 10, 15),
        ),
      ),
    );

    await cubit.refreshProfile();

    verify(() => sessionSyncService.runManualRefresh()).called(1);
    verify(() => repository.getCurrentSession()).called(1);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.hasLoaded, isTrue);
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state.session.isAuthenticated, isTrue);
  });

  test('refreshProfile keeps loaded session and surfaces manual refresh failure', () async {
    when(() => sessionSyncService.runManualRefresh()).thenAnswer(
      (_) async => const SessionSyncActionResult(
        status: SessionSyncActionStatus.failed,
        message: 'manual refresh failed: session is not authenticated',
      ),
    );

    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => const Right(AppSession.guest()),
    );

    await cubit.refreshProfile();

    verify(() => sessionSyncService.runManualRefresh()).called(1);
    verify(() => repository.getCurrentSession()).called(1);
    expect(cubit.state.session, const AppSession.guest());
    expect(cubit.state.errorMessage,
        'manual refresh failed: session is not authenticated');
  });

  test('refreshProfile combines manual refresh and session load failures', () async {
    when(() => sessionSyncService.runManualRefresh()).thenAnswer(
      (_) async => const SessionSyncActionResult(
        status: SessionSyncActionStatus.failed,
        message: 'manual refresh failed: sync orchestration failed',
      ),
    );

    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => const Left(CacheFailure(message: 'session unavailable')),
    );

    await cubit.refreshProfile();

    expect(cubit.state.session, const AppSession.guest());
    expect(
      cubit.state.errorMessage,
      'manual refresh failed: sync orchestration failed | session unavailable',
    );
  });

  test('clearError removes current error message', () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => const Left(CacheFailure(message: 'session unavailable')),
    );

    await cubit.loadProfile();
    expect(cubit.state.errorMessage, 'session unavailable');

    cubit.clearError();

    expect(cubit.state.errorMessage, isNull);
  });
}