import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../domain/entities/muscle_visual_data.dart';
import '../models/muscle_training_summary_view_data.dart';

class MuscleTrainingSummaryMapper {
  const MuscleTrainingSummaryMapper._();

  static MuscleTrainingSummaryViewData map(
    Map<String, MuscleVisualData> muscleData, {
    int maxItems = 6,
  }) {
    final trainedMuscles = muscleData.values
        .where((entry) => entry.hasTrained && entry.totalStimulus > 0)
        .toList()
      ..sort((a, b) => b.totalStimulus.compareTo(a.totalStimulus));

    if (trainedMuscles.isEmpty) {
      return MuscleTrainingSummaryViewData.empty();
    }

    final strongest = trainedMuscles.first;
    final averageIntensity = trainedMuscles
            .map((m) => m.visualIntensity)
            .fold<double>(0.0, (sum, value) => sum + value) /
        trainedMuscles.length;

    final items = trainedMuscles
        .take(maxItems)
        .map(
          (muscle) => MuscleTrainingSummaryItem(
            displayName: muscle.displayName,
            stimulus: muscle.totalStimulus,
            visualIntensity: muscle.visualIntensity,
            color: muscle.color,
            intensityLabel: muscle.intensityLevel,
          ),
        )
        .toList(growable: false);

    return MuscleTrainingSummaryViewData(
      trainedCount: trainedMuscles.length,
      topFocusLabel: strongest.displayName,
      averageIntensityLabel: _formatAverageIntensity(averageIntensity),
      averageIntensityColor: _colorForAverageIntensity(averageIntensity),
      items: items,
    );
  }

  static String _formatAverageIntensity(double value) {
    if (value < 0.20) return AppStrings.intensityLight;
    if (value < 0.45) return AppStrings.intensityModerate;
    if (value < 0.70) return AppStrings.intensityHeavy;
    return AppStrings.intensityHigh;
  }

  static Color _colorForAverageIntensity(double value) {
    if (value < 0.20) return Colors.green;
    if (value < 0.45) return Colors.yellow.shade700;
    if (value < 0.70) return Colors.orange;
    return Colors.red;
  }
}