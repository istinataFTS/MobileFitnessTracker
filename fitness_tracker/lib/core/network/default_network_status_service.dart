import 'dart:async';
import 'dart:io';

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
}
