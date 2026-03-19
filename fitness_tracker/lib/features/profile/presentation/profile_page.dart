import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/app_session.dart';
import '../../../domain/repositories/app_session_repository.dart';
import '../../../features/history/history.dart';
import '../../../features/settings/presentation/settings_page.dart';
import '../../../injection/injection_container.dart' as di;
import '../../../presentation/pages/targets/targets_page.dart';
import '../application/profile_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Key loadingIndicatorKey = ValueKey<String>(
    'profile_loading_indicator',
  );
  static const Key refreshListKey = ValueKey<String>(
    'profile_refresh_list',
  );
  static const Key titleKey = ValueKey<String>(
    'profile_title',
  );
  static const Key subtitleKey = ValueKey<String>(
    'profile_subtitle',
  );
  static const Key sessionBannerKey = ValueKey<String>(
    'profile_session_banner',
  );
  static const Key settingsTileKey = ValueKey<String>(
    'profile_settings_tile',
  );
  static const Key targetsTileKey = ValueKey<String>(
    'profile_targets_tile',
  );
  static const Key historyTileKey = ValueKey<String>(
    'profile_history_tile',
  );
  static const Key accountStatusTileKey = ValueKey<String>(
    'profile_account_status_tile',
  );
  static const Key cloudMigrationTileKey = ValueKey<String>(
    'profile_cloud_migration_tile',
  );
  static const Key lastSyncTileKey = ValueKey<String>(
    'profile_last_sync_tile',
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create: (_) => ProfileCubit(
        repository: di.sl<AppSessionRepository>(),
      )..loadProfile(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (ProfileState previous, ProfileState current) =>
          previous.errorMessage != current.errorMessage,
      listener: (BuildContext context, ProfileState state) {
        if (state.errorMessage == null || state.errorMessage!.isEmpty) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load profile session. Showing guest shell. ${state.errorMessage}',
            ),
          ),
        );

        context.read<ProfileCubit>().clearError();
      },
      builder: (BuildContext context, ProfileState state) {
        final AppSession session = state.session;

        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          appBar: AppBar(
            title: const Text('Profile'),
            automaticallyImplyLeading: false,
          ),
          body: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    key: ProfilePage.loadingIndicatorKey,
                    color: AppTheme.primaryOrange,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<ProfileCubit>().refreshProfile(),
                  color: AppTheme.primaryOrange,
                  child: ListView(
                    key: ProfilePage.refreshListKey,
                    padding: const EdgeInsets.all(20),
                    children: <Widget>[
                      const SizedBox(height: 20),
                      _ProfileHeader(session: session),
                      const SizedBox(height: 24),
                      _ProfileSessionBanner(session: session),
                      const SizedBox(height: 32),
                      _ProfileSection(
                        title: 'Your Space',
                        children: <Widget>[
                          _NavigationTile(
                            tileKey: ProfilePage.settingsTileKey,
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            subtitle: 'App preferences and local configuration',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const SettingsPage(),
                                ),
                              );
                            },
                          ),
                          _NavigationTile(
                            tileKey: ProfilePage.targetsTileKey,
                            icon: Icons.flag_outlined,
                            title: 'Targets',
                            subtitle: 'Manage your weekly muscle group goals',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const TargetsPage(),
                                ),
                              );
                            },
                          ),
                          _NavigationTile(
                            tileKey: ProfilePage.historyTileKey,
                            icon: Icons.history_outlined,
                            title: 'History',
                            subtitle: 'Review logged workouts and progress',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const HistoryPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _ProfileSection(
                        title: 'Account Status',
                        children: <Widget>[
                          _StatusTile(
                            tileKey: ProfilePage.accountStatusTileKey,
                            icon: session.isAuthenticated
                                ? Icons.verified_user_outlined
                                : Icons.person_outline,
                            title: session.isAuthenticated
                                ? 'Signed-in profile shell'
                                : 'Guest profile shell',
                            subtitle: session.isAuthenticated
                                ? 'Server-owned profile fields can attach here once auth is live'
                                : 'Ready for auth, identity, and cloud sync later',
                          ),
                          _StatusTile(
                            tileKey: ProfilePage.cloudMigrationTileKey,
                            icon: Icons.cloud_sync_outlined,
                            title: 'Cloud migration readiness',
                            subtitle: session.requiresInitialCloudMigration
                                ? 'This session is marked as needing an initial cloud migration'
                                : 'No initial cloud migration pending',
                          ),
                          _StatusTile(
                            tileKey: ProfilePage.lastSyncTileKey,
                            icon: Icons.sync_outlined,
                            title: 'Last cloud sync',
                            subtitle: session.lastCloudSyncAt != null
                                ? _formatDateTime(session.lastCloudSyncAt!)
                                : 'No successful cloud sync recorded yet',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _ProfileSection(
                        title: 'Deferred Until Auth / Supabase',
                        children: <Widget>[
                          _StaticInfoTile(
                            icon: Icons.badge_outlined,
                            title: 'Edit profile',
                            subtitle:
                                'Wait until profile data is owned by the authenticated user',
                          ),
                          _StaticInfoTile(
                            icon: Icons.lock_outline,
                            title: 'Password and sign out',
                            subtitle:
                                'Keep these tied to the real auth provider, not a local placeholder',
                          ),
                          _StaticInfoTile(
                            icon: Icons.public_outlined,
                            title: 'Avatar, handle, privacy, social presence',
                            subtitle:
                                'These are server-shaped and should land after Supabase auth',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _ProfileSection(
                        title: 'About',
                        children: <Widget>[
                          _StatusTile(
                            icon: Icons.info_outline,
                            title: AppInfo.name,
                            subtitle: AppInfo.versionLabel,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        );
      },
    );
  }

  String _formatDateTime(DateTime value) {
    final String year = value.year.toString().padLeft(4, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.session,
  });

  final AppSession session;

  @override
  Widget build(BuildContext context) {
    final String? displayName = session.user?.displayName?.trim();
    final String? email = session.user?.email.trim();

    final String titleText = session.isAuthenticated
        ? ((displayName != null && displayName.isNotEmpty)
            ? displayName
            : 'Signed-in User')
        : 'Guest';

    final String subtitleText = session.isAuthenticated
        ? ((email != null && email.isNotEmpty)
            ? email
            : 'Authenticated session')
        : 'Profile features will expand after auth is enabled';

    return Column(
      children: <Widget>[
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryOrange.withOpacity(0.3),
              width: 4,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          titleText,
          key: ProfilePage.titleKey,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitleText,
          key: ProfilePage.subtitleKey,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textMedium,
              ),
        ),
      ],
    );
  }
}

class _ProfileSessionBanner extends StatelessWidget {
  const _ProfileSessionBanner({
    required this.session,
  });

  final AppSession session;

  @override
  Widget build(BuildContext context) {
    final String message = session.isAuthenticated
        ? 'This page is intentionally thin. The real profile should attach to authenticated server data, not local placeholders.'
        : 'You are currently in guest mode. This page is ready for auth states now, while keeping profile details deferred until Supabase-backed accounts are in place.';

    return Container(
      key: ProfilePage.sessionBannerKey,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.info_outline,
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: tileKey,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryOrange, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textDim,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Key? tileKey;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: tileKey,
        leading: Icon(icon, color: AppTheme.textMedium),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _StaticInfoTile extends StatelessWidget {
  const _StaticInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textMedium),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}