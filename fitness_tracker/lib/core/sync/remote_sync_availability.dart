import '../../core/enums/sync_trigger.dart';
import '../../domain/entities/app_session.dart';

class RemoteSyncAvailabilityDecision {
  final bool isAllowed;
  final String reason;

  const RemoteSyncAvailabilityDecision({
    required this.isAllowed,
    required this.reason,
  });

  const RemoteSyncAvailabilityDecision.allowed()
      : isAllowed = true,
        reason = 'remote sync allowed';

  const RemoteSyncAvailabilityDecision.denied(this.reason)
      : isAllowed = false;
}

class RemoteSyncAvailability {
  final bool hasRemoteConfiguration;

  const RemoteSyncAvailability({
    required this.hasRemoteConfiguration,
  });

  RemoteSyncAvailabilityDecision evaluate({
    required AppSession session,
    required SyncTrigger trigger,
    bool isNetworkAvailable = true,
  }) {
    if (!hasRemoteConfiguration) {
      return const RemoteSyncAvailabilityDecision.denied(
        'remote backend not configured',
      );
    }

    if (!isNetworkAvailable) {
      return const RemoteSyncAvailabilityDecision.denied(
        'network unavailable',
      );
    }

    if (!session.isAuthenticated) {
      return const RemoteSyncAvailabilityDecision.denied(
        'session is not authenticated',
      );
    }

    if (session.requiresInitialCloudMigration &&
        trigger != SyncTrigger.initialSignIn) {
      return const RemoteSyncAvailabilityDecision.denied(
        'initial cloud migration is pending',
      );
    }

    return const RemoteSyncAvailabilityDecision.allowed();
  }
}