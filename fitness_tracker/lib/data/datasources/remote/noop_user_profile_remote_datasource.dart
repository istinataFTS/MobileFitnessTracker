import '../../../domain/entities/user_profile.dart';
import 'user_profile_remote_datasource.dart';

class NoopUserProfileRemoteDataSource implements UserProfileRemoteDataSource {
  const NoopUserProfileRemoteDataSource();

  @override
  bool get isConfigured => false;

  @override
  Future<UserProfile?> getProfile(String userId) async => null;

  @override
  Future<UserProfile> upsertProfile(UserProfile profile) {
    throw UnsupportedError(
      'NoopUserProfileRemoteDataSource does not support upsertProfile.',
    );
  }
}
