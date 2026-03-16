import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/themes/app_theme.dart';
import '../models/home_progress_view_data.dart';

extension on MuscleGroupProgressTone {
  Color get foregroundColor {
    switch (this) {
      case MuscleGroupProgressTone.success:
        return AppTheme.successGreen;
      case MuscleGroupProgressTone.primary:
        return AppTheme.primaryOrange;
    }
  }

  Color get badgeBackgroundColor {
    switch (this) {
      case MuscleGroupProgressTone.success:
        return AppTheme.successGreen.withOpacity(0.1);
      case MuscleGroupProgressTone.primary:
        return AppTheme.primaryOrange.withOpacity(0.1);
    }
  }
}

class MuscleGroupProgressCard extends StatelessWidget {
  final MuscleGroupProgressItemViewData viewData;

  const MuscleGroupProgressCard({
    super.key,
    required this.viewData,
  });

  @override
  Widget build(BuildContext context) {
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
                    viewData.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (viewData.showCompleteBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: viewData.tone.badgeBackgroundColor,
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
                  viewData.progressLabel,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                ),
                const Spacer(),
                Text(
                  viewData.percentageLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: viewData.tone.foregroundColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: viewData.progressValue,
                minHeight: 6,
                backgroundColor: AppTheme.surfaceDark,
                color: viewData.tone.foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}