import '../../core/logging/app_logger.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../domain/entities/app_user.dart';
import '../errors/sync_exceptions.dart';
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

    try {
      final AppUser user = await authRemoteDataSource.signInWithEmail(
        email: normalizedEmail,
        password: password,
      );

      AppLogger.info(
        'Remote sign-in succeeded for user ${user.id}; establishing session',
        category: 'auth',
      );

      return await _establishSession(
        user: user,
        successMessage: 'sign-in completed successfully',
        actionLabel: 'sign-in',
      );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Remote sign-in failed for $normalizedEmail: $error',
        category: 'auth',
      );
      AppLogger.debug(
        'Remote sign-in stack trace: $stackTrace',
        category: 'auth',
      );

      return AuthSessionActionResult(
        status: AuthSessionActionStatus.failed,
        message: _resolveErrorMessage(error, action: 'sign-in'),
      );
    }
  }

  @override
  Future<AuthSessionActionResult> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final normalizedEmail = email.trim();
    final normalizedUsername = username.trim();

    try {
      final result = await authRemoteDataSource.signUpWithEmail(
        email: normalizedEmail,
        password: password,
        username: normalizedUsername,
      );

      AppLogger.info(
        'Remote sign-up succeeded for ${result.user.id}; '
        'requiresEmailConfirmation=${result.requiresEmailConfirmation}',
        category: 'auth',
      );

      // Email confirmation required — account created but no session yet.
      // Return a success so the UI can show the "check your inbox" screen.
      if (result.requiresEmailConfirmation) {
        return AuthSessionActionResult(
          status: AuthSessionActionStatus.completed,
          message:
              'registration successful; check your email to confirm your account',
          user: result.user,
          requiresEmailConfirmation: true,
        );
      }

      // No email confirmation required — establish the local session now.
      return await _establishSession(
        user: result.user,
        successMessage: 'sign-up completed successfully',
        actionLabel: 'sign-up',
      );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Remote sign-up failed for $normalizedEmail: $error',
        category: 'auth',
      );
      AppLogger.debug(
        'Remote sign-up stack trace: $stackTrace',
        category: 'auth',
      );

      return AuthSessionActionResult(
        status: AuthSessionActionStatus.failed,
        message: _resolveErrorMessage(error, action: 'sign-up'),
      );
    }
  }

  @override
  Future<SessionSyncActionResult> signOut() {
    return sessionSyncService.signOut();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Calls [sessionSyncService.establishAuthenticatedSession] and maps the
  /// result to an [AuthSessionActionResult].
  Future<AuthSessionActionResult> _establishSession({
    required AppUser user,
    required String successMessage,
    required String actionLabel,
  }) async {
    final sessionResult =
        await sessionSyncService.establishAuthenticatedSession(user);

    if (sessionResult.isFailure) {
      AppLogger.error(
        'Session establishment failed after $actionLabel for ${user.id}',
        category: 'auth',
        error: sessionResult.message,
      );

      return AuthSessionActionResult(
        status: AuthSessionActionStatus.failed,
        message:
            '$actionLabel succeeded but session initialization failed: '
            '${sessionResult.message}',
        user: user,
        sessionResult: sessionResult,
      );
    }

    if (sessionResult.isSkipped) {
      AppLogger.warning(
        'Session establishment skipped after $actionLabel for ${user.id}: '
        '${sessionResult.message}',
        category: 'auth',
      );

      return AuthSessionActionResult(
        status: AuthSessionActionStatus.failed,
        message:
            '$actionLabel succeeded but session initialization was skipped: '
            '${sessionResult.message}',
        user: user,
        sessionResult: sessionResult,
      );
    }

    AppLogger.info(
      'Session established successfully for ${user.id}',
      category: 'auth',
    );

    return AuthSessionActionResult(
      status: AuthSessionActionStatus.completed,
      message: successMessage,
      user: user,
      sessionResult: sessionResult,
    );
  }

  /// Maps typed sync exceptions to user-facing messages.
  static String _resolveErrorMessage(Object error, {required String action}) {
    if (error is AuthSyncException) {
      return '$action failed: ${error.message}';
    }
    if (error is NetworkSyncException) {
      return 'Network unavailable. Please check your connection.';
    }
    if (error is RemoteSyncException) {
      return 'Service error. Please try again later.';
    }
    return '$action failed: $error';
  }
}
