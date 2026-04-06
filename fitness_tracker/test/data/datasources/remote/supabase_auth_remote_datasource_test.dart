import 'package:fitness_tracker/data/datasources/remote/noop_auth_remote_datasource.dart';
import 'package:fitness_tracker/data/datasources/remote/supabase_auth_remote_datasource.dart';
import 'package:fitness_tracker/data/datasources/remote/supabase_client_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupabaseAuthRemoteDataSource', () {
    test('reports isConfigured from provider when configured', () {
      const dataSource = SupabaseAuthRemoteDataSource(
        clientProvider: SupabaseClientProvider(isConfigured: true),
      );

      expect(dataSource.isConfigured, isTrue);
    });

    test('reports isConfigured from provider when not configured', () {
      const dataSource = SupabaseAuthRemoteDataSource(
        clientProvider: SupabaseClientProvider(isConfigured: false),
      );

      expect(dataSource.isConfigured, isFalse);
    });

    test('getCurrentUser returns null when not configured', () async {
      const dataSource = SupabaseAuthRemoteDataSource(
        clientProvider: SupabaseClientProvider(isConfigured: false),
      );

      final user = await dataSource.getCurrentUser();

      expect(user, isNull);
    });

    test('throws StateError when unconfigured provider client is accessed', () {
      const provider = SupabaseClientProvider(isConfigured: false);

      expect(() => provider.client, throwsStateError);
    });
  });

  // ---------------------------------------------------------------------------
  // NoopAuthRemoteDataSource
  // ---------------------------------------------------------------------------

  group('NoopAuthRemoteDataSource', () {
    const dataSource = NoopAuthRemoteDataSource();

    test('is never configured', () {
      expect(dataSource.isConfigured, isFalse);
    });

    test('getCurrentUser always returns null', () async {
      expect(await dataSource.getCurrentUser(), isNull);
    });

    test('signInWithEmail throws UnsupportedError', () async {
      await expectLater(
        dataSource.signInWithEmail(
          email: 'test@test.com',
          password: 'password',
        ),
        throwsUnsupportedError,
      );
    });

    test('signUpWithEmail throws UnsupportedError', () async {
      await expectLater(
        dataSource.signUpWithEmail(
          email: 'test@test.com',
          password: 'password',
          username: 'tester',
        ),
        throwsUnsupportedError,
      );
    });

    test('verifyEmailOtp throws UnsupportedError', () async {
      await expectLater(
        dataSource.verifyEmailOtp(email: 'test@test.com', token: '123456'),
        throwsUnsupportedError,
      );
    });

    test('sendPasswordResetEmail is a silent no-op', () async {
      await expectLater(
        dataSource.sendPasswordResetEmail(email: 'test@test.com'),
        completes,
      );
    });

    test('signOut is a silent no-op', () async {
      await expectLater(dataSource.signOut(), completes);
    });
  });
}
