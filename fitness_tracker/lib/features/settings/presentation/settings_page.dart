import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/app_settings.dart';
import '../application/app_settings_cubit.dart';
import '../domain/settings_display_formatter.dart';
import 'mappers/settings_page_view_data_mapper.dart';
import 'models/settings_page_view_data.dart';
import 'settings_page_keys.dart';
import 'widgets/settings_content.dart';
import 'widgets/settings_option_sheet.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const Key loadingIndicatorKey = SettingsPageKeys.loadingIndicatorKey;
  static const Key refreshListKey = SettingsPageKeys.refreshListKey;
  static const Key notificationsSwitchKey =
      SettingsPageKeys.notificationsSwitchKey;
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
            content: Text(
              SettingsDisplayFormatter.saveErrorMessage(errorMessage),
            ),
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
                : () => _selectWeekStartDay(context, viewData, state.settings),
            onWeightUnitTapped: state.isSaving
                ? () {}
                : () => _selectWeightUnit(context, viewData, state.settings),
          ),
        );
      },
    );
  }

  Future<void> _selectWeekStartDay(
    BuildContext context,
    SettingsPageViewData viewData,
    AppSettings settings,
  ) async {
    final WeekStartDay? selected = await showModalBottomSheet<WeekStartDay>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      builder: (BuildContext context) {
        return SettingsOptionSheet<WeekStartDay>(
          options: viewData.weekStartOptions
              .map(
                (
                  SettingsSelectionOptionViewData<WeekStartDay> option,
                ) =>
                    SettingsOption<WeekStartDay>(
                  value: option.value,
                  title: option.title,
                  selected: option.selected,
                ),
              )
              .toList(growable: false),
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
    SettingsPageViewData viewData,
    AppSettings settings,
  ) async {
    final WeightUnit? selected = await showModalBottomSheet<WeightUnit>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      builder: (BuildContext context) {
        return SettingsOptionSheet<WeightUnit>(
          options: viewData.weightUnitOptions
              .map(
                (
                  SettingsSelectionOptionViewData<WeightUnit> option,
                ) =>
                    SettingsOption<WeightUnit>(
                  value: option.value,
                  title: option.title,
                  selected: option.selected,
                ),
              )
              .toList(growable: false),
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
        content: Text(SettingsDisplayFormatter.saveSuccessMessage),
      ),
    );
  }
}