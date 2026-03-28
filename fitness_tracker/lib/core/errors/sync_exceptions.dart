class NetworkSyncException implements Exception {
  final String message;
  final Object? cause;

  const NetworkSyncException(this.message, {this.cause});

  @override
  String toString() =>
      'NetworkSyncException: $message'
      '${cause != null ? ' (cause: $cause)' : ''}';
}

/// Thrown when a remote sync operation fails due to authentication
/// or authorization issues (e.g. expired token, missing user scope).
class AuthSyncException implements Exception {
  final String message;
  final Object? cause;

  const AuthSyncException(this.message, {this.cause});

  @override
  String toString() =>
      'AuthSyncException: $message'
      '${cause != null ? ' (cause: $cause)' : ''}';
}

/// Thrown when a remote sync operation fails at the backend level
/// for reasons that are not network or authentication related
/// (e.g. constraint violation, unexpected server response).
class RemoteSyncException implements Exception {
  final String message;
  final Object? cause;

  const RemoteSyncException(this.message, {this.cause});

  @override
  String toString() =>
      'RemoteSyncException: $message'
      '${cause != null ? ' (cause: $cause)' : ''}';
}
