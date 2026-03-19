import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/app_settings.dart';
import '../application/app_settings_cubit.dart';
import 'mappers/settings_page_view_data_mapper.dart';
import 'models/settings_page_view_data.dart';
import 'settings_page_keys.dart';
import 'widgets/settings_content.dart';
import 'widgets/settings_option_sheet.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const Key loadingIndicatorKey = SettingsPageKeys.loadingIndicatorKey;
  static const Key refreshListKey = SettingsPageKeys.refreshListKey;
  static const Key notificationsSwitchKey = SettingsPageKeys.notificationsSwitchKey;
  static const Key weekStartTileKey = SettingsPageKeys.weekStartTileKey;
  static const Key weightUnitTileKey = SettingsPageKeys.weightUnitTileKey;
  static const Key savingIndicatorKey = SettingsPageKeys.savingIndicatorKey;
  static const Key errorBannerKey = SettingsPageKeys.errorBannerKey;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<AppSettingsCubit>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppSettingsCubit, AppSettingsState>(
      listenWhen: (AppSettingsState previous, AppSettingsState current) =>
          previous.errorMessage != current.errorMessage,
      listener: (BuildContext context, AppSettingsState state) {
        final String? errorMessage = state.errorMessage;
        if (errorMessage == null || errorMessage.isEmpty) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $errorMessage'),
          ),
        );
        context.read<AppSettingsCubit>().clearError();
      },
      builder: (BuildContext context, AppSettingsState state) {
        final SettingsPageViewData viewData =
            SettingsPageViewDataMapper.map(state);

        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: SettingsContent(
            viewData: viewData,
            onRefresh: () => context.read<AppSettingsCubit>().refreshSettings(),
            onNotificationsChanged: (bool value) async {
              await _saveWithFeedback(
                context,
                operation: () {
                  return context
                      .read<AppSettingsCubit>()
                      .setNotificationsEnabled(value);
                },
              );
            },
            onWeekStartTapped: state.isSaving
                ? () {}
                : () => _selectWeekStartDay(context, state.settings),
            onWeightUnitTapped: state.isSaving
                ? () {}
                : () => _selectWeightUnit(context, state.settings),
          ),
        );
      },
    );
  }

  Future<void> _selectWeekStartDay(
    BuildContext context,
    AppSettings settings,
  ) async {
    final WeekStartDay? selected = await showModalBottomSheet<WeekStartDay>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      builder: (BuildContext context) {
        return SettingsOptionSheet<WeekStartDay>(
          options: <SettingsOption<WeekStartDay>>[
            SettingsOption<WeekStartDay>(
              value: WeekStartDay.monday,
              title: 'Monday',
              selected: settings.weekStartDay == WeekStartDay.monday,
            ),
            SettingsOption<WeekStartDay>(
              value: WeekStartDay.sunday,
              title: 'Sunday',
              selected: settings.weekStartDay == WeekStartDay.sunday,
            ),
          ],
        );
      },
    );

    if (selected == null || selected == settings.weekStartDay) {
      return;
    }

    await _saveWithFeedback(
      context,
      operation: () {
        return context.read<AppSettingsCubit>().setWeekStartDay(selected);
      },
    );
  }

  Future<void> _selectWeightUnit(
    BuildContext context,
    AppSettings settings,
  ) async {
    final WeightUnit? selected = await showModalBottomSheet<WeightUnit>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      builder: (BuildContext context) {
        return SettingsOptionSheet<WeightUnit>(
          options: <SettingsOption<WeightUnit>>[
            SettingsOption<WeightUnit>(
              value: WeightUnit.kilograms,
              title: 'Kilograms (kg)',
              selected: settings.weightUnit == WeightUnit.kilograms,
            ),
            SettingsOption<WeightUnit>(
              value: WeightUnit.pounds,
              title: 'Pounds (lb)',
              selected: settings.weightUnit == WeightUnit.pounds,
            ),
          ],
        );
      },
    );

    if (selected == null || selected == settings.weightUnit) {
      return;
    }

    await _saveWithFeedback(
      context,
      operation: () {
        return context.read<AppSettingsCubit>().setWeightUnit(selected);
      },
    );
  }

  Future<void> _saveWithFeedback(
    BuildContext context, {
    required Future<bool> Function() operation,
  }) async {
    final bool success = await operation();

    if (!success || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
      ),
    );
  }
}