import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/exercises_manager.dart';
import '../../../config/app_config.dart';
import 'package:intl/intl.dart';
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
    // Always use BLoC with database
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

  Widget _buildLoadedState(BuildContext context, HomeLoaded state) {
    // Calculate totals from BLoC state
    final totalWeeklyTarget = state.targets.fold<int>(
      0,
      (sum, target) => sum + target.weeklyGoal,
    );
    
    // Calculate weekly sets per muscle using exercise information
    final exercisesManager = ExercisesManager();
    final muscleBreakdown = <String, int>{};
    
    for (final set in state.weeklySets) {
      final exercise = exercisesManager.getExerciseById(set.exerciseId);
      if (exercise != null) {
        for (final muscle in exercise.muscleGroups) {
          muscleBreakdown[muscle] = (muscleBreakdown[muscle] ?? 0) + 1;
        }
      }
    }
    
    final totalWeeklySets = state.weeklySets.length;
    
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
          AppConfig.greeting,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Progress',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getProgressColor(
                          totalWeeklySets,
                          totalWeeklyTarget,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getProgressPercentage(
                          totalWeeklySets,
                          totalWeeklyTarget,
                        ),
                        style: TextStyle(
                          color: _getProgressColor(
                            totalWeeklySets,
                            totalWeeklyTarget,
                          ),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
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
            return _buildMuscleGroupCard(
              context,
              target.muscleGroup,
              currentSets,
              target.weeklyGoal,
            );
          }).toList(),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(
                    Icons.target,
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
                    'Add muscle group targets to track your progress',
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
        Icon(icon, color: AppTheme.primaryOrange, size: 20),
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
                color: AppTheme.textMedium,
              ),
        ),
      ],
    );
  }

  Widget _buildMuscleGroupCard(
    BuildContext context,
    String muscleGroup,
    int currentSets,
    int targetSets,
  ) {
    final progress = targetSets > 0 ? currentSets / targetSets : 0.0;
    final percentage = (progress * 100).clamp(0, 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  MuscleGroups.getDisplayName(muscleGroup),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '$currentSets / $targetSets',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: AppTheme.surfaceDark,
                      color: _getProgressColor(currentSets, targetSets),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getProgressColor(currentSets, targetSets),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekRangeString() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final startFormat = DateFormat('MMM d');
    final endFormat = DateFormat('MMM d, y');

    return '${startFormat.format(weekStart)} - ${endFormat.format(weekEnd)}';
  }

  Color _getProgressColor(int current, int target) {
    if (target == 0) return AppTheme.textDim;
    final percentage = (current / target) * 100;

    if (percentage >= 100) return AppTheme.successGreen;
    if (percentage >= 75) return AppTheme.primaryOrange;
    if (percentage >= 50) return AppTheme.accentYellow;
    return AppTheme.textDim;
  }

  String _getProgressPercentage(int current, int target) {
    if (target == 0) return '0%';
    final percentage = ((current / target) * 100).clamp(0, 100).toInt();
    return '$percentage%';
  }
}
