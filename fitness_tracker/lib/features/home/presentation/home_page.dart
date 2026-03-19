import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/time_period.dart';
import '../../../presentation/settings/bloc/app_settings_cubit.dart';
import '../application/home_bloc.dart';
import '../application/muscle_visual_bloc.dart';
import 'mappers/home_view_data_mapper.dart';
import 'models/home_view_data.dart';
import 'widgets/period_selector_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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

                    final TimePeriod selectedPeriod =
                        muscleState is MuscleVisualLoaded
                            ? muscleState.currentPeriod
                            : TimePeriod.week;

                    final bool selectorEnabled =
                        muscleState is! MuscleVisualLoading;

                    return RefreshIndicator(
                      color: AppTheme.primaryOrange,
                      onRefresh: () async {
                        context.read<HomeBloc>().add(
                              const RefreshHomeDataEvent(),
                            );
                        context.read<MuscleVisualBloc>().add(
                              const RefreshVisualsEvent(),
                            );
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: <Widget>[
                          _GreetingSection(viewData: viewData),
                          const SizedBox(height: 24),
                          _NutritionCard(viewData: viewData.nutrition),
                          const SizedBox(height: 24),
                          _ProgressCard(
                            viewData: viewData.progress,
                            selectedPeriodLabel: viewData.period,
                            selectedPeriod: selectedPeriod,
                            selectorEnabled: selectorEnabled,
                            onPeriodChanged: (TimePeriod nextPeriod) {
                              context.read<MuscleVisualBloc>().add(
                                    ChangePeriodEvent(nextPeriod),
                                  );
                            },
                            onRetryVisuals: () {
                              context.read<MuscleVisualBloc>().add(
                                    const RefreshVisualsEvent(),
                                  );
                            },
                          ),
                          const SizedBox(height: 24),
                          if (viewData.showMuscleGroups)
                            _MuscleGroupSection(items: viewData.muscleGroups),
                        ],
                      ),
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

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({
    required this.viewData,
  });

  final HomePageViewData viewData;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          viewData.greeting,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          viewData.weekRangeLabel,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textMedium,
              ),
        ),
      ],
    );
  }
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({
    required this.viewData,
  });

  final HomeNutritionCardViewData viewData;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Today’s Nutrition',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.local_fire_department,
                    color: AppTheme.primaryOrange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Total Calories',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMedium,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        viewData.totalCaloriesLabel,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryOrange,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...viewData.macros.map(
              (HomeMacroProgressViewData item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _MacroRow(item: item),
              ),
            ),
            const SizedBox(height: 8),
            if (!viewData.hasEntries)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Text(
                  'No meals or macro entries logged today yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                ),
              )
            else ...<Widget>[
              Text(
                'Latest Entries',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              ...viewData.recentEntries.map(
                (HomeRecentNutritionEntryViewData entry) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        entry.isMealLog ? Icons.restaurant : Icons.calculate,
                        color: AppTheme.primaryOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              entry.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textMedium),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.item,
  });

  final HomeMacroProgressViewData item;

  @override
  Widget build(BuildContext context) {
    final Color progressColor =
        item.isComplete ? AppTheme.successGreen : AppTheme.primaryOrange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              item.trailingLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: item.hasTarget ? progressColor : AppTheme.textDim,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          item.progressLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMedium,
              ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: item.hasTarget ? item.progressValue : 0,
            minHeight: 8,
            backgroundColor: AppTheme.surfaceDark,
            color: progressColor,
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.viewData,
    required this.selectedPeriodLabel,
    required this.selectedPeriod,
    required this.selectorEnabled,
    required this.onPeriodChanged,
    required this.onRetryVisuals,
  });

  final HomeProgressCardViewData viewData;
  final String selectedPeriodLabel;
  final TimePeriod selectedPeriod;
  final bool selectorEnabled;
  final ValueChanged<TimePeriod> onPeriodChanged;
  final VoidCallback onRetryVisuals;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${AppStrings.progress} • $selectedPeriodLabel',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                PeriodSelectorWidget(
                  selectedPeriod: selectedPeriod,
                  onPeriodChanged: onPeriodChanged,
                  enabled: selectorEnabled,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (viewData.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryOrange,
                  ),
                ),
              )
            else if (viewData.errorMessage != null)
              Column(
                children: <Widget>[
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorRed,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    viewData.errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMedium,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onRetryVisuals,
                    icon: const Icon(Icons.refresh),
                    label: const Text(AppStrings.tryAgain),
                  ),
                ],
              )
            else ...<Widget>[
              _ProgressStatsRow(viewData: viewData),
              const SizedBox(height: 16),
              ...viewData.muscleSummary.map(
                (HomeMuscleSummaryItemViewData item) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.displayName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      Text(
                        '${item.stimulusLabel} • ${item.intensityLabel}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMedium,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressStatsRow extends StatelessWidget {
  const _ProgressStatsRow({
    required this.viewData,
  });

  final HomeProgressCardViewData viewData;

  @override
  Widget build(BuildContext context) {
    final Color targetColor = switch (viewData.targetTone) {
      HomeTone.success => AppTheme.successGreen,
      HomeTone.warning => AppTheme.warningAmber,
      HomeTone.primary => AppTheme.primaryOrange,
      HomeTone.muted => AppTheme.textDim,
    };

    Widget stat({
      required IconData icon,
      required String value,
      required String label,
      required Color color,
    }) {
      return Expanded(
        child: Column(
          children: <Widget>[
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: <Widget>[
          stat(
            icon: Icons.fitness_center,
            value: viewData.totalSetsLabel,
            label: AppStrings.sets,
            color: AppTheme.primaryOrange,
          ),
          Container(width: 1, height: 60, color: AppTheme.borderDark),
          stat(
            icon: Icons.flag_outlined,
            value: viewData.remainingTargetLabel,
            label: AppStrings.target,
            color: targetColor,
          ),
          Container(width: 1, height: 60, color: AppTheme.borderDark),
          stat(
            icon: Icons.auto_awesome,
            value: viewData.trainedMusclesLabel,
            label: AppStrings.muscles,
            color: AppTheme.primaryOrange,
          ),
        ],
      ),
    );
  }
}

class _MuscleGroupSection extends StatelessWidget {
  const _MuscleGroupSection({
    required this.items,
  });

  final List<HomeMuscleGroupProgressViewData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppStrings.muscleGroups,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (HomeMuscleGroupProgressViewData item) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (item.isComplete)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            AppStrings.complete,
                            style: TextStyle(
                              color: AppTheme.successGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Text(
                        item.progressLabel,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textMedium,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        item.percentageLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: item.tone == HomeTone.success
                                  ? AppTheme.successGreen
                                  : AppTheme.primaryOrange,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.progressValue,
                      minHeight: 6,
                      backgroundColor: AppTheme.surfaceDark,
                      color: item.tone == HomeTone.success
                          ? AppTheme.successGreen
                          : AppTheme.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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