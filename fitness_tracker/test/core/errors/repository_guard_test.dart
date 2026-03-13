import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/errors/exceptions.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/core/errors/repository_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RepositoryGuard', () {
    test('returns Right when action succeeds', () async {
      final Either<Failure, int> result = await RepositoryGuard.run(() async {
        return 42;
      });

      expect(result, const Right(42));
    });

    test('maps CacheDatabaseException to DatabaseFailure', () async {
      final Either<Failure, int> result = await RepositoryGuard.run(() async {
        throw const CacheDatabaseException('db error');
      });

      expect(result, const Left(DatabaseFailure('db error')));
    });

    test('maps ValidationException to ValidationFailure', () async {
      final Either<Failure, int> result = await RepositoryGuard.run(() async {
        throw const ValidationException('invalid');
      });

      expect(result, const Left(ValidationFailure('invalid')));
    });

    test('maps unexpected errors to UnexpectedFailure', () async {
      final Either<Failure, int> result = await RepositoryGuard.run(() async {
        throw StateError('broken');
      });

      expect(
        result,
        const Left(UnexpectedFailure('Unexpected error: Bad state: broken')),
      );
    });
  });
}