import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/targets_manager.dart';
import '../../../core/utils/workout_sets_manager.dart';
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
    if (!kIsWeb) {
      context.read<HomeBloc>().add(LoadHomeDataEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Web: Use in-memory managers
    if (kIsWeb) {
      return _buildWebVersion(context);
    }

    // Mobile: Use BLoC with database
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

  Widget _buildWebVersion(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        TargetsManager(),
        WorkoutSetsManager(),
      ]),
      builder: (context, child) {
        final targetsManager = TargetsManager();
        final setsManager = WorkoutSetsManager();
        
        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              color: AppTheme.primaryOrange,
              onRefresh: () async {
                // On web, just a small delay for UX
                await Future.delayed(const Duration(seconds: 1));
              },
              child: _buildContent(
                context,
                targetsManager.targets,
                targetsManager.totalWeeklyTarget,
                setsManager.totalWeeklySets,
                setsManager.getWeeklyMuscleBreakdown(),
              ),
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

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryOrange,
          onRefresh: () async {
            context.read<HomeBloc>().add(LoadHomeDataEvent());
          },
          child: _buildContent(
            context,
            state.targets,
            totalWeeklyTarget,
            state.weeklySets.length,
            muscleBreakdown,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<dynamic> targets,
    int totalWeeklyTarget,
    int totalWeeklySets,
    Map<String, int> muscleBreakdown,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTodaySection(context),
                    const SizedBox(height: 24),
                    _buildWeekSummaryCard(
                      context,
                      totalWeeklyTarget,
                      totalWeeklySets,
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(context, 'Target Progress'),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: _buildTargetsList(context, targets, muscleBreakdown),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderDark, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryOrange,
                  AppTheme.primaryOrange.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  EnvConfig.userName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () {
                context.read<HomeBloc>().add(LoadHomeDataEvent());
              },
              tooltip: 'Refresh data',
            ),
        ],
      ),
    );
  }

  Widget _buildTodaySection(BuildContext context) {
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          today,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textMedium,
              ),
        ),
      ],
    );
  }

  Widget _buildWeekSummaryCard(
    BuildContext context,
    int goalSets,
    int totalSets,
  ) {
    if (goalSets == 0) {
      return Card(
        child: InkWell(
          onTap: () {
            // Navigate to targets tab
            final scaffold = Scaffold.of(context);
            if (scaffold.hasDrawer) {
              scaffold.openDrawer();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 48,
                  color: AppTheme.textDim,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Targets Set',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add targets to track your weekly progress',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap to add targets →',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryOrange,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final progress = totalSets / goalSets;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceDark,
            AppTheme.surfaceDark.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: totalSets),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  return Text(
                    '$value',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryOrange,
                        ),
                  );
                },
              ),
              Text(
                ' / $goalSets',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textMedium,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'sets completed',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 12,
                  backgroundColor: AppTheme.borderDark,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(value),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% Complete',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                '${(goalSets - totalSets).clamp(0, goalSets)} sets remaining',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildTargetsList(
    BuildContext context,
    List<dynamic> targets,
    Map<String, int> muscleBreakdown,
  ) {
    if (targets.isEmpty) {
      return SliverToBoxAdapter(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Add targets to see your progress here',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textMedium,
                    ),
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final target = targets[index];
          final completed = muscleBreakdown[target.muscleGroup] ?? 0;
          return _buildTargetCard(
            context,
            target.muscleGroup,
            completed,
            target.weeklyGoal,
          );
        },
        childCount: targets.length,
      ),
    );
  }

  Widget _buildTargetCard(
    BuildContext context,
    String muscleGroup,
    int completed,
    int goal,
  ) {
    final progress = completed / goal;
    final remaining = goal - completed;
    final displayName = MuscleGroups.getDisplayName(muscleGroup);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: progress >= 1.0
                      ? AppTheme.successGreen.withOpacity(0.3)
                      : AppTheme.borderDark,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getProgressColor(progress).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$completed / $goal',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getProgressColor(progress),
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppTheme.borderDark,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(progress),
                      ),
                    ),
                  ),
                  if (remaining > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '$remaining sets remaining',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppTheme.successGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Target completed!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.successGreen,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return AppTheme.successGreen;
    if (progress >= 0.7) return AppTheme.primaryOrange;
    if (progress >= 0.4) return AppTheme.warningAmber;
    return AppTheme.textDim;
  }
}