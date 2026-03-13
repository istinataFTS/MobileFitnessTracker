import 'exceptions.dart';
import 'failures.dart';

class RepositoryErrorMapper {
  const RepositoryErrorMapper._();

  static Failure map(Object error) {
    if (error is ValidationException) {
      return ValidationFailure(error.message);
    }

    if (error is CacheDatabaseException) {
      return DatabaseFailure(error.message);
    }

    if (error is CacheException) {
      return CacheFailure(error.message);
    }

    if (error is ArgumentError) {
      return ValidationFailure(error.message?.toString() ?? error.toString());
    }

    return UnexpectedFailure('Unexpected error: $error');
  }
}