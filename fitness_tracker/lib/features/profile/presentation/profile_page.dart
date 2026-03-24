import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/auth_session_service.dart';
import '../../../core/session/session_sync_service.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/repositories/app_session_repository.dart';
import '../../../features/auth/presentation/sign_in_page.dart';
import '../../../features/history/history.dart';
import '../../../features/settings/presentation/settings_page.dart';
import '../../../features/settings/presentation/settings_scope.dart';
import '../../../features/targets/targets.dart';
import '../../../injection/injection_container.dart' as di;
import '../application/profile_cubit.dart';
import 'mappers/profile_view_data_mapper.dart';
import 'models/profile_view_data.dart';
import 'profile_page_keys.dart';
import 'widgets/profile_content.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Key loadingIndicatorKey = ProfilePageKeys.loadingIndicatorKey;
  static const Key refreshListKey = ProfilePageKeys.refreshListKey;
  static const Key titleKey = ProfilePageKeys.titleKey;
  static const Key subtitleKey = ProfilePageKeys.subtitleKey;
  static const Key sessionBannerKey = ProfilePageKeys.sessionBannerKey;
  static const Key settingsTileKey = ProfilePageKeys.settingsTileKey;
  static const Key targetsTileKey = ProfilePageKeys.targetsTileKey;
  static const Key historyTileKey = ProfilePageKeys.historyTileKey;
  static const Key accountStatusTileKey = ProfilePageKeys.accountStatusTileKey;
  static const Key cloudMigrationTileKey =
      ProfilePageKeys.cloudMigrationTileKey;
  static const Key lastSyncTileKey = ProfilePageKeys.lastSyncTileKey;
  static const Key accountModeBannerKey = ProfilePageKeys.accountModeBannerKey;
  static const Key deferredSectionKey = ProfilePageKeys.deferredSectionKey;
  static const Key appVersionTileKey = ProfilePageKeys.appVersionTileKey;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create: (_) => ProfileCubit(
        repository: di.sl<AppSessionRepository>(),
        sessionSyncService: di.sl<SessionSyncService>(),
        authSessionService: di.sl<AuthSessionService>(),
      ),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<ProfileCubit>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (ProfileState previous, ProfileState current) =>
          previous.errorMessage != current.errorMessage,
      listener: (BuildContext context, ProfileState state) {
        final String? errorMessage = state.errorMessage;
        if (errorMessage == null || errorMessage.isEmpty) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
          ),
        );

        context.read<ProfileCubit>().clearError();
      },
      builder: (BuildContext context, ProfileState state) {
        final ProfilePageViewData viewData = ProfileViewDataMapper.map(state);

        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          appBar: AppBar(
            title: const Text('Profile'),
            automaticallyImplyLeading: false,
            actions: [
              if (!state.session.isAuthenticated)
                IconButton(
                  icon: const Icon(Icons.login),
                  tooltip: 'Sign in',
                  onPressed: () async {
                    final didSignIn = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => const SignInPage(),
                      ),
                    );

                    if (!mounted) {
                      return;
                    }

                    if (didSignIn == true) {
                      await context.read<ProfileCubit>().loadProfile();
                    }
                  },
                ),
              if (state.session.isAuthenticated)
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign out',
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          await context.read<ProfileCubit>().signOut();
                        },
                ),
            ],
          ),
          body: ProfileContent(
            viewData: viewData,
            onRefresh: () => context.read<ProfileCubit>().refreshProfile(),
            onOpenSettings: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
            onOpenTargets: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const TargetsPage(),
                ),
              );
            },
            onOpenHistory: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => HistoryPage(
                    settings: SettingsScope.of(context),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}