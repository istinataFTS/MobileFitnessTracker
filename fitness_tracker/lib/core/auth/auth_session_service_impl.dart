import '../../core/logging/app_logger.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../errors/sync_exceptions.dart';
import '../session/session_sync_service.dart';
import 'auth_session_service.dart';

class AuthSessionServiceImpl implements AuthSessionService {
  const AuthSessionServiceImpl({
    required this.authRemoteDataSource,
    required this.sessionSyncService,
    required this.userProfileRepository,
  });

  final AuthRemoteDataSource authRemoteDataSource;
  final SessionSyncService sessionSyncService;
  final UserProfileRepository userProfileRepository;

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
      // The profile will be created after the user confirms and signs in.
      if (result.requiresEmailConfirmation) {
        return AuthSessionActionResult(
          status: AuthSessionActionStatus.completed,
          message:
              'registration successful; check your email to confirm your account',
          user: result.user,
          requiresEmailConfirmation: true,
        );
      }

      // No email confirmation required — establish session then create profile.
      final sessionResult = await _establishSession(
        user: result.user,
        successMessage: 'sign-up completed successfully',
        actionLabel: 'sign-up',
      );

      if (sessionResult.isCompleted) {
        await _createInitialProfile(
          userId: result.user.id,
          username: normalizedUsername,
          displayName: result.user.displayName,
        );
      }

      return sessionResult;
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
        message: '$actionLabel succeeded but session initialization failed: '
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

  /// Creates the initial [UserProfile] row after a successful sign-up.
  /// Best-effort: logs failures but never blocks the sign-up result.
  Future<void> _createInitialProfile({
    required String userId,
    required String username,
    String? displayName,
  }) async {
    final now = DateTime.now();
    final profile = UserProfile(
      id: userId,
      username: username,
      displayName: displayName,
      createdAt: now,
      updatedAt: now,
    );

    final result = await userProfileRepository.upsertProfile(profile);

    result.fold(
      (failure) => AppLogger.warning(
        'Best-effort profile creation failed for $userId: ${failure.message}',
        category: 'auth',
      ),
      (_) => AppLogger.info(
        'Initial profile created for $userId (@$username)',
        category: 'auth',
      ),
    );
  }

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
