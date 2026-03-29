import '../../../domain/entities/follow_counts.dart';
import '../../../domain/entities/user_profile_summary.dart';

abstract class SocialRemoteDataSource {
  bool get isConfigured;

  Future<void> follow(String targetUserId);
  Future<void> unfollow(String targetUserId);
  Future<bool> isFollowing(String targetUserId);
  Future<List<UserProfileSummary>> getFollowers(String userId);
  Future<List<UserProfileSummary>> getFollowing(String userId);
  Future<FollowCounts> getFollowCounts(String userId);
}
