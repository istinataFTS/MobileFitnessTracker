import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings_phase7.dart';
import '../../../../core/themes/app_theme.dart';

/// Progress stats display widget for home page
class ProgressStatsWidget extends StatelessWidget {
  final int totalSets;
  final int remainingTarget;
  final int trainedMuscles;
  final bool hasTarget;

  const ProgressStatsWidget({
    super.key,
    required this.totalSets,
    required this.remainingTarget,
    required this.trainedMuscles,
    this.hasTarget = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildStatColumn(
              context,
              icon: Icons.fitness_center,
              value: totalSets.toString(),
              label: AppStringsPhase7.sets,
              color: totalSets > 0 ? AppTheme.primaryOrange : AppTheme.textDim,
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppTheme.borderDark,
          ),
          Expanded(
            child: _buildStatColumn(
              context,
              icon: Icons.flag_outlined,
              value: hasTarget ? remainingTarget.toString() : '-',
              label: AppStringsPhase7.target,
              color: _getTargetColor(remainingTarget),
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppTheme.borderDark,
          ),
          Expanded(
            child: _buildStatColumn(
              context,
              icon: Icons.auto_awesome,
              value: trainedMuscles.toString(),
              label: AppStringsPhase7.muscles,
              color: trainedMuscles > 0 ? AppTheme.primaryOrange : AppTheme.textDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 24,
          color: color,
        ),
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
    );
  }

  /// Get color for target based on remaining count
  Color _getTargetColor(int remaining) {
    if (!hasTarget) return AppTheme.textDim;
    if (remaining <= 0) return AppTheme.successGreen; // Target met/exceeded
    if (remaining <= 3) return AppTheme.warningAmber; // Close to target
    return AppTheme.primaryOrange; // Work to do
  }
}

/// Detailed progress stats card with additional information
/// 
/// Extended version with more detailed breakdowns
/// Suitable for dedicated progress tracking views
class DetailedProgressStatsWidget extends StatelessWidget {
  final int totalSets;
  final int totalTarget;
  final int remainingTarget;
  final int trainedMuscles;
  final int totalMuscles;
  final double progressPercentage;

  const DetailedProgressStatsWidget({
    super.key,
    required this.totalSets,
    required this.totalTarget,
    required this.remainingTarget,
    required this.trainedMuscles,
    this.totalMuscles = 20, // Default to all muscle groups
    this.progressPercentage = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              AppStringsPhase7.progress,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressPercentage.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: AppTheme.surfaceDark,
                color: _getProgressColor(progressPercentage),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progressPercentage * 100).toStringAsFixed(0)}% Complete',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
            const SizedBox(height: 24),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    context,
                    icon: Icons.fitness_center,
                    value: '$totalSets / $totalTarget',
                    label: 'Sets Completed',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(
                    context,
                    icon: Icons.auto_awesome,
                    value: '$trainedMuscles / $totalMuscles',
                    label: 'Muscles Trained',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Remaining target
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getTargetBoxColor(remainingTarget),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color: _getTargetIconColor(remainingTarget),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      remainingTarget <= 0
                          ? 'Target met! 🎉'
                          : '$remainingTarget sets remaining',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getTargetIconColor(remainingTarget),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryOrange),
            const SizedBox(width: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
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

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return AppTheme.successGreen;
    if (progress >= 0.7) return AppTheme.primaryOrange;
    return AppTheme.warningAmber;
  }

  Color _getTargetBoxColor(int remaining) {
    if (remaining <= 0) return AppTheme.successGreen.withOpacity(0.1);
    if (remaining <= 3) return AppTheme.warningAmber.withOpacity(0.1);
    return AppTheme.primaryOrange.withOpacity(0.1);
  }

  Color _getTargetIconColor(int remaining) {
    if (remaining <= 0) return AppTheme.successGreen;
    if (remaining <= 3) return AppTheme.warningAmber;
    return AppTheme.primaryOrange;
  }
}