import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              title: 'General',
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage workout reminders',
                  onTap: () => _showComingSoon(context),
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.calendar_month_outlined,
                  title: 'Week Start Day',
                  subtitle: 'Monday',
                  onTap: () => _showComingSoon(context),
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.backup_outlined,
                  title: 'Backup & Restore',
                  subtitle: 'Export or import your data',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'About',
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.info_outlined,
                  title: 'App Version',
                  subtitle: '1.0.0',
                  onTap: null,
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Terms & Privacy',
                  onTap: () => _showComingSoon(context),
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.bug_report_outlined,
                  title: 'Report a Bug',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
          ],
        ),
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
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryOrange),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, color: AppTheme.textDim)
            : null,
        onTap: onTap,
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
