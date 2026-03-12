import 'package:flutter/material.dart';

import '../../../../core/themes/app_theme.dart';
import '../bloc/home_bloc.dart';

class NutritionSummaryCard extends StatelessWidget {
  final HomeNutritionStats nutritionStats;

  const NutritionSummaryCard({
    super.key,
    required this.nutritionStats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildCaloriesSummary(context),
            const SizedBox(height: 20),
            ...nutritionStats.macroProgressItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildMacroProgress(context, item),
              ),
            ),
            const SizedBox(height: 8),
            _buildRecentLogsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.restaurant_menu,
            color: AppTheme.primaryOrange,
            size: 24,
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
    );
  }

  Widget _buildCaloriesSummary(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: AppTheme.primaryOrange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Calories',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMedium,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${nutritionStats.totalCalories.round()} kcal',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgress(BuildContext context, MacroProgress item) {
    final progressColor = item.isComplete
        ? AppTheme.successGreen
        : AppTheme.primaryOrange;

    final progressText = item.hasTarget
        ? '${item.actual.toStringAsFixed(0)} / ${item.target.toStringAsFixed(0)} ${item.unit}'
        : '${item.actual.toStringAsFixed(0)} ${item.unit}';

    final trailingText = item.hasTarget
        ? item.isComplete
            ? 'Done'
            : '${item.remaining.toStringAsFixed(0)} ${item.unit} left'
        : 'No target';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              trailingText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: item.hasTarget ? progressColor : AppTheme.textDim,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          progressText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMedium,
              ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: item.hasTarget ? item.progress : 0,
            minHeight: 8,
            backgroundColor: AppTheme.surfaceDark,
            color: progressColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentLogsSection(BuildContext context) {
    final recentLogs = nutritionStats.todaysLogs.take(3).toList();

    if (recentLogs.isEmpty) {
      return Container(
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest Entries',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...recentLogs.map(
          (log) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Row(
              children: [
                Icon(
                  log.isMealLog ? Icons.restaurant : Icons.calculate,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.mealName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${log.proteinGrams.toStringAsFixed(0)}P • '
                        '${log.carbsGrams.toStringAsFixed(0)}C • '
                        '${log.fatGrams.toStringAsFixed(0)}F • '
                        '${log.calories.round()} kcal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMedium,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}