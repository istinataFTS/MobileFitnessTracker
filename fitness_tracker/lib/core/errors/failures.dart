import 'package:equatable/equatable.dart';

/// Base failure class for error handling throughout the app
/// 
/// All failures extend this base class and use Equatable for comparison.
/// Failures represent errors that have been handled and converted from exceptions.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Database operation failure
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

/// Cache operation failure (in-memory)
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Input validation failure
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// ⭐ NEW - Unexpected/unknown failure (catch-all for unhandled errors)
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}