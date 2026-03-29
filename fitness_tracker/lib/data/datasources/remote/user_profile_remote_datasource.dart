import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/user_profile_summary.dart';

abstract class UserProfileRemoteDataSource {
  bool get isConfigured;

  Future<UserProfile?> getProfile(String userId);

  Future<UserProfile> upsertProfile(UserProfile profile);

  /// Case-insensitive username prefix/substring search.
  Future<List<UserProfileSummary>> searchByUsername(
    String query, {
    int limit = 20,
  });
}
