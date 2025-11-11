import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';
import '../../../config/app_config.dart';
import '../exercises/bloc/exercise_bloc.dart';
import 'bloc/home_bloc.dart';


  class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Refresh data when page is shown
    context.read<HomeBloc>().add(LoadHomeDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryOrange,
              ),
            ),
          );
        }

        if (state is HomeError) {
          return Scaffold(
            body: Center(
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
                    'Error loading data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<HomeBloc>().add(LoadHomeDataEvent());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is HomeLoaded) {
          return _buildLoadedState(context, state);
        }

        // Initial state
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryOrange,
            ),
          ),
        );
      },
    );
  }

  /// Build loaded state - now uses ExerciseBloc instead of ExercisesManager
  Widget _buildLoadedState(BuildContext context, HomeLoaded state) {
    // Calculate totals from BLoC state
    final totalWeeklyTarget = state.targets.fold<int>(
      0,
      (sum, target) => sum + target.weeklyGoal,
    );

    final totalWeeklySets = state.weeklySets.length;

    // Use BlocBuilder to get exercises and calculate muscle breakdown
    return BlocBuilder<ExerciseBloc, ExerciseState>(
      builder: (context, exerciseState) {
        // Calculate muscle breakdown using ExerciseBloc
        final muscleBreakdown = _calculateMuscleBreakdown(
          state.weeklySets,
          exerciseState,
        );

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              color: AppTheme.primaryOrange,
              onRefresh: () async {
                context.read<HomeBloc>().add(LoadHomeDataEvent());
                // Wait a moment for the bloc to process
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: _buildContent(
                context,
                state.targets,
                totalWeeklyTarget,
                totalWeeklySets,
                muscleBreakdown,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Calculate muscle breakdown from ExerciseBloc state
  /// This replaces the ExercisesManager approach
  Map<String, int> _calculateMuscleBreakdown(
    List weeklySets,
    ExerciseState exerciseState,
  ) {
    final muscleBreakdown = <String, int>{};

    // Only calculate if exercises are loaded
    if (exerciseState is ExercisesLoaded) {
      final exercises = exerciseState.exercises;

      for (final set in weeklySets) {
        // Find exercise by ID from BLoC state
        try {
          final exercise = exercises.firstWhere(
            (e) => e.id == set.exerciseId,
          );

          // Count sets for each muscle group in the exercise
          for (final muscle in exercise.muscleGroups) {
            muscleBreakdown[muscle] = (muscleBreakdown[muscle] ?? 0) + 1;
          }
        } catch (_) {
          // Exercise not found - skip this set
          // This handles cases where exercise was deleted but sets remain
        }
      }
    }

    return muscleBreakdown;
  }

  Widget _buildContent(
    BuildContext context,
    List targets,
    int totalWeeklyTarget,
    int totalWeeklySets,
    Map<String, int> muscleBreakdown,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        Text(
          'Hello, ${EnvConfig.userName}!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _getWeekRangeString(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textMedium,
              ),
        ),
        const SizedBox(height: 24),

        // Weekly Overview Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                    Text(
                      'Weekly Progress',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatColumn(
                        context,
                        'Sets',
                        totalWeeklySets.toString(),
                        Icons.fitness_center,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.borderDark,
                    ),
                    Expanded(
                      child: _buildStatColumn(
                        context,
                        'Target',
                        totalWeeklyTarget.toString(),
                        Icons.flag,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.borderDark,
                    ),
                    Expanded(
                      child: _buildStatColumn(
                        context,
                        'Muscles',
                        targets.length.toString(),
                        Icons.auto_awesome,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalWeeklyTarget > 0
                        ? (totalWeeklySets / totalWeeklyTarget).clamp(0.0, 1.0)
                        : 0.0,
                    minHeight: 8,
                    backgroundColor: AppTheme.surfaceDark,
                    color: _getProgressColor(totalWeeklySets, totalWeeklyTarget),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Muscle Groups Section
        if (targets.isNotEmpty) ...[
          Text(
            'Muscle Groups',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ...targets.map((target) {
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
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
                                  'Complete',
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
                          '$currentSets / ${target.weeklyGoal} sets',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textMedium,
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          '${(progress * 100).clamp(0, 100).toInt()}%',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
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
          }).toList(),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 64,
                    color: AppTheme.textDim,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Targets Set',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add targets to track your weekly progress',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMedium,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.textDim,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textDim,
              ),
        ),
      ],
    );
  }

  Color _getProgressColor(int current, int target) {
    if (target == 0) return AppTheme.primaryOrange;
    final ratio = current / target;
    if (ratio >= 1.0) return AppTheme.successGreen;
    if (ratio >= 0.7) return AppTheme.primaryOrange;
    return AppTheme.warningAmber;
  }

  String _getWeekRangeString() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final formatter = DateFormat('MMM d');
    return '${formatter.format(weekStart)} - ${formatter.format(weekEnd)}';
  }
}