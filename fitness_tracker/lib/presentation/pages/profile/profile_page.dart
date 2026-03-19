import 'package:flutter/material.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/app_session.dart';
import '../../../domain/repositories/app_session_repository.dart';
import '../../../injection/injection_container.dart' as di;
import '../history/history_page.dart';
import '../../../features/settings/presentation/settings_page.dart';
import '../targets/targets_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final AppSessionRepository _sessionRepository;
  late Future<AppSession> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionRepository = di.sl<AppSessionRepository>();
    _sessionFuture = _loadSession();
  }

  Future<AppSession> _loadSession() async {
    final result = await _sessionRepository.getCurrentSession();
    return result.fold(
      (_) => const AppSession.guest(),
      (session) => session,
    );
  }

  Future<void> _refreshSession() async {
    final nextFuture = _loadSession();

    setState(() {
      _sessionFuture = nextFuture;
    });

    await nextFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSession,
        color: AppTheme.primaryOrange,
        child: FutureBuilder<AppSession>(
          future: _sessionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryOrange,
                ),
              );
            }

            final session = snapshot.data ?? const AppSession.guest();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 20),
                _buildHeader(context, session),
                const SizedBox(height: 24),
                _buildSessionBanner(context, session),
                const SizedBox(height: 32),
                _buildSection(
                  context,
                  title: 'Your Space',
                  children: [
                    _buildNavigationTile(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'App preferences and local configuration',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        );
                      },
                    ),
                    _buildNavigationTile(
                      context,
                      icon: Icons.flag_outlined,
                      title: 'Targets',
                      subtitle: 'Manage your weekly muscle group goals',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TargetsPage(),
                          ),
                        );
                      },
                    ),
                    _buildNavigationTile(
                      context,
                      icon: Icons.history_outlined,
                      title: 'History',
                      subtitle: 'Review logged workouts and progress',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoryPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  title: 'Account Status',
                  children: [
                    _buildStatusTile(
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
                    _buildStatusTile(
                      icon: Icons.cloud_sync_outlined,
                      title: 'Cloud migration readiness',
                      subtitle: session.requiresInitialCloudMigration
                          ? 'This session is marked as needing an initial cloud migration'
                          : 'No initial cloud migration pending',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  title: 'Deferred Until Auth / Supabase',
                  children: const [
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
                _buildSection(
                  context,
                  title: 'About',
                  children: [
                    _buildStatusTile(
                      icon: Icons.info_outline,
                      title: AppInfo.name,
                      subtitle: AppInfo.versionLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppSession session) {
    final displayName = session.user?.displayName?.trim();
    final email = session.user?.email.trim();

    final titleText = session.isAuthenticated
        ? ((displayName != null && displayName.isNotEmpty)
            ? displayName
            : 'Signed-in User')
        : 'Guest';

    final subtitleText = session.isAuthenticated
        ? (email != null && email.isNotEmpty
            ? email
            : 'Authenticated session')
        : 'Profile features will expand after auth is enabled';

    return Column(
      children: [
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitleText,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textMedium,
              ),
        ),
      ],
    );
  }

  Widget _buildSessionBanner(BuildContext context, AppSession session) {
    final message = session.isAuthenticated
        ? 'This page is intentionally thin. The real profile should attach to authenticated server data, not local placeholders.'
        : 'You are currently in guest mode. This page is ready for auth states now, while keeping profile details deferred until Supabase-backed accounts are in place.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

  Widget _buildNavigationTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
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

  Widget _buildStatusTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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