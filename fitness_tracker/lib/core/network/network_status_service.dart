abstract class NetworkStatusService {
  /// One-shot check: resolves true when the network appears reachable.
  Future<bool> isNetworkAvailable();

  /// Emits true whenever the device transitions from offline → online.
  /// Implementations should only emit on state *changes*, not periodically.
  Stream<bool> get onConnectivityRestored;
}