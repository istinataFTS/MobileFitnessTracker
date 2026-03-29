import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user_profile.dart';
import '../entities/user_profile_summary.dart';

abstract class UserProfileRepository {
  /// Returns the full profile for [userId], or `null` if the row doesn't exist.
  /// Works for both the signed-in user and any other user (social lookups).
  Future<Either<Failure, UserProfile?>> getProfile(String userId);

  /// Semantic alias for [getProfile] — use this when looking up another user's
  /// profile to make the calling intent obvious.
  Future<Either<Failure, UserProfile?>> getProfileById(String userId);

  /// Inserts or updates the profile row for [profile.id].
  Future<Either<Failure, UserProfile>> upsertProfile(UserProfile profile);

  /// Returns profiles whose username contains [query] (case-insensitive).
  /// Results are limited to [limit] entries (default 20).
  Future<Either<Failure, List<UserProfileSummary>>> searchByUsername(
    String query, {
    int limit = 20,
  });
}
