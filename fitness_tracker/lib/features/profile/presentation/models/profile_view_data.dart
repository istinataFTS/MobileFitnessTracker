import 'package:equatable/equatable.dart';

class ProfilePageViewData extends Equatable {
  const ProfilePageViewData({
    required this.title,
    required this.subtitle,
    required this.sessionBannerMessage,
    required this.accountModeTitle,
    required this.accountModeSubtitle,
    required this.isLoading,
    required this.errorMessage,
    this.username,
    this.bio,
  });

  final String title;
  final String subtitle;
  final String sessionBannerMessage;
  final String accountModeTitle;
  final String accountModeSubtitle;
  final bool isLoading;
  final String? errorMessage;

  /// Populated only when an authenticated profile has been loaded.
  final String? username;

  /// Populated only when the profile has a bio set.
  final String? bio;

  @override
  List<Object?> get props => <Object?>[
    title,
    subtitle,
    sessionBannerMessage,
    accountModeTitle,
    accountModeSubtitle,
    isLoading,
    errorMessage,
    username,
    bio,
  ];
}
