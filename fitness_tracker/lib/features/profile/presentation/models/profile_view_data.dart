import 'package:equatable/equatable.dart';

class ProfilePageViewData extends Equatable {
  const ProfilePageViewData({
    required this.title,
    required this.subtitle,
    required this.sessionBannerMessage,
    required this.accountModeTitle,
    required this.accountModeSubtitle,
    required this.cloudMigrationSubtitle,
    required this.lastSyncSubtitle,
    required this.infoTiles,
    required this.deferredItems,
    required this.isLoading,
    required this.errorMessage,
  });

  final String title;
  final String subtitle;
  final String sessionBannerMessage;
  final String accountModeTitle;
  final String accountModeSubtitle;
  final String cloudMigrationSubtitle;
  final String lastSyncSubtitle;
  final List<ProfileInfoTileViewData> infoTiles;
  final List<ProfileDeferredItemViewData> deferredItems;
  final bool isLoading;
  final String? errorMessage;

  @override
  List<Object?> get props => <Object?>[
        title,
        subtitle,
        sessionBannerMessage,
        accountModeTitle,
        accountModeSubtitle,
        cloudMigrationSubtitle,
        lastSyncSubtitle,
        infoTiles,
        deferredItems,
        isLoading,
        errorMessage,
      ];
}

class ProfileInfoTileViewData extends Equatable {
  const ProfileInfoTileViewData({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  List<Object?> get props => <Object?>[title, subtitle];
}

class ProfileDeferredItemViewData extends Equatable {
  const ProfileDeferredItemViewData({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  List<Object?> get props => <Object?>[title, subtitle];
}