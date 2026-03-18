import '../../../domain/entities/app_user.dart';
import 'auth_remote_datasource.dart';
import 'supabase_client_provider.dart';

class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final SupabaseClientProvider clientProvider;

  const SupabaseAuthRemoteDataSource({
    required this.clientProvider,
  });

  @override
  bool get isConfigured => clientProvider.isConfigured;

  @override
  Future<AppUser?> getCurrentUser() async {
    if (!isConfigured) {
      return null;
    }

    final user = clientProvider.client.auth.currentUser;
    if (user == null) {
      return null;
    }

    return _mapUser(user);
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await clientProvider.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw StateError('Supabase sign-in completed without a user.');
    }

    return _mapUser(user);
  }

  @override
  Future<void> signOut() {
    return clientProvider.client.auth.signOut();
  }

  AppUser _mapUser(dynamic user) {
    return AppUser(
      id: user.id as String,
      email: (user.email ?? '') as String,
      displayName: user.userMetadata?['display_name'] as String?,
    );
  }
}