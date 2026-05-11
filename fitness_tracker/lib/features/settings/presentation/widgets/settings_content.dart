import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/voice_constants.dart';
import '../../../../core/themes/app_theme.dart';
import '../models/settings_page_view_data.dart';
import '../settings_page_keys.dart';

class SettingsContent extends StatelessWidget {
  const SettingsContent({
    super.key,
    required this.viewData,
    required this.onRefresh,
    required this.onNotificationsChanged,
    required this.onWeekStartTapped,
    required this.onWeightUnitTapped,
    this.onSessionLoggingChanged,
    this.onSpeechRateChanged,
  });

  final SettingsPageViewData viewData;
  final Future<void> Function() onRefresh;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onWeekStartTapped;
  final VoidCallback onWeightUnitTapped;
  final ValueChanged<bool>? onSessionLoggingChanged;
  final ValueChanged<double>? onSpeechRateChanged;

  @override
  Widget build(BuildContext context) {
    if (viewData.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          key: SettingsPageKeys.loadingIndicatorKey,
          color: AppTheme.primaryOrange,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primaryOrange,
      child: ListView(
        key: SettingsPageKeys.refreshListKey,
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          _InfoBanner(message: viewData.infoMessage),
          if (viewData.errorMessage != null) ...<Widget>[
            const SizedBox(height: 16),
            _ErrorBanner(message: viewData.errorMessage!),
          ],
          const SizedBox(height: 24),
          _Section(
            title: viewData.generalSectionTitle,
            children: <Widget>[
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: SwitchListTile(
                  key: SettingsPageKeys.notificationsSwitchKey,
                  value: viewData.notificationsEnabled,
                  activeColor: AppTheme.primaryOrange,
                  secondary: const Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.primaryOrange,
                  ),
                  title: Text(viewData.notificationsTitle),
                  subtitle: Text(viewData.notificationsSubtitle),
                  onChanged: viewData.isSaving ? null : onNotificationsChanged,
                ),
              ),
              _SelectionTile(
                tileKey: SettingsPageKeys.weekStartTileKey,
                icon: Icons.calendar_month_outlined,
                title: viewData.weekStartTitle,
                subtitle: viewData.weekStartSubtitle,
                helperText: viewData.weekStartPreview,
                enabled: !viewData.isSaving,
                onTap: onWeekStartTapped,
              ),
              _SelectionTile(
                tileKey: SettingsPageKeys.weightUnitTileKey,
                icon: Icons.straighten_outlined,
                title: viewData.weightUnitTitle,
                subtitle: viewData.weightUnitSubtitle,
                helperText: viewData.weightUnitPreview,
                enabled: !viewData.isSaving,
                onTap: onWeightUnitTapped,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _Section(
            title: viewData.aboutSectionTitle,
            children: <Widget>[
              _ReadOnlyTile(
                icon: Icons.info_outline,
                title: viewData.appVersionTitle,
                subtitle: viewData.appVersionSubtitle,
              ),
              _ReadOnlyTile(
                icon: Icons.storage_outlined,
                title: viewData.storageModeTitle,
                subtitle: viewData.storageModeSubtitle,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _Section(
            title: AppStrings.voiceSectionTitle,
            children: <Widget>[
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: SwitchListTile(
                  value: viewData.voiceSettings.sessionLoggingEnabled,
                  activeColor: AppTheme.primaryOrange,
                  secondary: const Icon(
                    Icons.record_voice_over_outlined,
                    color: AppTheme.primaryOrange,
                  ),
                  title: const Text(AppStrings.voiceSessionLoggingTitle),
                  subtitle: const Text(AppStrings.voiceSessionLoggingSubtitle),
                  onChanged: onSessionLoggingChanged,
                ),
              ),
              _SpeechRateTile(
                speechRate: viewData.voiceSettings.ttsSpeechRate,
                preview: viewData.voiceSettings.ttsSpeechRatePreview,
                onChanged: onSpeechRateChanged,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _Section(
            title: viewData.deferredSectionTitle,
            children: viewData.deferredItems
                .map(
                  (DeferredSettingsItemViewData item) => _DeferredTile(
                    icon: _iconForDeferredTitle(item.title),
                    title: item.title,
                    subtitle: item.subtitle,
                  ),
                )
                .toList(growable: false),
          ),
          if (viewData.isSaving) ...<Widget>[
            const SizedBox(height: 24),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(
                  key: SettingsPageKeys.savingIndicatorKey,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForDeferredTitle(String title) {
    switch (title) {
      case 'Theme':
        return Icons.dark_mode_outlined;
      case 'Backup & Restore':
        return Icons.backup_outlined;
      case 'Terms & Privacy':
        return Icons.description_outlined;
      case 'Report a Bug':
        return Icons.bug_report_outlined;
      default:
        return Icons.hourglass_top;
    }
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
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
        children: <Widget>[
          const Icon(
            Icons.tune,
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: SettingsPageKeys.errorBannerKey,
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
        children: <Widget>[
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
}

class _Section extends StatelessWidget {
  const _Section({
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

class _ReadOnlyTile extends StatelessWidget {
  const _ReadOnlyTile({
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
        leading: Icon(icon, color: AppTheme.primaryOrange),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.helperText,
    required this.enabled,
    required this.onTap,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final String helperText;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: tileKey,
        enabled: enabled,
        leading: Icon(
          icon,
          color: enabled ? AppTheme.primaryOrange : AppTheme.textDim,
        ),
        title: Text(title),
        subtitle: Text('$subtitle\n$helperText'),
        isThreeLine: true,
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textDim,
        ),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}

class _SpeechRateTile extends StatelessWidget {
  const _SpeechRateTile({
    required this.speechRate,
    required this.preview,
    required this.onChanged,
  });

  final double speechRate;
  final String preview;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.speed_outlined,
                  color: enabled ? AppTheme.primaryOrange : AppTheme.textDim,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(AppStrings.voiceTtsSpeechRateTitle),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.voiceTtsSpeechRateSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMedium,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  preview,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            Slider(
              key: const Key('voice_tts_speech_rate_slider'),
              value: speechRate.clamp(
                VoiceConstants.minTtsSpeechRate,
                VoiceConstants.maxTtsSpeechRate,
              ),
              min: VoiceConstants.minTtsSpeechRate,
              max: VoiceConstants.maxTtsSpeechRate,
              // 15 discrete steps across the 0.5–2.0 range — granular
              // enough for taste, coarse enough that consecutive
              // values are audibly different.
              divisions: 15,
              activeColor: AppTheme.primaryOrange,
              label: preview,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeferredTile extends StatelessWidget {
  const _DeferredTile({
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
        trailing: const Icon(
          Icons.hourglass_top,
          color: AppTheme.textDim,
        ),
      ),
    );
  }
}