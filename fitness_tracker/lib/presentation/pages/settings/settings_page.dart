import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/app_settings.dart';
import '../../settings/bloc/app_settings_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppSettingsCubit, AppSettingsState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.isSaving != current.isSaving,
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save settings: ${state.errorMessage}'),
            ),
          );
          context.read<AppSettingsCubit>().clearError();
        }
      },
      builder: (context, state) {
        final settings = state.settings;

        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryOrange,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<AppSettingsCubit>().loadSettings(),
                  color: AppTheme.primaryOrange,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildInfoBanner(context),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorBanner(context, state.errorMessage!),
                      ],
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: 'General',
                        children: [
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: SwitchListTile(
                              value: settings.notificationsEnabled,
                              activeColor: AppTheme.primaryOrange,
                              secondary: const Icon(
                                Icons.notifications_outlined,
                                color: AppTheme.primaryOrange,
                              ),
                              title: const Text('Notifications'),
                              subtitle: const Text(
                                'Workout reminders and local alerts',
                              ),
                              onChanged: state.isSaving
                                  ? null
                                  : (value) async {
                                      final success = await context
                                          .read<AppSettingsCubit>()
                                          .setNotificationsEnabled(value);

                                      if (success && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Settings saved'),
                                          ),
                                        );
                                      }
                                    },
                            ),
                          ),
                          _buildSelectionTile(
                            icon: Icons.calendar_month_outlined,
                            title: 'Week Start Day',
                            subtitle: settings.weekStartDayLabel,
                            onTap: state.isSaving
                                ? null
                                : () => _selectWeekStartDay(context, settings),
                          ),
                          _buildSelectionTile(
                            icon: Icons.straighten_outlined,
                            title: 'Weight Units',
                            subtitle: settings.weightUnitLabel,
                            onTap: state.isSaving
                                ? null
                                : () => _selectWeightUnit(context, settings),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: 'About',
                        children: [
                          _buildReadOnlyTile(
                            icon: Icons.info_outline,
                            title: 'App Version',
                            subtitle: AppInfo.versionLabel,
                          ),
                          _buildReadOnlyTile(
                            icon: Icons.storage_outlined,
                            title: 'Storage Mode',
                            subtitle:
                                'Local device settings now, account sync later',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: 'Deferred Until Auth / Cloud',
                        children: [
                          _buildDeferredTile(
                            icon: Icons.dark_mode_outlined,
                            title: 'Theme',
                            subtitle:
                                'Hold for the wider app-shell theming pass',
                          ),
                          _buildDeferredTile(
                            icon: Icons.backup_outlined,
                            title: 'Backup & Restore',
                            subtitle:
                                'Best added after the Supabase sync path is in place',
                          ),
                          _buildDeferredTile(
                            icon: Icons.description_outlined,
                            title: 'Terms & Privacy',
                            subtitle: 'Needs final hosted documents / URLs',
                          ),
                          _buildDeferredTile(
                            icon: Icons.bug_report_outlined,
                            title: 'Report a Bug',
                            subtitle:
                                'Needs a connected support destination',
                          ),
                        ],
                      ),
                      if (state.isSaving) ...[
                        const SizedBox(height: 24),
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  Future<void> _selectWeekStartDay(
    BuildContext context,
    AppSettings settings,
  ) async {
    final selected = await showModalBottomSheet<WeekStartDay>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBottomSheetOption<WeekStartDay>(
                value: WeekStartDay.monday,
                title: 'Monday',
                selected: settings.weekStartDay == WeekStartDay.monday,
              ),
              _buildBottomSheetOption<WeekStartDay>(
                value: WeekStartDay.sunday,
                title: 'Sunday',
                selected: settings.weekStartDay == WeekStartDay.sunday,
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == settings.weekStartDay) {
      return;
    }

    final success =
        await context.read<AppSettingsCubit>().setWeekStartDay(selected);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
        ),
      );
    }
  }

  Future<void> _selectWeightUnit(
    BuildContext context,
    AppSettings settings,
  ) async {
    final selected = await showModalBottomSheet<WeightUnit>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBottomSheetOption<WeightUnit>(
                value: WeightUnit.kilograms,
                title: 'Kilograms (kg)',
                selected: settings.weightUnit == WeightUnit.kilograms,
              ),
              _buildBottomSheetOption<WeightUnit>(
                value: WeightUnit.pounds,
                title: 'Pounds (lb)',
                selected: settings.weightUnit == WeightUnit.pounds,
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == settings.weightUnit) {
      return;
    }

    final success = await context.read<AppSettingsCubit>().setWeightUnit(
          selected,
        );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
        ),
      );
    }
  }

  Widget _buildBottomSheetOption<T>({
    required T value,
    required String title,
    required bool selected,
  }) {
    return Builder(
      builder: (context) {
        return ListTile(
          title: Text(title),
          trailing: selected
              ? const Icon(
                  Icons.check,
                  color: AppTheme.primaryOrange,
                )
              : null,
          onTap: () => Navigator.of(context).pop(value),
        );
      },
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
            Icons.tune,
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'These settings are stored locally today and are safe to keep when the app moves to Supabase-backed accounts later.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.errorRed.withOpacity(0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.errorRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textLight,
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

  Widget _buildSelectionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryOrange),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textDim,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDeferredTile({
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
        trailing: const Icon(
          Icons.hourglass_top,
          color: AppTheme.textDim,
        ),
      ),
    );
  }
}