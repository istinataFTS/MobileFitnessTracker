import '../../domain/repositories/app_session_repository.dart';

/// Identifier used for records that belong to an unauthenticated (guest)
/// session.  Centralised here so that writers and readers never drift apart.
const String kGuestUserId = '';

/// Resolves the identifier of the currently-active user (authenticated or
/// guest) from the [AppSessionRepository].  Returns [kGuestUserId] when the
/// session is a guest session, the user is missing, or the session read
/// fails for any reason.
///
/// This must stay the single source of truth for user-id resolution on both
/// the write path (e.g. `WorkoutBloc` recording stimulus) and the read path
/// (e.g. `MuscleVisualBloc` querying stimulus).  A mismatch between writer
/// and reader silently hides training data.
class CurrentUserIdResolver {
  const CurrentUserIdResolver({required this.appSessionRepository});

  final AppSessionRepository appSessionRepository;

  /// Resolves the active user id, or [kGuestUserId] for guest sessions.
  Future<String> resolve() async {
    final result = await appSessionRepository.getCurrentSession();
    return result.fold(
      (_) => kGuestUserId,
      (session) => session.user?.id ?? kGuestUserId,
    );
  }

  /// Whether the currently-active user is an authenticated (non-guest) user.
  Future<bool> hasAuthenticatedUser() async {
    final id = await resolve();
    return id.isNotEmpty;
  }
}
