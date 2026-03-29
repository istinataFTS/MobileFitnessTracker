import '../../../domain/entities/follow_counts.dart';
import '../../../domain/entities/user_profile_summary.dart';
import 'social_remote_datasource.dart';

class NoopSocialRemoteDataSource implements SocialRemoteDataSource {
  const NoopSocialRemoteDataSource();

  @override
  bool get isConfigured => false;

  @override
  Future<void> follow(String targetUserId) async {}

  @override
  Future<void> unfollow(String targetUserId) async {}

  @override
  Future<bool> isFollowing(String targetUserId) async => false;

  @override
  Future<List<UserProfileSummary>> getFollowers(String userId) async =>
      const <UserProfileSummary>[];

  @override
  Future<List<UserProfileSummary>> getFollowing(String userId) async =>
      const <UserProfileSummary>[];

  @override
  Future<FollowCounts> getFollowCounts(String userId) async =>
      const FollowCounts.zero();
}
