import 'package:flutter/material.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/themes/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(context),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: AppStrings.settingsGeneral,
              children: [
                _buildUnavailableSettingsTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: AppStrings.settingsNotifications,
                  subtitle: AppStrings.settingsNotificationsDesc,
                  message: AppStrings.unavailableSettingsMessage,
                ),
                _buildUnavailableSettingsTile(
                  context,
                  icon: Icons.calendar_month_outlined,
                  title: AppStrings.settingsWeekStartDay,
                  subtitle: AppStrings.settingsWeekStartDayValue,
                  message: AppStrings.unavailableSettingsMessage,
                ),
                _buildUnavailableSettingsTile(
                  context,
                  icon: Icons.backup_outlined,
                  title: AppStrings.settingsBackupRestore,
                  subtitle: AppStrings.settingsBackupRestoreDesc,
                  message: AppStrings.unavailableSettingsMessage,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: AppStrings.settingsAboutSection,
              children: [
                _buildReadOnlyTile(
                  icon: Icons.info_outlined,
                  title: AppStrings.settingsAppVersion,
                  subtitle: AppInfo.versionLabel,
                ),
                _buildUnavailableSettingsTile(
                  context,
                  icon: Icons.description_outlined,
                  title: AppStrings.settingsTermsPrivacy,
                  subtitle: AppStrings.settingsUnavailableSubtitle,
                  message: AppStrings.unavailableSupportMessage,
                ),
                _buildUnavailableSettingsTile(
                  context,
                  icon: Icons.bug_report_outlined,
                  title: AppStrings.settingsReportBug,
                  subtitle: AppStrings.settingsUnavailableSubtitle,
                  message: AppStrings.unavailableFeedbackMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
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
              AppStrings.unavailableSettingsMessage,
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

  Widget _buildReadOnlyTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryOrange),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _buildUnavailableSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    String? subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryOrange),
        title: Text(title),
        subtitle: Text(subtitle ?? AppStrings.featureUnavailableLabel),
        trailing: const Icon(Icons.info_outline, color: AppTheme.textDim),
        onTap: () => _showUnavailableDialog(
          context,
          title: title,
          message: message,
        ),
      ),
    );
  }

  void _showUnavailableDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
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