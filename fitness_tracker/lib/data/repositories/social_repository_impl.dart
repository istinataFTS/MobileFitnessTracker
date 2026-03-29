import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
import '../../domain/entities/follow_counts.dart';
import '../../domain/entities/user_profile_summary.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/remote/social_remote_datasource.dart';

class SocialRepositoryImpl implements SocialRepository {
  const SocialRepositoryImpl({required this.remoteDataSource});

  final SocialRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, void>> follow(String targetUserId) {
    return RepositoryGuard.run(() => remoteDataSource.follow(targetUserId));
  }

  @override
  Future<Either<Failure, void>> unfollow(String targetUserId) {
    return RepositoryGuard.run(() => remoteDataSource.unfollow(targetUserId));
  }

  @override
  Future<Either<Failure, bool>> isFollowing(String targetUserId) {
    return RepositoryGuard.run(
      () => remoteDataSource.isFollowing(targetUserId),
    );
  }

  @override
  Future<Either<Failure, List<UserProfileSummary>>> getFollowers(
    String userId,
  ) {
    return RepositoryGuard.run(() => remoteDataSource.getFollowers(userId));
  }

  @override
  Future<Either<Failure, List<UserProfileSummary>>> getFollowing(
    String userId,
  ) {
    return RepositoryGuard.run(() => remoteDataSource.getFollowing(userId));
  }

  @override
  Future<Either<Failure, FollowCounts>> getFollowCounts(String userId) {
    return RepositoryGuard.run(() => remoteDataSource.getFollowCounts(userId));
  }
}
