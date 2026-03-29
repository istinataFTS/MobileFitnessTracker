import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_profile_summary.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/remote/user_profile_remote_datasource.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  const UserProfileRepositoryImpl({required this.remoteDataSource});

  final UserProfileRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, UserProfile?>> getProfile(String userId) {
    return RepositoryGuard.run(() => remoteDataSource.getProfile(userId));
  }

  /// Delegates to [getProfile] — exists for call-site clarity when looking up
  /// another user's profile in a social context.
  @override
  Future<Either<Failure, UserProfile?>> getProfileById(String userId) =>
      getProfile(userId);

  @override
  Future<Either<Failure, UserProfile>> upsertProfile(UserProfile profile) {
    return RepositoryGuard.run(() => remoteDataSource.upsertProfile(profile));
  }

  @override
  Future<Either<Failure, List<UserProfileSummary>>> searchByUsername(
    String query, {
    int limit = 20,
  }) {
    return RepositoryGuard.run(
      () => remoteDataSource.searchByUsername(query, limit: limit),
    );
  }
}
