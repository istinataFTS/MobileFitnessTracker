import 'package:fitness_tracker/core/errors/exceptions.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/core/errors/repository_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RepositoryErrorMapper', () {
    test('maps ValidationException to ValidationFailure', () {
      final Failure result = RepositoryErrorMapper.map(
        const ValidationException('invalid input'),
      );

      expect(result, const ValidationFailure('invalid input'));
    });

    test('maps CacheDatabaseException to DatabaseFailure', () {
      final Failure result = RepositoryErrorMapper.map(
        const CacheDatabaseException('db failed'),
      );

      expect(result, const DatabaseFailure('db failed'));
    });

    test('maps CacheException to CacheFailure', () {
      final Failure result = RepositoryErrorMapper.map(
        const CacheException('cache failed'),
      );

      expect(result, const CacheFailure('cache failed'));
    });

    test('maps ArgumentError to ValidationFailure', () {
      final Failure result = RepositoryErrorMapper.map(
        ArgumentError('bad argument'),
      );

      expect(result, const ValidationFailure('bad argument'));
    });

    test('maps unknown errors to UnexpectedFailure', () {
      final Failure result = RepositoryErrorMapper.map(
        StateError('boom'),
      );

      expect(result, const UnexpectedFailure('Unexpected error: Bad state: boom'));
    });
  });
}