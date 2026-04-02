import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'network_status_service.dart';

class DefaultNetworkStatusService implements NetworkStatusService {
  const DefaultNetworkStatusService();

  @override
  Future<bool> isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Emits `true` each time connectivity transitions from none → any network.
  /// Uses connectivity_plus for efficient platform-level change detection,
  /// then confirms actual internet reachability before emitting.
  @override
  Stream<bool> get onConnectivityRestored {
    return Connectivity()
        .onConnectivityChanged
        .asyncMap((List<ConnectivityResult> results) async {
          final bool hasInterface = results.any(
            (ConnectivityResult r) => r != ConnectivityResult.none,
          );
          if (!hasInterface) return false;
          // Verify we actually have internet, not just a local network.
          return isNetworkAvailable();
        })
        .where((bool reachable) => reachable)
        .distinct();
  }
}
