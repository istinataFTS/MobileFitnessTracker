import 'package:flutter/material.dart';

import '../../../../core/themes/app_theme.dart';
import '../models/profile_view_data.dart';
import '../profile_page_keys.dart';

class ProfileContent extends StatelessWidget {
  const ProfileContent({
    super.key,
    required this.viewData,
    required this.onRefresh,
    required this.onOpenSettings,
    required this.onOpenTargets,
    required this.onOpenHistory,
  });

  final ProfilePageViewData viewData;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenTargets;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    if (viewData.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          key: ProfilePageKeys.loadingIndicatorKey,
          color: AppTheme.primaryOrange,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primaryOrange,
      child: ListView(
        key: ProfilePageKeys.refreshListKey,
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const SizedBox(height: 20),
          _ProfileHeader(viewData: viewData),
          const SizedBox(height: 24),
          _SessionBanner(message: viewData.sessionBannerMessage),
          const SizedBox(height: 24),
          _AccountModeBanner(
            title: viewData.accountModeTitle,
            subtitle: viewData.accountModeSubtitle,
          ),
          const SizedBox(height: 32),
          _ProfileSection(
            title: 'Your Space',
            children: <Widget>[
              _NavigationTile(
                tileKey: ProfilePageKeys.settingsTileKey,
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'App preferences and local configuration',
                onTap: onOpenSettings,
              ),
              _NavigationTile(
                tileKey: ProfilePageKeys.targetsTileKey,
                icon: Icons.flag_outlined,
                title: 'Targets',
                subtitle: 'Manage your weekly muscle group goals',
                onTap: onOpenTargets,
              ),
              _NavigationTile(
                tileKey: ProfilePageKeys.historyTileKey,
                icon: Icons.history_outlined,
                title: 'History',
                subtitle: 'Review logged workouts and progress',
                onTap: onOpenHistory,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ProfileSection(
            title: 'Account Status',
            children: <Widget>[
              _StatusTile(
                tileKey: ProfilePageKeys.accountStatusTileKey,
                icon: Icons.verified_user_outlined,
                title: viewData.accountModeTitle,
                subtitle: viewData.accountModeSubtitle,
              ),
              _StatusTile(
                tileKey: ProfilePageKeys.cloudMigrationTileKey,
                icon: Icons.cloud_sync_outlined,
                title: 'Cloud migration readiness',
                subtitle: viewData.cloudMigrationSubtitle,
              ),
              _StatusTile(
                tileKey: ProfilePageKeys.lastSyncTileKey,
                icon: Icons.sync_outlined,
                title: 'Last cloud sync',
                subtitle: viewData.lastSyncSubtitle,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ProfileSection(
            key: ProfilePageKeys.deferredSectionKey,
            title: 'Deferred Until Auth / Supabase',
            children: viewData.deferredItems
                .map(
                  (ProfileDeferredItemViewData item) => _StaticInfoTile(
                    icon: _iconForDeferredItem(item.title),
                    title: item.title,
                    subtitle: item.subtitle,
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 24),
          _ProfileSection(
            title: 'About',
            children: viewData.infoTiles
                .map(
                  (ProfileInfoTileViewData item) => _StatusTile(
                    tileKey: ProfilePageKeys.appVersionTileKey,
                    icon: Icons.info_outline,
                    title: item.title,
                    subtitle: item.subtitle,
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  IconData _iconForDeferredItem(String title) {
    switch (title) {
      case 'Edit profile':
        return Icons.badge_outlined;
      case 'Password and sign out':
        return Icons.lock_outline;
      case 'Avatar, handle, privacy, social presence':
        return Icons.public_outlined;
      default:
        return Icons.hourglass_top;
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.viewData,
  });

  final ProfilePageViewData viewData;

  @override
  Widget build(BuildContext context) {
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
          viewData.title,
          key: ProfilePageKeys.titleKey,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          viewData.subtitle,
          key: ProfilePageKeys.subtitleKey,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textMedium,
              ),
        ),
      ],
    );
  }
}

class _SessionBanner extends StatelessWidget {
  const _SessionBanner({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ProfilePageKeys.sessionBannerKey,
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

class _AccountModeBanner extends StatelessWidget {
  const _AccountModeBanner({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ProfilePageKeys.accountModeBannerKey,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryOrange.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.account_circle_outlined,
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    super.key,
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