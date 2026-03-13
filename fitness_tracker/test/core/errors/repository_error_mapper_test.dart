import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_tracker/core/errors/exceptions.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/core/errors/repository_error_mapper.dart';

void main() {
  group('RepositoryErrorMapper', () {
    test('maps ValidationException to ValidationFailure', () {
      final failure = RepositoryErrorMapper.map(
        const ValidationException('Invalid meal macros'),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'Invalid meal macros');
    });

    test('maps CacheDatabaseException to DatabaseFailure', () {
      final failure = RepositoryErrorMapper.map(
        const CacheDatabaseException('Database write failed'),
      );

      expect(failure, isA<DatabaseFailure>());
      expect(failure.message, 'Database write failed');
    });

    test('maps CacheException to CacheFailure', () {
      final failure = RepositoryErrorMapper.map(
        const CacheException('Cache miss'),
      );

      expect(failure, isA<CacheFailure>());
      expect(failure.message, 'Cache miss');
    });

    test('maps ArgumentError to ValidationFailure', () {
      final failure = RepositoryErrorMapper.map(
        ArgumentError('Invalid workout set input'),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.message, contains('Invalid workout set input'));
    });

    test('maps unknown errors to UnexpectedFailure', () {
      final failure = RepositoryErrorMapper.map(
        StateError('Something unexpected happened'),
      );

      expect(failure, isA<UnexpectedFailure>());
      expect(
        failure.message,
        'Unexpected error: Bad state: Something unexpected happened',
      );
    });
  });
}