import '../enums/auth_mode.dart';
import '../enums/conflict_resolution_strategy.dart';
import '../enums/sync_trigger.dart';

class AppSyncPolicy {
  final bool offlineFirst;
  final bool localStoreAcceptsWrites;
  final bool remoteIsSourceOfTruthWhenAuthenticated;
  final bool guestModeUsesLocalStorageOnly;
  final bool authenticatedModeUsesUserScopedData;
  final bool initialCloudSyncUploadsLocalData;
  final ConflictResolutionStrategy conflictResolutionStrategy;
  final List<SyncTrigger> syncTriggers;

  const AppSyncPolicy({
    required this.offlineFirst,
    required this.localStoreAcceptsWrites,
    required this.remoteIsSourceOfTruthWhenAuthenticated,
    required this.guestModeUsesLocalStorageOnly,
    required this.authenticatedModeUsesUserScopedData,
    required this.initialCloudSyncUploadsLocalData,
    required this.conflictResolutionStrategy,
    required this.syncTriggers,
  });

  bool usesRemoteDataFor(AuthMode authMode) {
    if (authMode == AuthMode.guest) {
      return false;
    }

    return true;
  }

  static const AppSyncPolicy productionDefault = AppSyncPolicy(
    offlineFirst: true,
    localStoreAcceptsWrites: true,
    remoteIsSourceOfTruthWhenAuthenticated: true,
    guestModeUsesLocalStorageOnly: true,
    authenticatedModeUsesUserScopedData: true,
    initialCloudSyncUploadsLocalData: true,
    conflictResolutionStrategy: ConflictResolutionStrategy.serverWins,
    syncTriggers: <SyncTrigger>[
      SyncTrigger.appLaunch,
      SyncTrigger.appResume,
      SyncTrigger.manualRefresh,
      SyncTrigger.writeThrough,
      SyncTrigger.initialSignIn,
    ],
  );
}