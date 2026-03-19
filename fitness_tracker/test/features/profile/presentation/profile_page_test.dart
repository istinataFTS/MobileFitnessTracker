import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/config/app_sync_policy.dart';
import 'package:fitness_tracker/core/enums/auth_mode.dart';
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

  testWidgets('renders guest profile shell', (WidgetTester tester) async {
    when(() => repository.getCurrentSession()).thenAnswer(
      (_) async => const Right(AppSession.guest()),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Guest profile shell'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Targets'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('renders authenticated profile shell', (
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

    expect(find.text('Marin Dinchev'), findsOneWidget);
    expect(find.text('marin@test.com'), findsOneWidget);
    expect(find.text('Signed-in profile shell'), findsOneWidget);
    expect(find.text('This session is marked as needing an initial cloud migration'), findsOneWidget);
    expect(find.text('2026-03-18 14:45'), findsOneWidget);
  });

  testWidgets('falls back to guest shell when session lookup fails', (
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

    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Guest profile shell'), findsOneWidget);
  });
}