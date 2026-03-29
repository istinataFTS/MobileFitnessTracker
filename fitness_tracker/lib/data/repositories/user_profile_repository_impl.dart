import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/remote/user_profile_remote_datasource.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  const UserProfileRepositoryImpl({
    required this.remoteDataSource,
  });

  final UserProfileRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, UserProfile?>> getProfile(String userId) {
    return RepositoryGuard.run(() => remoteDataSource.getProfile(userId));
  }

  @override
  Future<Either<Failure, UserProfile>> upsertProfile(UserProfile profile) {
    return RepositoryGuard.run(() => remoteDataSource.upsertProfile(profile));
  }
}
