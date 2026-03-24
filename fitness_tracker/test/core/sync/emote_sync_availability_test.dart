import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/core/enums/sync_trigger.dart';
import 'package:fitness_tracker/core/sync/remote_sync_availability.dart';
import 'package:fitness_tracker/domain/entities/app_session.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteSyncAvailability', () {
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

    test('denies sync when remote backend is not configured', () {
      const availability = RemoteSyncAvailability(
        hasRemoteConfiguration: false,
      );

      final decision = availability.evaluate(
        session: authenticatedSession,
        trigger: SyncTrigger.appLaunch,
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.reason, 'remote backend not configured');
    });

    test('denies sync for guest session', () {
      const availability = RemoteSyncAvailability(
        hasRemoteConfiguration: true,
      );

      final decision = availability.evaluate(
        session: const AppSession.guest(),
        trigger: SyncTrigger.appLaunch,
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.reason, 'session is not authenticated');
    });

    test('denies normal sync while initial migration is pending', () {
      const availability = RemoteSyncAvailability(
        hasRemoteConfiguration: true,
      );

      final decision = availability.evaluate(
        session: migrationPendingSession,
        trigger: SyncTrigger.appResume,
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.reason, 'initial cloud migration is pending');
    });

    test('allows initial sign-in sync while migration is pending', () {
      const availability = RemoteSyncAvailability(
        hasRemoteConfiguration: true,
      );

      final decision = availability.evaluate(
        session: migrationPendingSession,
        trigger: SyncTrigger.initialSignIn,
      );

      expect(decision.isAllowed, isTrue);
    });

    test('denies sync when network is unavailable', () {
      const availability = RemoteSyncAvailability(
        hasRemoteConfiguration: true,
      );

      final decision = availability.evaluate(
        session: authenticatedSession,
        trigger: SyncTrigger.appLaunch,
        isNetworkAvailable: false,
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.reason, 'network unavailable');
    });

    test('allows authenticated sync when prerequisites are satisfied', () {
      const availability = RemoteSyncAvailability(
        hasRemoteConfiguration: true,
      );

      final decision = availability.evaluate(
        session: authenticatedSession,
        trigger: SyncTrigger.appLaunch,
      );

      expect(decision.isAllowed, isTrue);
      expect(decision.reason, 'remote sync allowed');
    });
  });
}