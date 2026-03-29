import '../../../domain/entities/user_profile.dart';

abstract class UserProfileRemoteDataSource {
  bool get isConfigured;

  /// Returns `null` when no row exists for [userId].
  Future<UserProfile?> getProfile(String userId);

  /// Upserts the profile row and returns the persisted entity.
  Future<UserProfile> upsertProfile(UserProfile profile);
}
