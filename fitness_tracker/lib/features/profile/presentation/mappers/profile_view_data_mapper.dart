import '../../../../core/constants/app_info.dart';
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

    final String accountModeTitle =
        session.isAuthenticated ? 'Cloud account' : 'Guest account';

    final String accountModeSubtitle = session.isAuthenticated
        ? 'Data is owned and synced with your authenticated account'
        : 'Data is stored locally only — sign in to back it up';

    final String cloudMigrationSubtitle =
        session.requiresInitialCloudMigration
            ? 'Waiting to upload local data to the cloud'
            : 'No initial migration pending';

    final String lastSyncSubtitle = session.lastCloudSyncAt != null
        ? _formatDateTime(session.lastCloudSyncAt!)
        : 'No successful cloud sync recorded yet';

    // ---------------------------------------------------------------------------
    // Deferred items — only list things genuinely not yet built
    // ---------------------------------------------------------------------------
    final List<ProfileDeferredItemViewData> deferredItems =
        session.isAuthenticated
            ? const <ProfileDeferredItemViewData>[
                ProfileDeferredItemViewData(
                  title: 'Avatar',
                  subtitle: 'Image upload requires cloud storage integration',
                ),
                ProfileDeferredItemViewData(
                  title: 'Social presence',
                  subtitle:
                      'Followers, following, and public profile coming in Phase 5',
                ),
              ]
            : const <ProfileDeferredItemViewData>[
                ProfileDeferredItemViewData(
                  title: 'All profile features',
                  subtitle: 'Sign in to unlock cloud-backed profile data',
                ),
              ];

    return ProfilePageViewData(
      title: title,
      subtitle: subtitle,
      sessionBannerMessage: sessionBannerMessage,
      accountModeTitle: accountModeTitle,
      accountModeSubtitle: accountModeSubtitle,
      cloudMigrationSubtitle: cloudMigrationSubtitle,
      lastSyncSubtitle: lastSyncSubtitle,
      infoTiles: <ProfileInfoTileViewData>[
        ProfileInfoTileViewData(
          title: AppInfo.name,
          subtitle: AppInfo.versionLabel,
        ),
      ],
      deferredItems: deferredItems,
      isLoading: state.isLoading && !state.hasLoaded,
      errorMessage: state.errorMessage,
      username: profile?.username,
      bio: profile?.bio,
    );
  }

  static String _resolveTitle(AppSession session, UserProfile? profile) {
    if (!session.isAuthenticated) {
      return 'Guest';
    }

    final String? name =
        profile?.displayName?.trim().nullIfEmpty() ??
        session.user?.displayName?.trim().nullIfEmpty();

    return name ?? profile?.username ?? 'Signed-in User';
  }

  static String _resolveSubtitle(AppSession session, UserProfile? profile) {
    if (!session.isAuthenticated) {
      return 'Sign in to unlock cloud sync and social features';
    }

    final String? handle = profile?.username;
    if (handle != null && handle.isNotEmpty) {
      return '@$handle';
    }

    return session.user?.email.trim() ?? 'Authenticated session';
  }

  static String _formatDateTime(DateTime value) {
    final String year = value.year.toString().padLeft(4, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

extension _NullIfEmpty on String {
  String? nullIfEmpty() => isEmpty ? null : this;
}
