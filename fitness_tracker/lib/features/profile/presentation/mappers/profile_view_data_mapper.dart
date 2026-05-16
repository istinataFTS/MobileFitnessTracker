import '../../../../core/session/session_display_name.dart';
import '../../../../domain/entities/app_session.dart';
import '../../../../domain/entities/user_profile.dart';
import '../../application/profile_cubit.dart';
import '../models/profile_view_data.dart';

class ProfileViewDataMapper {
  const ProfileViewDataMapper._();

  static ProfilePageViewData map(ProfileState state) {
    final AppSession session = state.session;
    final UserProfile? profile = state.userProfile;

    // ---------------------------------------------------------------------------
    // Title / subtitle
    // Prefer real profile data; fall back to auth user fields; then guest label.
    // ---------------------------------------------------------------------------
    final String title = _resolveTitle(session, profile);
    final String subtitle = _resolveSubtitle(session, profile);

    // ---------------------------------------------------------------------------
    // Session / account mode copy
    // ---------------------------------------------------------------------------
    final String sessionBannerMessage = session.isAuthenticated
        ? 'Your data is backed by the cloud and stays in sync across devices.'
        : 'You are in guest mode. Sign in to enable cloud sync and social features.';

    final String accountModeTitle = session.isAuthenticated
        ? 'Cloud account'
        : 'Guest account';

    final String accountModeSubtitle = session.isAuthenticated
        ? 'Data is owned and synced with your authenticated account'
        : 'Data is stored locally only — sign in to back it up';

    return ProfilePageViewData(
      title: title,
      subtitle: subtitle,
      sessionBannerMessage: sessionBannerMessage,
      accountModeTitle: accountModeTitle,
      accountModeSubtitle: accountModeSubtitle,
      isLoading: state.isLoading && !state.hasLoaded,
      errorMessage: state.errorMessage,
      username: profile?.username,
      bio: profile?.bio,
    );
  }

  static String _resolveTitle(AppSession session, UserProfile? profile) =>
      SessionDisplayName.resolve(session, profile);

  static String _resolveSubtitle(AppSession session, UserProfile? profile) {
    if (!session.isAuthenticated) {
      return 'Sign in to unlock cloud sync and social features';
    }

    final String? handle = profile?.username;
    if (handle != null && handle.isNotEmpty) {
      return '@$handle';
    }

    return session.user?.email.trim().nullIfEmpty() ?? 'Authenticated session';
  }
}

extension _NullIfEmpty on String {
  String? nullIfEmpty() => isEmpty ? null : this;
}
