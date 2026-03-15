import '../../../domain/entities/app_user.dart';

abstract class AuthRemoteDataSource {
  bool get isConfigured;

  Future<AppUser?> getCurrentUser();

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();
}