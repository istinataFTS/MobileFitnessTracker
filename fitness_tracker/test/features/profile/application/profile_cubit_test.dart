import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/auth/auth_session_service.dart';
import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/core/session/session_sync_service.dart';
import 'package:fitness_tracker/domain/entities/app_session.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/domain/entities/user_profile.dart';
import 'package:fitness_tracker/domain/repositories/app_session_repository.dart';
import 'package:fitness_tracker/domain/repositories/user_profile_repository.dart';
import 'package:fitness_tracker/features/profile/application/profile_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppSessionRepository extends Mock implements AppSessionRepository {}

class _MockSessionSyncService extends Mock implements SessionSyncService {}

class _MockAuthSessionService extends Mock implements AuthSessionService {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

void main() {
  late _MockAppSessionRepository mockSessionRepo;
  late _MockSessionSyncService mockSyncService;
  late _MockAuthSessionService mockAuthService;
  late _MockUserProfileRepository mockProfileRepo;
  late ProfileCubit sut;

  final AppUser testUser = AppUser(
    id: 'user-1',
    email: 'alice@example.com',
    displayName: 'Alice',
  );

  final AppSession authenticatedSession = AppSession(
    authMode: _authMode,
    user: testUser,
    requiresInitialCloudMigration: false,
    lastCloudSyncAt: null,
  );

  final UserProfile testProfile = UserProfile(
    id: 'user-1',
    username: 'alice',
    displayName: 'Alice',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  setUp(() {
    mockSessionRepo = _MockAppSessionRepository();
    mockSyncService = _MockSessionSyncService();
    mockAuthService = _MockAuthSessionService();
    mockProfileRepo = _MockUserProfileRepository();

    sut = ProfileCubit(
      repository: mockSessionRepo,
      sessionSyncService: mockSyncService,
      authSessionService: mockAuthService,
      userProfileRepository: mockProfileRepo,
    );
  });

  tearDown(() => sut.close());

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------
  test('initial state is guest, not loaded, no profile', () {
    expect(sut.state.session.isAuthenticated, isFalse);
    expect(sut.state.hasLoaded, isFalse);
    expect(sut.state.userProfile, isNull);
    expect(sut.state.errorMessage, isNull);
  });

  // ---------------------------------------------------------------------------
  // ensureLoaded — skips when already loaded
  // ---------------------------------------------------------------------------
  test('ensureLoaded does nothing when already hasLoaded', () async {
    when(() => mockSessionRepo.getCurrentSession())
        .thenAnswer((_) async => Right(authenticatedSession));
    when(() => mockProfileRepo.getProfile('user-1'))
        .thenAnswer((_) async => Right(testProfile));

    await sut.loadProfile();
    clearInteractions(mockSessionRepo);

    await sut.ensureLoaded();

    verifyNever(() => mockSessionRepo.getCurrentSession());
  });

  // ---------------------------------------------------------------------------
  // loadProfile — authenticated with profile
  // ---------------------------------------------------------------------------
  test('loadProfile emits session + userProfile on success', () async {
    when(() => mockSessionRepo.getCurrentSession())
        .thenAnswer((_) async => Right(authenticatedSession));
    when(() => mockProfileRepo.getProfile('user-1'))
        .thenAnswer((_) async => Right(testProfile));

    await sut.loadProfile();

    expect(sut.state.session, authenticatedSession);
    expect(sut.state.userProfile, testProfile);
    expect(sut.state.hasLoaded, isTrue);
    expect(sut.state.isLoading, isFalse);
    expect(sut.state.errorMessage, isNull);
  });

  // ---------------------------------------------------------------------------
  // loadProfile — authenticated but no profile row yet
  // ---------------------------------------------------------------------------
  test('loadProfile emits null userProfile when no profile row exists',
      () async {
    when(() => mockSessionRepo.getCurrentSession())
        .thenAnswer((_) async => Right(authenticatedSession));
    when(() => mockProfileRepo.getProfile('user-1'))
        .thenAnswer((_) async => const Right(null));

    await sut.loadProfile();

    expect(sut.state.userProfile, isNull);
    expect(sut.state.session.isAuthenticated, isTrue);
    expect(sut.state.hasLoaded, isTrue);
  });

  // ---------------------------------------------------------------------------
  // loadProfile — guest session (no profile fetch attempted)
  // ---------------------------------------------------------------------------
  test('loadProfile does not fetch profile for guest session', () async {
    when(() => mockSessionRepo.getCurrentSession())
        .thenAnswer((_) async => const Right(AppSession.guest()));

    await sut.loadProfile();

    verifyNever(() => mockProfileRepo.getProfile(any()));
    expect(sut.state.userProfile, isNull);
    expect(sut.state.hasLoaded, isTrue);
  });

  // ---------------------------------------------------------------------------
  // loadProfile — session repository failure
  // ---------------------------------------------------------------------------
  test('loadProfile emits error when session repository fails', () async {
    when(() => mockSessionRepo.getCurrentSession()).thenAnswer(
      (_) async => Left(DatabaseFailure('db error')),
    );

    await sut.loadProfile();

    expect(sut.state.errorMessage, isNotNull);
    expect(sut.state.session.isAuthenticated, isFalse);
    expect(sut.state.userProfile, isNull);
  });

  // ---------------------------------------------------------------------------
  // updateProfile — success
  // ---------------------------------------------------------------------------
  test('updateProfile emits updated profile on success', () async {
    // Pre-load so hasLoaded = true
    when(() => mockSessionRepo.getCurrentSession())
        .thenAnswer((_) async => Right(authenticatedSession));
    when(() => mockProfileRepo.getProfile('user-1'))
        .thenAnswer((_) async => Right(testProfile));
    await sut.loadProfile();

    final updated = testProfile.copyWith(displayName: 'Alice B');
    when(() => mockProfileRepo.upsertProfile(updated))
        .thenAnswer((_) async => Right(updated));

    await sut.updateProfile(updated);

    expect(sut.state.userProfile, updated);
    expect(sut.state.isLoading, isFalse);
    expect(sut.state.errorMessage, isNull);
  });

  // ---------------------------------------------------------------------------
  // updateProfile — failure
  // ---------------------------------------------------------------------------
  test('updateProfile emits error on repository failure', () async {
    when(() => mockSessionRepo.getCurrentSession())
        .thenAnswer((_) async => Right(authenticatedSession));
    when(() => mockProfileRepo.getProfile('user-1'))
        .thenAnswer((_) async => Right(testProfile));
    await sut.loadProfile();

    when(() => mockProfileRepo.upsertProfile(any())).thenAnswer(
      (_) async => Left(UnexpectedFailure('network error')),
    );

    await sut.updateProfile(testProfile);

    expect(sut.state.errorMessage, isNotNull);
    expect(sut.state.userProfile, testProfile); // unchanged
  });

  // ---------------------------------------------------------------------------
  // signOut — clears userProfile
  // ---------------------------------------------------------------------------
  test('signOut clears userProfile', () async {
    // Pre-load with profile
    when(() => mockSessionRepo.getCurrentSession())
        .thenAnswer((_) async => Right(authenticatedSession));
    when(() => mockProfileRepo.getProfile('user-1'))
        .thenAnswer((_) async => Right(testProfile));
    await sut.loadProfile();
    expect(sut.state.userProfile, testProfile);

    when(() => mockAuthService.signOut()).thenAnswer(
      (_) async => const SessionSyncActionResult(
          status: SessionSyncActionStatus.completed,
          message: 'signed out',
        ),
    );
    when(() => mockSessionRepo.getCurrentSession())
        .thenAnswer((_) async => const Right(AppSession.guest()));

    await sut.signOut();

    expect(sut.state.userProfile, isNull);
    expect(sut.state.session.isAuthenticated, isFalse);
  });

  // ---------------------------------------------------------------------------
  // clearError
  // ---------------------------------------------------------------------------
  test('clearError clears the error message', () async {
    when(() => mockSessionRepo.getCurrentSession()).thenAnswer(
      (_) async => Left(DatabaseFailure('db error')),
    );
    await sut.loadProfile();
    expect(sut.state.errorMessage, isNotNull);

    sut.clearError();

    expect(sut.state.errorMessage, isNull);
  });

  test('clearError is a no-op when there is no error', () {
    final stateBefore = sut.state;
    sut.clearError();
    expect(sut.state, stateBefore);
  });
}

const _authMode = AuthMode.authenticated;
