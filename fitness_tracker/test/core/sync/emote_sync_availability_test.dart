import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/core/enums/sync_trigger.dart';
import 'package:fitness_tracker/core/network/network_status_service.dart';
import 'package:fitness_tracker/core/sync/remote_sync_availability.dart';
import 'package:fitness_tracker/domain/entities/app_session.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNetworkStatusService extends Mock implements NetworkStatusService {}

void main() {
  group('RemoteSyncAvailability', () {
    late MockNetworkStatusService networkStatusService;

    const authenticatedSession = AppSession(
      authMode: AuthMode.authenticated,
      user: AppUser(
        id: 'user-1',
        email: 'user@test.com',
      ),
    );

    const migrationPendingSession = AppSession(
      authMode: AuthMode.authenticated,
      user: AppUser(
        id: 'user-1',
        email: 'user@test.com',
      ),
      requiresInitialCloudMigration: true,
    );

    setUp(() {
      networkStatusService = MockNetworkStatusService();
    });

    test('denies sync when remote backend is not configured', () async {
      final availability = RemoteSyncAvailability(
        hasRemoteConfiguration: false,
        networkStatusService: networkStatusService,
      );

      final decision = await availability.evaluate(
        session: authenticatedSession,
        trigger: SyncTrigger.appLaunch,
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.reason, 'remote backend not configured');
      verifyNever(() => networkStatusService.isNetworkAvailable());
    });

    test('denies sync for guest session', () async {
      when(() => networkStatusService.isNetworkAvailable())
          .thenAnswer((_) async => true);

      final availability = RemoteSyncAvailability(
        hasRemoteConfiguration: true,
        networkStatusService: networkStatusService,
      );

      final decision = await availability.evaluate(
        session: const AppSession.guest(),
        trigger: SyncTrigger.appLaunch,
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.reason, 'session is not authenticated');
    });

    test('denies normal sync while initial migration is pending', () async {
      when(() => networkStatusService.isNetworkAvailable())
          .thenAnswer((_) async => true);

      final availability = RemoteSyncAvailability(
        hasRemoteConfiguration: true,
        networkStatusService: networkStatusService,
      );

      final decision = await availability.evaluate(
        session: migrationPendingSession,
        trigger: SyncTrigger.appResume,
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.reason, 'initial cloud migration is pending');
    });

    test('allows initial sign-in sync while migration is pending', () async {
      when(() => networkStatusService.isNetworkAvailable())
          .thenAnswer((_) async => true);

      final availability = RemoteSyncAvailability(
        hasRemoteConfiguration: true,
        networkStatusService: networkStatusService,
      );

      final decision = await availability.evaluate(
        session: migrationPendingSession,
        trigger: SyncTrigger.initialSignIn,
      );

      expect(decision.isAllowed, isTrue);
    });

    test('denies sync when network is unavailable', () async {
      when(() => networkStatusService.isNetworkAvailable())
          .thenAnswer((_) async => false);

      final availability = RemoteSyncAvailability(
        hasRemoteConfiguration: true,
        networkStatusService: networkStatusService,
      );

      final decision = await availability.evaluate(
        session: authenticatedSession,
        trigger: SyncTrigger.appLaunch,
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.reason, 'network unavailable');
    });

    test('allows authenticated sync when prerequisites are satisfied', () async {
      when(() => networkStatusService.isNetworkAvailable())
          .thenAnswer((_) async => true);

      final availability = RemoteSyncAvailability(
        hasRemoteConfiguration: true,
        networkStatusService: networkStatusService,
      );

      final decision = await availability.evaluate(
        session: authenticatedSession,
        trigger: SyncTrigger.appLaunch,
      );

      expect(decision.isAllowed, isTrue);
      expect(decision.reason, 'remote sync allowed');
    });
  });
}