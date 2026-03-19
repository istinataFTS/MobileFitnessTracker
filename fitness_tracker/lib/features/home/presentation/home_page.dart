import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/themes/app_theme.dart';
import '../../settings/application/app_settings_cubit.dart';
import '../application/home_bloc.dart';
import '../application/muscle_visual_bloc.dart';
import 'home_page_keys.dart';
import 'mappers/home_view_data_mapper.dart';
import 'models/home_view_data.dart';
import 'widgets/home_content.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Key pageLoadingIndicatorKey =
      HomePageKeys.pageLoadingIndicatorKey;
  static const Key refreshListKey = HomePageKeys.refreshListKey;
  static const Key progressCardKey = HomePageKeys.progressCardKey;
  static const Key progressLoadingIndicatorKey =
      HomePageKeys.progressLoadingIndicatorKey;
  static const Key progressRetryButtonKey =
      HomePageKeys.progressRetryButtonKey;
  static const Key homeRetryButtonKey = HomePageKeys.homeRetryButtonKey;
  static const Key nutritionEmptyStateKey =
      HomePageKeys.nutritionEmptyStateKey;
  static const Key latestEntriesSectionKey =
      HomePageKeys.latestEntriesSectionKey;
  static const Key muscleGroupsSectionKey =
      HomePageKeys.muscleGroupsSectionKey;
  static const Key totalSetsValueKey = HomePageKeys.totalSetsValueKey;
  static const Key targetValueKey = HomePageKeys.targetValueKey;
  static const Key trainedMusclesValueKey =
      HomePageKeys.trainedMusclesValueKey;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (BuildContext context, AppSettingsState settingsState) {
        return Scaffold(
          body: SafeArea(
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (BuildContext context, HomeState homeState) {
                if (homeState is HomeLoading || homeState is HomeInitial) {
                  return const Center(
                    child: CircularProgressIndicator(
                      key: HomePageKeys.pageLoadingIndicatorKey,
                      color: AppTheme.primaryOrange,
                    ),
                  );
                }

                if (homeState is HomeError) {
                  return _HomeErrorState(
                    message: homeState.message,
                    onRetry: () {
                      context.read<HomeBloc>().add(const LoadHomeDataEvent());
                    },
                  );
                }

                final HomeLoaded loadedState = homeState as HomeLoaded;

                return BlocBuilder<MuscleVisualBloc, MuscleVisualState>(
                  builder: (
                    BuildContext context,
                    MuscleVisualState muscleState,
                  ) {
                    final HomePageViewData viewData = HomeViewDataMapper.map(
                      homeState: loadedState,
                      muscleVisualState: muscleState,
                      settings: settingsState.settings,
                    );

                    return HomeContent(
                      viewData: viewData,
                      onRefresh: () async {
                        context.read<HomeBloc>().add(
                              const RefreshHomeDataEvent(),
                            );
                        context.read<MuscleVisualBloc>().add(
                              const RefreshVisualsEvent(),
                            );
                      },
                      onPeriodChanged: (period) {
                        context.read<MuscleVisualBloc>().add(
                              ChangePeriodEvent(period),
                            );
                      },
                      onRetryVisuals: () {
                        context.read<MuscleVisualBloc>().add(
                              const RefreshVisualsEvent(),
                            );
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.error,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: HomePageKeys.homeRetryButtonKey,
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}