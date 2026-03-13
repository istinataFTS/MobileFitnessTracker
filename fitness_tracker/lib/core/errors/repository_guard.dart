import 'package:dartz/dartz.dart';

import 'failures.dart';
import 'repository_error_mapper.dart';

class RepositoryGuard {
  const RepositoryGuard._();

  static Future<Either<Failure, T>> run<T>(
    Future<T> Function() action,
  ) async {
    try {
      final result = await action();
      return Right(result);
    } catch (error) {
      return Left(RepositoryErrorMapper.map(error));
    }
  }
}