import 'package:flutter/material.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/repositories/app_settings_repository.dart';
import '../../../injection/injection_container.dart' as di;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final AppSettingsRepository _settingsRepository;

  AppSettings _settings = const AppSettings.defaults();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _settingsRepository = di.sl<AppSettingsRepository>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final result = await _settingsRepository.getSettings();

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _settings = const AppSettings.defaults();
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (settings) {
        setState(() {
          _settings = settings;
          _isLoading = false;
          _errorMessage = null;
        });
      },
    );
  }

  Future<void> _saveSettings(AppSettings nextSettings) async {
    setState(() {
      _settings = nextSettings;
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await _settingsRepository.saveSettings(nextSettings);

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isSaving = false;
          _errorMessage = failure.message;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${failure.message}'),
          ),
        );
      },
      (_) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
          ),
        );
      },
    );
  }

  Future<void> _selectWeekStartDay() async {
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
                selected: _settings.weekStartDay == WeekStartDay.monday,
              ),
              _buildBottomSheetOption<WeekStartDay>(
                value: WeekStartDay.sunday,
                title: 'Sunday',
                selected: _settings.weekStartDay == WeekStartDay.sunday,
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == _settings.weekStartDay) {
      return;
    }

    await _saveSettings(
      _settings.copyWith(weekStartDay: selected),
    );
  }

  Future<void> _selectWeightUnit() async {
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
                selected:
                    _settings.weightUnit == WeightUnit.kilograms,
              ),
              _buildBottomSheetOption<WeightUnit>(
                value: WeightUnit.pounds,
                title: 'Pounds (lb)',
                selected: _settings.weightUnit == WeightUnit.pounds,
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == _settings.weightUnit) {
      return;
    }

    await _saveSettings(
      _settings.copyWith(weightUnit: selected),
    );
  }

  Widget _buildBottomSheetOption<T>({
    required T value,
    required String title,
    required bool selected,
  }) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryOrange,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadSettings,
              color: AppTheme.primaryOrange,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildInfoBanner(context),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorBanner(context, _errorMessage!),
                  ],
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    title: 'General',
                    children: [
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: SwitchListTile(
                          value: _settings.notificationsEnabled,
                          activeColor: AppTheme.primaryOrange,
                          secondary: const Icon(
                            Icons.notifications_outlined,
                            color: AppTheme.primaryOrange,
                          ),
                          title: const Text('Notifications'),
                          subtitle: const Text(
                            'Workout reminders and local alerts',
                          ),
                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  _saveSettings(
                                    _settings.copyWith(
                                      notificationsEnabled: value,
                                    ),
                                  );
                                },
                        ),
                      ),
                      _buildSelectionTile(
                        icon: Icons.calendar_month_outlined,
                        title: 'Week Start Day',
                        subtitle: _settings.weekStartDayLabel,
                        onTap: _isSaving ? null : _selectWeekStartDay,
                      ),
                      _buildSelectionTile(
                        icon: Icons.straighten_outlined,
                        title: 'Weight Units',
                        subtitle: _settings.weightUnitLabel,
                        onTap: _isSaving ? null : _selectWeightUnit,
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
                        subtitle:
                            'Needs final hosted documents / URLs',
                      ),
                      _buildDeferredTile(
                        icon: Icons.bug_report_outlined,
                        title: 'Report a Bug',
                        subtitle:
                            'Needs a connected support destination',
                      ),
                    ],
                  ),
                  if (_isSaving) ...[
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