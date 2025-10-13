import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/themes/app_theme.dart';
import '../../../config/app_config.dart';
import '../targets/targets_page.dart';
import '../settings/settings_page.dart';

/// Simplified Profile page - stats and settings access only
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text(AppStrings.profileTitle),
        automaticallyImplyLeading: false, // No back button - it's a main tab
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(context),
            const SizedBox(height: 32),
            _buildStatsCards(context),
            const SizedBox(height: 32),
            _buildSection(
              context,
              title: AppStrings.workoutManagement,
              children: [
                _buildNavigationTile(
                  context,
                  icon: Icons.flag_outlined,
                  title: AppStrings.manageTargets,
                  subtitle: AppStrings.manageTargetsDesc,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TargetsPage(),
                      ),
                    );
                  },
                ),
                _buildNavigationTile(
                  context,
                  icon: Icons.settings_outlined,
                  title: AppStrings.settings,
                  subtitle: AppStrings.settingsDesc,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: AppStrings.account,
              children: [
                _buildActionTile(
                  context,
                  icon: Icons.person_outline,
                  title: AppStrings.editProfile,
                  onTap: () => _showComingSoon(context),
                ),
                _buildActionTile(
                  context,
                  icon: Icons.lock_outline,
                  title: AppStrings.changePassword,
                  onTap: () => _showComingSoon(context),
                ),
                _buildActionTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: AppStrings.notifications,
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: AppStrings.preferences,
              children: [
                _buildActionTile(
                  context,
                  icon: Icons.dark_mode_outlined,
                  title: AppStrings.theme,
                  subtitle: AppStrings.dark,
                  onTap: () => _showComingSoon(context),
                ),
                _buildActionTile(
                  context,
                  icon: Icons.language_outlined,
                  title: AppStrings.language,
                  subtitle: AppStrings.english,
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: AppStrings.support,
              children: [
                _buildActionTile(
                  context,
                  icon: Icons.help_outline,
                  title: AppStrings.helpSupport,
                  onTap: () => _showComingSoon(context),
                ),
                _buildActionTile(
                  context,
                  icon: Icons.feedback_outlined,
                  title: AppStrings.sendFeedback,
                  onTap: () => _showComingSoon(context),
                ),
                _buildActionTile(
                  context,
                  icon: Icons.info_outline,
                  title: AppStrings.about,
                  subtitle: '${AppStrings.version} ${EnvConfig.appVersion}',
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSignOutButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
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
          EnvConfig.userName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.fitnessEnthusiast,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textMedium,
              ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            label: AppStrings.totalWorkouts,
            value: '24',
            icon: Icons.fitness_center,
            color: AppTheme.primaryOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            label: AppStrings.thisWeek,
            value: '5',
            icon: Icons.calendar_today,
            color: AppTheme.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            label: AppStrings.streak,
            value: '7',
            icon: Icons.local_fire_department,
            color: AppTheme.warningAmber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMedium,
                  height: 1.2,
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
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textDim),
        onTap: onTap,
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textMedium),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textDim),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showComingSoon(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.errorRed,
          side: const BorderSide(color: AppTheme.errorRed),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: const Icon(Icons.logout),
        label: const Text(
          AppStrings.signOut,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.comingSoon),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(EnvConfig.appName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppStrings.version}: ${EnvConfig.appVersion}'),
            const SizedBox(height: 8),
            Text(
              'A personal fitness tracking app to monitor weekly muscle group training goals.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.gotIt),
          ),
        ],
      ),
    );
  }
}