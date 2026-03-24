import '../../core/config/app_sync_policy.dart';
import '../../core/enums/sync_trigger.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/repositories/app_session_repository.dart';
import 'remote_sync_availability.dart';
import 'sync_feature.dart';
import 'sync_orchestrator.dart';

class SyncOrchestratorImpl implements SyncOrchestrator {
  final AppSessionRepository appSessionRepository;
  final AppSyncPolicy syncPolicy;
  final RemoteSyncAvailability remoteSyncAvailability;
  final List<SyncFeature> features;

  const SyncOrchestratorImpl({
    required this.appSessionRepository,
    required this.syncPolicy,
    required this.remoteSyncAvailability,
    required this.features,
  });

  @override
  Future<SyncRunResult> run(SyncTrigger trigger) async {
    if (!syncPolicy.syncTriggers.contains(trigger)) {
      return SyncRunResult(
        status: SyncRunStatus.skipped,
        trigger: trigger,
        message: 'trigger is disabled by sync policy',
      );
    }

    final sessionResult = await appSessionRepository.getCurrentSession();

    return await sessionResult.fold(
      (failure) async {
        AppLogger.warning(
          'Sync orchestration skipped because session lookup failed: ${failure.message}',
          category: 'sync',
        );

        return SyncRunResult(
          status: SyncRunStatus.failed,
          trigger: trigger,
          message: 'session lookup failed: ${failure.message}',
        );
      },
      (session) async {
        final availability = remoteSyncAvailability.evaluate(
          session: session,
          trigger: trigger,
        );

        if (!availability.isAllowed) {
          AppLogger.info(
            'Sync orchestration skipped for $trigger: ${availability.reason}',
            category: 'sync',
          );

          return SyncRunResult(
            status: SyncRunStatus.skipped,
            trigger: trigger,
            message: availability.reason,
          );
        }

        AppLogger.info(
          'Sync orchestration started for $trigger',
          category: 'sync',
        );

        final List<SyncFeatureRunResult> featureResults =
            <SyncFeatureRunResult>[];

        for (final feature in features) {
          try {
            await feature.syncPendingChanges();

            featureResults.add(
              SyncFeatureRunResult.success(feature.name),
            );

            AppLogger.info(
              'Feature sync completed: ${feature.name}',
              category: 'sync',
            );
          } catch (error, stackTrace) {
            featureResults.add(
              SyncFeatureRunResult.failure(
                featureName: feature.name,
                errorMessage: error.toString(),
              ),
            );

            AppLogger.error(
              'Feature sync failed: ${feature.name}',
              category: 'sync',
              error: error,
              stackTrace: stackTrace,
            );
          }
        }

        final bool hasFailures = featureResults.any(
          (result) => !result.isSuccess,
        );

        if (hasFailures) {
          return SyncRunResult(
            status: SyncRunStatus.failed,
            trigger: trigger,
            message: 'one or more feature sync operations failed',
            featureResults: featureResults,
          );
        }

        final recordSyncResult = await appSessionRepository
            .recordSuccessfulCloudSync(DateTime.now());

        recordSyncResult.fold(
          (failure) {
            AppLogger.warning(
              'Sync completed but lastCloudSyncAt could not be persisted: ${failure.message}',
              category: 'sync',
            );
          },
          (_) {
            AppLogger.info(
              'Recorded successful cloud sync timestamp',
              category: 'sync',
            );
          },
        );

        return SyncRunResult(
          status: SyncRunStatus.completed,
          trigger: trigger,
          message: 'sync orchestration completed successfully',
          featureResults: featureResults,
        );
      },
    );
  }
}