class CacheDatabaseException implements Exception {
  final String message;
  const CacheDatabaseException(this.message);
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
}