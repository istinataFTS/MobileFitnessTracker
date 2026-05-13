abstract class NetworkStatusService {
  /// One-shot check: resolves true when the network appears reachable.
  Future<bool> isNetworkAvailable();

  /// Emits `true` whenever the device transitions from offline → online.
  /// Implementations should only emit on state *changes*, not periodically.
  Stream<bool> get onConnectivityRestored;

  /// Emits the current online/offline status on every connectivity change.
  /// Unlike [onConnectivityRestored] (which emits only when coming online),
  /// this stream emits both `true` (online) and `false` (offline) so that
  /// consumers can react to either direction.
  Stream<bool> get onConnectivityChanged;
}
