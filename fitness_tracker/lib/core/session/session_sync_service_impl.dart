import '../../core/logging/app_logger.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../enums/sync_trigger.dart';
import '../sync/sync_orchestrator.dart';
import 'session_sync_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/app_session_repository.dart';

class SessionSyncServiceImpl implements SessionSyncService {
  final AppSessionRepository appSessionRepository;
  final AuthRemoteDataSource authRemoteDataSource;
  final SyncOrchestrator syncOrchestrator;

  const SessionSyncServiceImpl({
    required this.appSessionRepository,
    required this.authRemoteDataSource,
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
          'Authenticated session persisted; starting authenticated session synchronization',
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

  @override
  Future<SessionSyncActionResult> signOut() async {
    try {
      await authRemoteDataSource.signOut();
    } catch (error) {
      AppLogger.warning(
        'Remote sign-out failed: $error',
        category: 'session',
      );

      return SessionSyncActionResult(
        status: SessionSyncActionStatus.failed,
        message: 'sign-out failed: $error',
      );
    }

    final clearSessionResult = await appSessionRepository.clearSession();

    return await clearSessionResult.fold(
      (failure) async {
        AppLogger.error(
          'Remote sign-out succeeded but local session clear failed',
          category: 'session',
          error: failure,
        );

        return SessionSyncActionResult(
          status: SessionSyncActionStatus.failed,
          message:
              'sign-out succeeded remotely but local session reset failed: ${failure.message}',
        );
      },
      (_) async {
        AppLogger.info(
          'Session signed out and local session reset completed',
          category: 'session',
        );

        return const SessionSyncActionResult(
          status: SessionSyncActionStatus.completed,
          message: 'sign-out completed successfully',
        );
      },
    );
  }
}
