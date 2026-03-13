import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_tracker/core/errors/exceptions.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/core/errors/repository_guard.dart';

void main() {
  group('RepositoryGuard', () {
    test('returns Right when action succeeds', () async {
      final result = await RepositoryGuard.run(() async {
        return 42;
      });

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => -1), 42);
    });

    test('maps ValidationException to ValidationFailure', () async {
      final result = await RepositoryGuard.run<int>(() async {
        throw const ValidationException('Validation failed');
      });

      expect(result.isLeft(), isTrue);

      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, 'Validation failed');
        },
        (_) => fail('Expected a failure result'),
      );
    });

    test('maps CacheDatabaseException to DatabaseFailure', () async {
      final result = await RepositoryGuard.run<void>(() async {
        throw const CacheDatabaseException('DB unavailable');
      });

      expect(result.isLeft(), isTrue);

      result.fold(
        (failure) {
          expect(failure, isA<DatabaseFailure>());
          expect(failure.message, 'DB unavailable');
        },
        (_) => fail('Expected a failure result'),
      );
    });

    test('maps CacheException to CacheFailure', () async {
      final result = await RepositoryGuard.run<String>(() async {
        throw const CacheException('Cache lookup failed');
      });

      expect(result.isLeft(), isTrue);

      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.message, 'Cache lookup failed');
        },
        (_) => fail('Expected a failure result'),
      );
    });

    test('maps unknown exceptions to UnexpectedFailure', () async {
      final result = await RepositoryGuard.run<void>(() async {
        throw StateError('Unexpected repository issue');
      });

      expect(result.isLeft(), isTrue);

      result.fold(
        (failure) {
          expect(failure, isA<UnexpectedFailure>());
          expect(
            failure.message,
            'Unexpected error: Bad state: Unexpected repository issue',
          );
        },
        (_) => fail('Expected a failure result'),
      );
    });
  });
}