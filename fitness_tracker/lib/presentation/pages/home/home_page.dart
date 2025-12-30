import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../config/app_config.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/time_period.dart';
import '../exercises/bloc/exercise_bloc.dart';
import 'bloc/home_bloc.dart';
import 'bloc/muscle_visual_bloc.dart';
import 'widgets/body_view_toggle_widget.dart';
import 'widgets/muscle_body_diagram_widget.dart';
import 'widgets/period_selector_widget.dart';
import 'widgets/progress_stats_widget.dart';

/// Home page with integrated muscle visualization system
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Local state for view toggle
  bool _isFrontView = true;

  @override
  void initState() {
    super.initState();
    // Load home data on page init
    context.read<HomeBloc>().add(LoadHomeDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, homeState) {
            return _buildHomeContent(context, homeState);
          },
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, HomeState homeState) {
    // Handle loading state
    if (homeState is HomeLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryOrange,
        ),
      );
    }

    // Handle error state
    if (homeState is HomeError) {
      return _buildErrorState(context, homeState.message);
    }

    // Handle loaded state
    if (homeState is HomeLoaded) {
      return _buildLoadedContent(context, homeState);
    }

    // Initial state - show loading
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.primaryOrange,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              onPressed: () {
                context.read<HomeBloc>().add(LoadHomeDataEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, HomeLoaded homeState) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<HomeBloc>().add(RefreshHomeDataEvent());
        context.read<MuscleVisualBloc>().add(const RefreshVisualsEvent());
      },
      color: AppTheme.primaryOrange,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Greeting section
          _buildGreetingSection(context),
          const SizedBox(height: 24),

          // Muscle visualization card
          _buildMuscleVisualizationCard(context, homeState),
          const SizedBox(height: 24),

          // Optional: Muscle groups breakdown
          if (homeState.targets.isNotEmpty) ...[
            _buildMuscleGroupsSection(context, homeState),
          ],
        ],
      ),
    );
  }

  /// Build greeting section with user name and date
  Widget _buildGreetingSection(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final dateFormatter = DateFormat('MMM d');
    final weekRange =
        '${dateFormatter.format(weekStart)} - ${dateFormatter.format(weekEnd)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppStrings.hello}, ${EnvConfig.userName}!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          weekRange,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textMedium,
              ),
        ),
      ],
    );
  }

  /// Build comprehensive muscle visualization card
  Widget _buildMuscleVisualizationCard(
    BuildContext context,
    HomeLoaded homeState,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with period selector
            _buildCardHeader(context),
            const SizedBox(height: 20),

            // Muscle visualization with BLoC
            BlocBuilder<MuscleVisualBloc, MuscleVisualState>(
              builder: (context, muscleState) {
                return _buildVisualizationContent(
                  context,
                  homeState,
                  muscleState,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build card header with title and period selector
  Widget _buildCardHeader(BuildContext context) {
    return Row(
      children: [
        // Icon and title
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.analytics,
            color: AppTheme.primaryOrange,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppStringsPhase7.progress,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        // Period selector
        BlocBuilder<MuscleVisualBloc, MuscleVisualState>(
          builder: (context, state) {
            final currentPeriod = state is MuscleVisualLoaded
                ? state.currentPeriod
                : TimePeriod.week;

            return PeriodSelectorWidget(
              selectedPeriod: currentPeriod,
              onPeriodChanged: (newPeriod) {
                context.read<MuscleVisualBloc>().add(
                      ChangePeriodEvent(newPeriod),
                    );
              },
              enabled: state is! MuscleVisualLoading,
            );
          },
        ),
      ],
    );
  }

  /// Build visualization content based on muscle visual state
  Widget _buildVisualizationContent(
    BuildContext context,
    HomeLoaded homeState,
    MuscleVisualState muscleState,
  ) {
    // Handle loading state
    if (muscleState is MuscleVisualLoading) {
      return _buildLoadingVisualization(context);
    }

    // Handle error state
    if (muscleState is MuscleVisualError) {
      return _buildErrorVisualization(context, muscleState.message);
    }

    // Handle loaded state
    if (muscleState is MuscleVisualLoaded) {
      return _buildLoadedVisualization(
        context,
        homeState,
        muscleState,
      );
    }

    // Initial state - show loading
    return _buildLoadingVisualization(context);
  }

  /// Build loading visualization placeholder
  Widget _buildLoadingVisualization(BuildContext context) {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(height: 16),
          Text(
            AppStringsPhase7.loadingVisualization,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textDim,
                ),
          ),
        ],
      ),
    );
  }

  /// Build error visualization state
  Widget _buildErrorVisualization(BuildContext context, String message) {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppTheme.errorRed,
          ),
          const SizedBox(height: 16),
          Text(
            AppStringsPhase7.errorLoadingData,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMedium,
                ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              context.read<MuscleVisualBloc>().add(const RefreshVisualsEvent());
            },
            icon: const Icon(Icons.refresh),
            label: Text(AppStringsPhase7.tryAgain),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }

  /// Build loaded visualization with body diagram and stats
  Widget _buildLoadedVisualization(
    BuildContext context,
    HomeLoaded homeState,
    MuscleVisualLoaded muscleState,
  ) {
    // Calculate stats for current period
    final stats = _calculatePeriodStats(
      homeState,
      muscleState,
    );

    return Column(
      children: [
        // Body diagram
        RepaintBoundary(
          child: MuscleBodyDiagramWidget(
            muscleData: muscleState.muscleData,
            isFrontView: _isFrontView,
            isLoading: false,
          ),
        ),
        const SizedBox(height: 16),

        // View toggle
        BodyViewToggleWidget(
          isFrontView: _isFrontView,
          onViewChanged: (isFront) {
            setState(() {
              _isFrontView = isFront;
            });
          },
          enabled: true,
        ),
        const SizedBox(height: 20),

        // Progress stats
        ProgressStatsWidget(
          totalSets: stats['totalSets'] as int,
          remainingTarget: stats['remainingTarget'] as int,
          trainedMuscles: stats['trainedMuscles'] as int,
          hasTarget: homeState.stats.hasTargets,
        ),
      ],
    );
  }

  /// Calculate stats for the current period
  /// 
  /// Adapts stats display based on selected time period
  Map<String, dynamic> _calculatePeriodStats(
    HomeLoaded homeState,
    MuscleVisualLoaded muscleState,
  ) {
    // Get trained muscle count from visual data
    final trainedMuscles = muscleState.trainedMuscleCount;

    // For week period, use HomeBloc stats
    if (muscleState.currentPeriod == TimePeriod.week) {
      return {
        'totalSets': homeState.stats.totalWeeklySets,
        'remainingTarget': homeState.stats.remainingTarget,
        'trainedMuscles': trainedMuscles,
      };
    }

    // For other periods, show total sets but no target
    // (targets are weekly-specific)
    return {
      'totalSets': homeState.stats.totalWeeklySets, // TODO: Calculate for period
      'remainingTarget': 0, // No target for non-week periods
      'trainedMuscles': trainedMuscles,
    };
  }

  /// Build muscle groups breakdown section
  Widget _buildMuscleGroupsSection(
    BuildContext context,
    HomeLoaded homeState,
  ) {
    // Calculate muscle breakdown from weekly sets
    final muscleBreakdown = _calculateMuscleBreakdown(homeState.weeklySets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.muscleGroups,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...homeState.targets.map((target) {
          final currentSets = muscleBreakdown[target.muscleGroup] ?? 0;
          final progress = currentSets / target.weeklyGoal;
          final isComplete = currentSets >= target.weeklyGoal;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          MuscleGroups.getDisplayName(target.muscleGroup),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      if (isComplete)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: AppTheme.successGreen,
                              ),
                              SizedBox(width: 4),
                              Text(
                                AppStrings.complete,
                                style: TextStyle(
                                  color: AppTheme.successGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '$currentSets / ${target.weeklyGoal} ${AppStrings.sets}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textMedium,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '${(progress * 100).clamp(0, 100).toInt()}%',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isComplete
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
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppTheme.surfaceDark,
                      color: isComplete
                          ? AppTheme.successGreen
                          : AppTheme.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Calculate muscle breakdown from weekly sets
  /// 
  /// Maps each set to its muscle groups and counts sets per muscle
  /// Requires ExercisesLoaded state to function properly
  Map<String, int> _calculateMuscleBreakdown(List weeklySets) {
    final Map<String, int> muscleBreakdown = {};

    // Get exercise state from context
    final exerciseState = context.read<ExerciseBloc>().state;

    // Only calculate if exercises are loaded
    if (exerciseState is! ExercisesLoaded) {
      return muscleBreakdown;
    }

    final exercises = (exerciseState as ExercisesLoaded).exercises;

    for (final set in weeklySets) {
      // Look up exercise to get muscle groups
      try {
        final exercise = exercises.firstWhere(
          (e) => e.id == set.exerciseId,
        );

        for (final muscleGroup in exercise.muscleGroups) {
          muscleBreakdown[muscleGroup] =
              (muscleBreakdown[muscleGroup] ?? 0) + 1;
        }
      } catch (_) {
        // Exercise not found - skip this set
        continue;
      }
    }

    return muscleBreakdown;
  }
}