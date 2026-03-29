import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user_profile.dart';

abstract class UserProfileRepository {
  /// Returns `null` when no profile row exists yet for [userId].
  Future<Either<Failure, UserProfile?>> getProfile(String userId);

  /// Inserts or updates the profile row for [profile.id].
  /// Safe to call on every sign-up — the underlying datasource uses upsert.
  Future<Either<Failure, UserProfile>> upsertProfile(UserProfile profile);
}
