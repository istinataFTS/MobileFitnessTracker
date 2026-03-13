import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class MuscleTrainingSummaryItem extends Equatable {
  final String displayName;
  final double stimulus;
  final double visualIntensity;
  final Color color;
  final String intensityLabel;

  const MuscleTrainingSummaryItem({
    required this.displayName,
    required this.stimulus,
    required this.visualIntensity,
    required this.color,
    required this.intensityLabel,
  });

  @override
  List<Object?> get props => [
        displayName,
        stimulus,
        visualIntensity,
        color,
        intensityLabel,
      ];
}

class MuscleTrainingSummaryViewData extends Equatable {
  final int trainedCount;
  final String topFocusLabel;
  final String averageIntensityLabel;
  final Color averageIntensityColor;
  final List<MuscleTrainingSummaryItem> items;

  const MuscleTrainingSummaryViewData({
    required this.trainedCount,
    required this.topFocusLabel,
    required this.averageIntensityLabel,
    required this.averageIntensityColor,
    required this.items,
  });

  factory MuscleTrainingSummaryViewData.empty() {
    return const MuscleTrainingSummaryViewData(
      trainedCount: 0,
      topFocusLabel: '',
      averageIntensityLabel: 'None',
      averageIntensityColor: Colors.grey,
      items: [],
    );
  }

  bool get hasData => items.isNotEmpty;

  @override
  List<Object?> get props => [
        trainedCount,
        topFocusLabel,
        averageIntensityLabel,
        averageIntensityColor,
        items,
      ];
}