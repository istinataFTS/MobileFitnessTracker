import '../../core/logging/app_logger.dart';
import '../sync/sync_orchestrator.dart';
import '../enums/sync_trigger.dart';
import 'session_sync_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/app_session_repository.dart';

class SessionSyncServiceImpl implements SessionSyncService {
  final AppSessionRepository appSessionRepository;
  final SyncOrchestrator syncOrchestrator;

  const SessionSyncServiceImpl({
    required this.appSessionRepository,
    required this.syncOrchestrator,
  });

  @override
  Future<SessionSyncActionResult> establishAuthenticatedSession(
    AppUser user,
  ) async {
    final bool requiresInitialCloudMigration = appSessionRepository
        .syncPolicy
        .initialCloudSyncUploadsLocalData;

    final startSessionResult = await appSessionRepository
        .startAuthenticatedSession(
      user,
      requiresInitialCloudMigration: requiresInitialCloudMigration,
    );

    return await startSessionResult.fold(
      (failure) async {
        AppLogger.error(
          'Failed to persist authenticated session',
          category: 'session',
          error: failure,
        );

        return SessionSyncActionResult(
          status: SessionSyncActionStatus.failed,
          message: 'failed to persist authenticated session: ${failure.message}',
        );
      },
      (_) async {
        AppLogger.info(
          'Authenticated session persisted; starting initial sign-in sync',
          category: 'session',
        );

        final syncResult = await syncOrchestrator.run(
          SyncTrigger.initialSignIn,
        );

        if (syncResult.isFailure) {
          return SessionSyncActionResult(
            status: SessionSyncActionStatus.failed,
            message: 'initial sign-in sync failed: ${syncResult.message}',
            syncResult: syncResult,
          );
        }

        if (syncResult.isSkipped) {
          return SessionSyncActionResult(
            status: SessionSyncActionStatus.skipped,
            message: 'initial sign-in sync skipped: ${syncResult.message}',
            syncResult: syncResult,
          );
        }

        if (requiresInitialCloudMigration) {
          final completeMigrationResult =
              await appSessionRepository.completeInitialCloudMigration();

          return await completeMigrationResult.fold(
            (failure) async {
              AppLogger.warning(
                'Initial sign-in sync completed but migration flag could not be cleared: ${failure.message}',
                category: 'session',
              );

              return SessionSyncActionResult(
                status: SessionSyncActionStatus.failed,
                message:
                    'initial sign-in sync completed but migration finalization failed: ${failure.message}',
                syncResult: syncResult,
              );
            },
            (_) async {
              AppLogger.info(
                'Initial cloud migration marked complete',
                category: 'session',
              );

              return SessionSyncActionResult(
                status: SessionSyncActionStatus.completed,
                message:
                    'authenticated session established and initial migration completed',
                syncResult: syncResult,
              );
            },
          );
        }

        return SessionSyncActionResult(
          status: SessionSyncActionStatus.completed,
          message: 'authenticated session established',
          syncResult: syncResult,
        );
      },
    );
  }

  @override
  Future<SessionSyncActionResult> runManualRefresh() async {
    final syncResult = await syncOrchestrator.run(SyncTrigger.manualRefresh);

    switch (syncResult.status) {
      case SyncRunStatus.completed:
        return SessionSyncActionResult(
          status: SessionSyncActionStatus.completed,
          message: 'manual refresh completed successfully',
          syncResult: syncResult,
        );
      case SyncRunStatus.skipped:
        return SessionSyncActionResult(
          status: SessionSyncActionStatus.skipped,
          message: 'manual refresh skipped: ${syncResult.message}',
          syncResult: syncResult,
        );
      case SyncRunStatus.failed:
        return SessionSyncActionResult(
          status: SessionSyncActionStatus.failed,
          message: 'manual refresh failed: ${syncResult.message}',
          syncResult: syncResult,
        );
    }
  }
}