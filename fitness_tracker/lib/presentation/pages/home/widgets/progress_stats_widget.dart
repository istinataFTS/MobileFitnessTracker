import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/themes/app_theme.dart';
import '../models/home_progress_view_data.dart';

extension on HomeProgressTone {
  Color get foregroundColor {
    switch (this) {
      case HomeProgressTone.success:
        return AppTheme.successGreen;
      case HomeProgressTone.warning:
        return AppTheme.warningAmber;
      case HomeProgressTone.primary:
        return AppTheme.primaryOrange;
      case HomeProgressTone.muted:
        return AppTheme.textDim;
    }
  }

  Color get backgroundTint {
    switch (this) {
      case HomeProgressTone.success:
        return AppTheme.successGreen.withOpacity(0.1);
      case HomeProgressTone.warning:
        return AppTheme.warningAmber.withOpacity(0.1);
      case HomeProgressTone.primary:
        return AppTheme.primaryOrange.withOpacity(0.1);
      case HomeProgressTone.muted:
        return AppTheme.surfaceDark;
    }
  }
}

/// Progress stats display widget for home page
class ProgressStatsWidget extends StatelessWidget {
  final HomeProgressStatsViewData viewData;

  const ProgressStatsWidget({
    super.key,
    required this.viewData,
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
              stat: viewData.totalSetsStat,
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
              stat: viewData.targetStat,
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
              stat: viewData.trainedMusclesStat,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required IconData icon,
    required HomeProgressStatViewData stat,
  }) {
    final Color color = stat.tone.foregroundColor;

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
          stat.value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          stat.label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMedium,
              ),
        ),
      ],
    );
  }
}

/// Detailed progress stats card with additional information
///
/// Extended version with more detailed breakdowns
/// Suitable for dedicated progress tracking views
class DetailedProgressStatsWidget extends StatelessWidget {
  final DetailedHomeProgressStatsViewData viewData;

  const DetailedProgressStatsWidget({
    super.key,
    required this.viewData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStringsPhase7.progress,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: viewData.progressValue,
                minHeight: 12,
                backgroundColor: AppTheme.surfaceDark,
                color: viewData.progressTone.foregroundColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewData.progressLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMedium,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    context,
                    icon: Icons.fitness_center,
                    stat: viewData.completedSetsStat,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(
                    context,
                    icon: Icons.auto_awesome,
                    stat: viewData.trainedMusclesStat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: viewData.targetCallout.tone.backgroundTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color: viewData.targetCallout.tone.foregroundColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      viewData.targetCallout.message,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: viewData.targetCallout.tone.foregroundColor,
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
    required HomeProgressStatViewData stat,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: stat.tone.foregroundColor,
            ),
            const SizedBox(width: 8),
            Text(
              stat.value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: stat.tone.foregroundColor,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          stat.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMedium,
              ),
        ),
      ],
    );
  }
}