import 'package:equatable/equatable.dart';

class SettingsPageViewData extends Equatable {
  const SettingsPageViewData({
    required this.infoMessage,
    required this.generalSectionTitle,
    required this.aboutSectionTitle,
    required this.deferredSectionTitle,
    required this.notificationsTitle,
    required this.notificationsSubtitle,
    required this.notificationsEnabled,
    required this.weekStartTitle,
    required this.weekStartSubtitle,
    required this.weekStartPreview,
    required this.weightUnitTitle,
    required this.weightUnitSubtitle,
    required this.weightUnitPreview,
    required this.appVersionTitle,
    required this.appVersionSubtitle,
    required this.storageModeTitle,
    required this.storageModeSubtitle,
    required this.deferredItems,
    required this.isLoading,
    required this.isSaving,
    required this.errorMessage,
  });

  final String infoMessage;
  final String generalSectionTitle;
  final String aboutSectionTitle;
  final String deferredSectionTitle;
  final String notificationsTitle;
  final String notificationsSubtitle;
  final bool notificationsEnabled;
  final String weekStartTitle;
  final String weekStartSubtitle;
  final String weekStartPreview;
  final String weightUnitTitle;
  final String weightUnitSubtitle;
  final String weightUnitPreview;
  final String appVersionTitle;
  final String appVersionSubtitle;
  final String storageModeTitle;
  final String storageModeSubtitle;
  final List<DeferredSettingsItemViewData> deferredItems;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  @override
  List<Object?> get props => <Object?>[
        infoMessage,
        generalSectionTitle,
        aboutSectionTitle,
        deferredSectionTitle,
        notificationsTitle,
        notificationsSubtitle,
        notificationsEnabled,
        weekStartTitle,
        weekStartSubtitle,
        weekStartPreview,
        weightUnitTitle,
        weightUnitSubtitle,
        weightUnitPreview,
        appVersionTitle,
        appVersionSubtitle,
        storageModeTitle,
        storageModeSubtitle,
        deferredItems,
        isLoading,
        isSaving,
        errorMessage,
      ];
}

class DeferredSettingsItemViewData extends Equatable {
  const DeferredSettingsItemViewData({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  List<Object?> get props => <Object?>[title, subtitle];
}