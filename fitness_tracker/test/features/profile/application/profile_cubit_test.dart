import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/domain/entities/app_session.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/domain/repositories/app_session_repository.dart';
import 'package:fitness_tracker/features/profile/application/profile_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSessionRepository extends Mock implements AppSessionRepository {}

void main() {
  late MockAppSessionRepository repository;
  late ProfileCubit cubit;

  setUp(() {
    repository = MockAppSessionRepository();
    cubit = ProfileCubit(repository: repository);
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

  test('refreshProfile reloads current session', () async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => const Right(AppSession.guest()),
    );

    await cubit.refreshProfile();

    verify(() => repository.getCurrentSession()).called(1);
    expect(cubit.state.hasLoaded, isTrue);
    expect(cubit.state.isLoading, isFalse);
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