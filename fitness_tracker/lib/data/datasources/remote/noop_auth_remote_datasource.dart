import '../../../domain/entities/app_user.dart';
import 'auth_remote_datasource.dart';

class NoopAuthRemoteDataSource implements AuthRemoteDataSource {
  const NoopAuthRemoteDataSource();

  @override
  bool get isConfigured => false;

  @override
  Future<AppUser?> getCurrentUser() async {
    return null;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw UnsupportedError('Remote auth is not configured.');
  }

  @override
  Future<void> signOut() async {}
}