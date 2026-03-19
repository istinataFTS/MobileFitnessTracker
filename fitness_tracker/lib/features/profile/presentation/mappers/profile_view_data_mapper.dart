import '../../../../core/constants/app_info.dart';
import '../../../../domain/entities/app_session.dart';
import '../../application/profile_cubit.dart';
import '../models/profile_view_data.dart';

class ProfileViewDataMapper {
  const ProfileViewDataMapper._();

  static ProfilePageViewData map(ProfileState state) {
    final AppSession session = state.session;
    final String? displayName = session.user?.displayName?.trim();
    final String? email = session.user?.email.trim();

    final String title = session.isAuthenticated
        ? ((displayName != null && displayName.isNotEmpty)
            ? displayName
            : 'Signed-in User')
        : 'Guest';

    final String subtitle = session.isAuthenticated
        ? ((email != null && email.isNotEmpty)
            ? email
            : 'Authenticated session')
        : 'Profile features will expand after auth is enabled';

    final String sessionBannerMessage = session.isAuthenticated
        ? 'This page is intentionally thin. The real profile should attach to authenticated server data, not local placeholders.'
        : 'You are currently in guest mode. This page is ready for auth states now, while keeping profile details deferred until Supabase-backed accounts are in place.';

    final String accountModeTitle = session.isAuthenticated
        ? 'Signed-in profile shell'
        : 'Guest profile shell';

    final String accountModeSubtitle = session.isAuthenticated
        ? 'Server-owned profile fields can attach here once auth is live'
        : 'Ready for auth, identity, and cloud sync later';

    final String cloudMigrationSubtitle = session.requiresInitialCloudMigration
        ? 'This session is marked as needing an initial cloud migration'
        : 'No initial cloud migration pending';

    final String lastSyncSubtitle = session.lastCloudSyncAt != null
        ? _formatDateTime(session.lastCloudSyncAt!)
        : 'No successful cloud sync recorded yet';

    return ProfilePageViewData(
      title: title,
      subtitle: subtitle,
      sessionBannerMessage: sessionBannerMessage,
      accountModeTitle: accountModeTitle,
      accountModeSubtitle: accountModeSubtitle,
      cloudMigrationSubtitle: cloudMigrationSubtitle,
      lastSyncSubtitle: lastSyncSubtitle,
      infoTiles: const <ProfileInfoTileViewData>[
        ProfileInfoTileViewData(
          title: AppInfo.name,
          subtitle: AppInfo.versionLabel,
        ),
      ],
      deferredItems: const <ProfileDeferredItemViewData>[
        ProfileDeferredItemViewData(
          title: 'Edit profile',
          subtitle:
              'Wait until profile data is owned by the authenticated user',
        ),
        ProfileDeferredItemViewData(
          title: 'Password and sign out',
          subtitle:
              'Keep these tied to the real auth provider, not a local placeholder',
        ),
        ProfileDeferredItemViewData(
          title: 'Avatar, handle, privacy, social presence',
          subtitle:
              'These are server-shaped and should land after Supabase auth',
        ),
      ],
      isLoading: state.isLoading && !state.hasLoaded,
      errorMessage: state.errorMessage,
    );
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