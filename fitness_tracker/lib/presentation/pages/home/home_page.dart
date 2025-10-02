import 'package:flutter/material.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../core/themes/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () {
              // TODO: Show week selector
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeekSummaryCard(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Muscle Groups'),
            const SizedBox(height: 12),
            _buildMuscleGroupsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSummaryCard(BuildContext context) {
    // TODO: Replace with actual data from BLoC
    const totalSets = 45;
    const goalSets = 150;
    final progress = totalSets / goalSets;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'This Week',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$totalSets / $goalSets sets completed',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppTheme.borderDark,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryOrange,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${goalSets - totalSets} sets remaining',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildMuscleGroupsList(BuildContext context) {
    // TODO: Replace with actual data from BLoC
    final muscleGroupsData = MuscleGroups.all.map((muscle) {
      final goal = MuscleGroups.getDefaultGoal(muscle);
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
      return AppTheme.textLight;
    }

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
      ),
    );
  }
}