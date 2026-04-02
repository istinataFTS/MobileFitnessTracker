/// Exports the correct [DefaultNetworkStatusService] implementation
/// based on the target platform:
/// - Native (Android/iOS): uses dart:io + connectivity_plus
/// - Web: uses a no-op stub (sync is skipped on web entirely)
export 'default_network_status_service_native.dart'
    if (dart.library.html) 'default_network_status_service_web.dart';
