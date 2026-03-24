import '../../core/logging/app_logger.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../domain/entities/app_user.dart';
import '../session/session_sync_service.dart';
import 'auth_session_service.dart';

class AuthSessionServiceImpl implements AuthSessionService {
  final AuthRemoteDataSource authRemoteDataSource;
  final SessionSyncService sessionSyncService;

  const AuthSessionServiceImpl({
    required this.authRemoteDataSource,
    required this.sessionSyncService,
  });

  @override
  Future<AuthSessionActionResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();

    final signInResult = await authRemoteDataSource.signInWithEmail(
      email: normalizedEmail,
      password: password,
    );

    return await signInResult.fold(
      (failure) async {
        AppLogger.warning(
          'Remote sign-in failed for $normalizedEmail: ${failure.message}',
          category: 'auth',
        );

        return AuthSessionActionResult(
          status: AuthSessionActionStatus.failed,
          message: 'sign-in failed: ${failure.message}',
        );
      },
      (AppUser user) async {
        AppLogger.info(
          'Remote sign-in succeeded for user ${user.id}; establishing authenticated session',
          category: 'auth',
        );

        final sessionResult =
            await sessionSyncService.establishAuthenticatedSession(user);

        if (sessionResult.isFailure) {
          AppLogger.error(
            'Authenticated session establishment failed after remote sign-in',
            category: 'auth',
            error: sessionResult.message,
          );

          return AuthSessionActionResult(
            status: AuthSessionActionStatus.failed,
            message:
                'sign-in succeeded but session initialization failed: ${sessionResult.message}',
            user: user,
            sessionResult: sessionResult,
          );
        }

        if (sessionResult.isSkipped) {
          AppLogger.warning(
            'Authenticated session establishment was skipped after remote sign-in: ${sessionResult.message}',
            category: 'auth',
          );

          return AuthSessionActionResult(
            status: AuthSessionActionStatus.failed,
            message:
                'sign-in succeeded but session initialization was skipped: ${sessionResult.message}',
            user: user,
            sessionResult: sessionResult,
          );
        }

        AppLogger.info(
          'Authenticated session established successfully for ${user.id}',
          category: 'auth',
        );

        return AuthSessionActionResult(
          status: AuthSessionActionStatus.completed,
          message: 'sign-in completed successfully',
          user: user,
          sessionResult: sessionResult,
        );
      },
    );
  }

  @override
  Future<SessionSyncActionResult> signOut() {
    return sessionSyncService.signOut();
  }
}