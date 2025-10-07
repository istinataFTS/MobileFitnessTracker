import 'package:flutter/material.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/goals_manager.dart';
import '../../../config/env_config.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GoalsManager(),
      builder: (context, child) {
        final goalsManager = GoalsManager();
        
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTodaySection(context),
                        const SizedBox(height: 24),
                        _buildWeekSummaryCard(context, goalsManager),
                        const SizedBox(height: 32),
                        _buildSectionHeader(context, 'Muscle Groups'),
                        const SizedBox(height: 16),
                        _buildMuscleGroupsList(context, goalsManager),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
              color: AppTheme.primaryOrange,
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
                  'Username: ${EnvConfig.userName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to settings - will be handled by bottom nav
            },
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
          "Today's Day + Date",
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

  Widget _buildWeekSummaryCard(BuildContext context, GoalsManager goalsManager) {
    // TODO: Replace with actual completed sets data
    const totalSets = 45;
    final goalSets = goalsManager.totalWeeklyGoal;
    final progress = totalSets / goalSets;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Weekly Goals',
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
              Text(
                '$totalSets',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryOrange,
                    ),
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
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: AppTheme.borderDark,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryOrange,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% Complete',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${goalSets - totalSets} sets remaining',
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

  Widget _buildMuscleGroupsList(BuildContext context, GoalsManager goalsManager) {
    // TODO: Replace with actual completed sets data
    final muscleGroupsData = MuscleGroups.all.map((muscle) {
      final goal = goalsManager.getGoal(muscle);
      // Mock data - replace with actual progress
      final completed = (goal * 0.3).round(); // 30% completed for demo
      return {
        'muscle': muscle,
        'completed': completed,
        'goal': goal,
      };
    }).toList();

    return Column(
      children: muscleGroupsData.map((data) {
        return _buildMuscleGroupCard(
          context,
          data['muscle'] as String,
          data['completed'] as int,
          data['goal'] as int,
        );
      }).toList(),
    );
  }

  Widget _buildMuscleGroupCard(
    BuildContext context,
    String muscleGroup,
    int completed,
    int goal,
  ) {
    final progress = completed / goal;
    final remaining = goal - completed;
    final displayName = MuscleGroups.getDisplayName(muscleGroup);

    Color getProgressColor() {
      if (progress >= 1.0) return AppTheme.successGreen;
      if (progress >= 0.7) return AppTheme.primaryOrange;
      if (progress >= 0.4) return AppTheme.warningAmber;
      return AppTheme.textDim;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark, width: 1),
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
              Text(
                '$completed / $goal',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: getProgressColor(),
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
                getProgressColor(),
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
                  'Goal completed!',
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
    );
  }
}