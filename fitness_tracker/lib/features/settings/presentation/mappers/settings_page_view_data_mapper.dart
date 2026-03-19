import '../../../../core/constants/app_info.dart';
import '../../../../core/utils/week_range_label_formatter.dart';
import '../../../../core/utils/weight_unit_utils.dart';
import '../../../settings/application/app_settings_cubit.dart';
import '../models/settings_page_view_data.dart';

class SettingsPageViewDataMapper {
  const SettingsPageViewDataMapper._();

  static SettingsPageViewData map(AppSettingsState state) {
    final settings = state.settings;
    final String sampleWeekRange = WeekRangeLabelFormatter.formatForDate(
      DateTime(2026, 3, 19),
      weekStartDay: settings.weekStartDay,
    );
    final String sampleWeight = WeightUnitUtils.formatForDisplay(
      82.5,
      settings.weightUnit,
    );

    return SettingsPageViewData(
      infoMessage:
          'These settings are stored locally today and are safe to keep when the app moves to Supabase-backed accounts later.',
      generalSectionTitle: 'General',
      aboutSectionTitle: 'About',
      deferredSectionTitle: 'Deferred Until Auth / Cloud',
      notificationsTitle: 'Notifications',
      notificationsSubtitle: 'Workout reminders and local alerts',
      notificationsEnabled: settings.notificationsEnabled,
      weekStartTitle: 'Week Start Day',
      weekStartSubtitle: settings.weekStartDayLabel,
      weekStartPreview: 'Week preview: $sampleWeekRange',
      weightUnitTitle: 'Weight Units',
      weightUnitSubtitle: settings.weightUnitLabel,
      weightUnitPreview: 'Display preview: $sampleWeight',
      appVersionTitle: 'App Version',
      appVersionSubtitle: AppInfo.versionLabel,
      storageModeTitle: 'Storage Mode',
      storageModeSubtitle: 'Local device settings now, account sync later',
      deferredItems: const <DeferredSettingsItemViewData>[
        DeferredSettingsItemViewData(
          title: 'Theme',
          subtitle: 'Hold for the wider app-shell theming pass',
        ),
        DeferredSettingsItemViewData(
          title: 'Backup & Restore',
          subtitle: 'Best added after the Supabase sync path is in place',
        ),
        DeferredSettingsItemViewData(
          title: 'Terms & Privacy',
          subtitle: 'Needs final hosted documents / URLs',
        ),
        DeferredSettingsItemViewData(
          title: 'Report a Bug',
          subtitle: 'Needs a connected support destination',
        ),
      ],
      isLoading: state.isLoading && !state.hasLoaded,
      isSaving: state.isSaving,
      errorMessage: state.errorMessage,
    );
  }
}