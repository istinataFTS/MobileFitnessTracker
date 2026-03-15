import 'package:dartz/dartz.dart';

import '../../core/config/app_sync_policy.dart';
import '../../core/errors/failures.dart';
import '../entities/app_session.dart';
import '../entities/app_user.dart';

abstract class AppSessionRepository {
  Future<Either<Failure, AppSession>> getCurrentSession();

  Future<Either<Failure, void>> startGuestSession();

  Future<Either<Failure, void>> startAuthenticatedSession(
    AppUser user, {
    bool requiresInitialCloudMigration = true,
  });

  Future<Either<Failure, void>> completeInitialCloudMigration();

  Future<Either<Failure, void>> recordSuccessfulCloudSync(DateTime syncedAt);

  Future<Either<Failure, void>> clearSession();

  AppSyncPolicy get syncPolicy;
}