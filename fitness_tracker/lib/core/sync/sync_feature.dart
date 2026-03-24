typedef SyncFeatureRunner = Future<void> Function();

class SyncFeature {
  final String name;
  final SyncFeatureRunner syncPendingChanges;

  const SyncFeature({
    required this.name,
    required this.syncPendingChanges,
  });
}

class SyncFeatureRunResult {
  final String featureName;
  final bool isSuccess;
  final String? errorMessage;

  const SyncFeatureRunResult({
    required this.featureName,
    required this.isSuccess,
    this.errorMessage,
  });

  const SyncFeatureRunResult.success(String featureName)
      : featureName = featureName,
        isSuccess = true,
        errorMessage = null;

  const SyncFeatureRunResult.failure({
    required this.featureName,
    required this.errorMessage,
  }) : isSuccess = false;
}