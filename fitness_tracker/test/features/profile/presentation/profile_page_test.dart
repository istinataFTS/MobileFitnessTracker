import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/config/app_sync_policy.dart';
import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/domain/entities/app_session.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/domain/repositories/app_session_repository.dart';
import 'package:fitness_tracker/features/profile/presentation/profile_page.dart';
import 'package:fitness_tracker/injection/injection_container.dart' as di;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSessionRepository extends Mock implements AppSessionRepository {}

void main() {
  late MockAppSessionRepository repository;

  setUp(() async {
    repository = MockAppSessionRepository();

    if (!di.sl.isRegistered<AppSessionRepository>()) {
      di.sl.registerLazySingleton<AppSessionRepository>(() => repository);
    } else {
      await di.sl.unregister<AppSessionRepository>();
      di.sl.registerLazySingleton<AppSessionRepository>(() => repository);
    }

    when(() => repository.syncPolicy)
        .thenReturn(AppSyncPolicy.productionDefault);
  });

  tearDown(() async {
    if (di.sl.isRegistered<AppSessionRepository>()) {
      await di.sl.unregister<AppSessionRepository>();
    }
  });

  Widget buildSubject() {
    return const MaterialApp(
      home: ProfilePage(),
    );
  }

  testWidgets('shows dedicated loading indicator before session resolves', (
    WidgetTester tester,
  ) async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return const Right(AppSession.guest());
      },
    );

    await tester.pumpWidget(buildSubject());

    expect(find.byKey(ProfilePage.loadingIndicatorKey), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(ProfilePage.titleKey), findsOneWidget);
  });

  testWidgets('renders guest profile shell through stable keys', (
    WidgetTester tester,
  ) async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => const Right(AppSession.guest()),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byKey(ProfilePage.titleKey), findsOneWidget);
    expect(find.byKey(ProfilePage.subtitleKey), findsOneWidget);
    expect(find.byKey(ProfilePage.sessionBannerKey), findsOneWidget);
    expect(find.byKey(ProfilePage.accountModeBannerKey), findsOneWidget);
    expect(find.byKey(ProfilePage.settingsTileKey), findsOneWidget);
    expect(find.byKey(ProfilePage.targetsTileKey), findsOneWidget);
    expect(find.byKey(ProfilePage.historyTileKey), findsOneWidget);
    expect(find.byKey(ProfilePage.accountStatusTileKey), findsOneWidget);
    expect(find.byKey(ProfilePage.cloudMigrationTileKey), findsOneWidget);
    expect(find.byKey(ProfilePage.lastSyncTileKey), findsOneWidget);
    expect(find.byKey(ProfilePage.deferredSectionKey), findsOneWidget);
    expect(find.byKey(ProfilePage.appVersionTileKey), findsOneWidget);

    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Guest profile shell'), findsWidgets);
    expect(find.text('No initial cloud migration pending'), findsOneWidget);
    expect(find.text('No successful cloud sync recorded yet'), findsOneWidget);
  });

  testWidgets('renders authenticated profile shell through stable keys', (
    WidgetTester tester,
  ) async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(
        AppSession(
          authMode: AuthMode.authenticated,
          user: const AppUser(
            id: 'user-1',
            email: 'marin@test.com',
            displayName: 'Marin Dinchev',
          ),
          requiresInitialCloudMigration: true,
          lastCloudSyncAt: DateTime(2026, 3, 18, 14, 45),
        ),
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byKey(ProfilePage.titleKey), findsOneWidget);
    expect(find.byKey(ProfilePage.subtitleKey), findsOneWidget);
    expect(find.text('Marin Dinchev'), findsOneWidget);
    expect(find.text('marin@test.com'), findsOneWidget);
    expect(find.text('Signed-in profile shell'), findsWidgets);
    expect(
      find.text('This session is marked as needing an initial cloud migration'),
      findsOneWidget,
    );
    expect(find.text('2026-03-18 14:45'), findsOneWidget);
  });

  testWidgets('authenticated session without display name uses fallback title', (
    WidgetTester tester,
  ) async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(
        AppSession(
          authMode: AuthMode.authenticated,
          user: const AppUser(
            id: 'user-1',
            email: 'marin@test.com',
            displayName: '',
          ),
          requiresInitialCloudMigration: false,
          lastCloudSyncAt: null,
        ),
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byKey(ProfilePage.titleKey), findsOneWidget);
    expect(find.text('Signed-in User'), findsOneWidget);
    expect(find.text('marin@test.com'), findsOneWidget);
  });

  testWidgets('authenticated session without email uses fallback subtitle', (
    WidgetTester tester,
  ) async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => Right(
        AppSession(
          authMode: AuthMode.authenticated,
          user: const AppUser(
            id: 'user-1',
            email: '',
            displayName: 'Marin Dinchev',
          ),
          requiresInitialCloudMigration: false,
          lastCloudSyncAt: null,
        ),
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byKey(ProfilePage.subtitleKey), findsOneWidget);
    expect(find.text('Authenticated session'), findsOneWidget);
  });

  testWidgets('failure falls back to guest shell and shows snackbar', (
    WidgetTester tester,
  ) async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => const Left(
        CacheFailure(message: 'session unavailable'),
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(ProfilePage.titleKey), findsOneWidget);
    expect(find.text('Guest'), findsOneWidget);
    expect(find.textContaining('Failed to load profile session.'), findsOneWidget);
  });

  testWidgets('pull to refresh reloads session from refresh list', (
    WidgetTester tester,
  ) async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => const Right(AppSession.guest()),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(ProfilePage.refreshListKey),
      const Offset(0, 300),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(() => repository.getCurrentSession()).called(greaterThanOrEqualTo(2));
  });
}