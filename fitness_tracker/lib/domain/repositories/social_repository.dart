import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/follow_counts.dart';
import '../entities/user_profile_summary.dart';

abstract class SocialRepository {
  /// Follows [targetUserId] as the currently authenticated user.
  Future<Either<Failure, void>> follow(String targetUserId);

  /// Unfollows [targetUserId] as the currently authenticated user.
  Future<Either<Failure, void>> unfollow(String targetUserId);

  /// Returns whether the currently authenticated user follows [targetUserId].
  Future<Either<Failure, bool>> isFollowing(String targetUserId);

  /// Returns the profiles of users who follow [userId].
  Future<Either<Failure, List<UserProfileSummary>>> getFollowers(String userId);

  /// Returns the profiles of users that [userId] follows.
  Future<Either<Failure, List<UserProfileSummary>>> getFollowing(String userId);

  /// Returns the follower and following counts for [userId].
  Future<Either<Failure, FollowCounts>> getFollowCounts(String userId);
}
