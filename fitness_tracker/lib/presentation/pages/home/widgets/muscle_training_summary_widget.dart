import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/themes/app_theme.dart';
import '../models/muscle_training_summary_view_data.dart';

class MuscleTrainingSummaryWidget extends StatelessWidget {
  final MuscleTrainingSummaryViewData viewData;
  final bool isLoading;

  const MuscleTrainingSummaryWidget({
    super.key,
    required this.viewData,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState(context);
    }

    if (!viewData.hasData) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryHighlightsRow(viewData: viewData),
        const SizedBox(height: 16),
        ...viewData.items.map(
          (muscle) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MuscleSummaryTile(muscle: muscle),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      height: 260,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.loadingMuscleSummary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textDim,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.insights_outlined,
            size: 40,
            color: AppTheme.textDim,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.noMuscleActivityYet,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.noMuscleActivityDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMedium,
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryHighlightsRow extends StatelessWidget {
  final MuscleTrainingSummaryViewData viewData;

  const _SummaryHighlightsRow({
    required this.viewData,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HighlightCard(
            icon: Icons.auto_awesome,
            label: AppStrings.trained,
            value: '${viewData.trainedCount} ${AppStrings.musclesSuffix}',
            accentColor: AppTheme.primaryOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _HighlightCard(
            icon: Icons.emoji_events_outlined,
            label: AppStrings.topFocus,
            value: viewData.topFocusLabel,
            accentColor: AppTheme.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _HighlightCard(
            icon: Icons.tune,
            label: AppStrings.averageIntensity,
            value: viewData.averageIntensityLabel,
            accentColor: viewData.averageIntensityColor,
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _HighlightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMedium,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class _MuscleSummaryTile extends StatelessWidget {
  final MuscleTrainingSummaryItem muscle;

  const _MuscleSummaryTile({
    required this.muscle,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (muscle.visualIntensity * 100).clamp(0, 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ColorIndicator(color: muscle.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  muscle.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              _IntensityBadge(
                label: muscle.intensityLabel,
                color: muscle.color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: muscle.visualIntensity.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppTheme.borderDark,
                    color: muscle.color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: muscle.color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${AppStrings.stimulusLabel}: ${muscle.stimulus.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMedium,
                ),
          ),
        ],
      ),
    );
  }
}

class _ColorIndicator extends StatelessWidget {
  final Color color;

  const _ColorIndicator({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
    );
  }
}

class _IntensityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _IntensityBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.45),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}