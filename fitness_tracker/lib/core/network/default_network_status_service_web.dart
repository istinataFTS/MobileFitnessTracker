import 'dart:async';

import 'network_status_service.dart';

/// Web stub for [DefaultNetworkStatusService].
/// On web, dart:io and connectivity_plus are unavailable.
/// Sync is skipped entirely on web (handled in AppBootstrapper),
/// so this implementation is never meaningfully called.
class DefaultNetworkStatusService implements NetworkStatusService {
  const DefaultNetworkStatusService();

  @override
  Future<bool> isNetworkAvailable() async => true;

  /// On web, connectivity events are not monitored.
  /// The stream never emits because sync lifecycle hooks are skipped on web.
  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();
}
