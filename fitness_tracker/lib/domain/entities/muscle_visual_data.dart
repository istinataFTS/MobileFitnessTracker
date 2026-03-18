import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../core/constants/muscle_stimulus_constants.dart';
import '../muscle_visual/muscle_visual_contract.dart';

class MuscleVisualData extends Equatable {
  final String muscleGroup;

  /// Total aggregated stimulus value for the selected period semantics.
  final double totalStimulus;

  /// Threshold used for normalization for this period.
  final double threshold;

  /// Visual intensity normalized to 0.0-1.0 range.
  final double visualIntensity;

  /// Explicit visual/state bucket instead of deriving everything from Color.
  final MuscleVisualBucket bucket;

  /// Whether the muscle is empty / partial / full / overflow for the current
  /// aggregation semantics.
  final MuscleVisualCoverageState coverageState;

  /// How this visual was aggregated for the selected period.
  final MuscleVisualAggregationMode aggregationMode;

  /// Surfaces where this muscle should appear on the 2D model.
  final Set<MuscleVisualSurface> visibleSurfaces;

  /// Amount above threshold. 0 when not overflowing.
  final double overflowAmount;

  /// Whether this muscle has any training data.
  final bool hasTrained;

  const MuscleVisualData({
    required this.muscleGroup,
    required this.totalStimulus,
    required this.threshold,
    required this.visualIntensity,
    required this.bucket,
    required this.coverageState,
    required this.aggregationMode,
    required this.visibleSurfaces,
    required this.overflowAmount,
    required this.hasTrained,
  });

  factory MuscleVisualData.untrained(
    String muscleGroup, {
    required MuscleVisualAggregationMode aggregationMode,
  }) {
    return MuscleVisualData(
      muscleGroup: muscleGroup,
      totalStimulus: 0.0,
      threshold: 1.0,
      visualIntensity: 0.0,
      bucket: MuscleVisualBucket.empty,
      coverageState: MuscleVisualCoverageState.empty,
      aggregationMode: aggregationMode,
      visibleSurfaces: MuscleVisualContract.visibleSurfacesFor(muscleGroup),
      overflowAmount: 0.0,
      hasTrained: false,
    );
  }

  factory MuscleVisualData.fromStimulus({
    required String muscleGroup,
    required double stimulus,
    required double threshold,
    required MuscleVisualAggregationMode aggregationMode,
  }) {
    final result = MuscleVisualContract.classify(
      muscleGroup: muscleGroup,
      stimulus: stimulus,
      threshold: threshold,
      aggregationMode: aggregationMode,
    );

    return MuscleVisualData(
      muscleGroup: muscleGroup,
      totalStimulus: result.stimulus,
      threshold: result.threshold,
      visualIntensity: result.normalizedIntensity,
      bucket: result.bucket,
      coverageState: result.coverageState,
      aggregationMode: result.aggregationMode,
      visibleSurfaces: result.visibleSurfaces,
      overflowAmount: result.overflowAmount,
      hasTrained: result.hasTrained,
    );
  }

  Color get color => _colorForBucket(bucket, visualIntensity);

  bool get appearsOnFront => visibleSurfaces.contains(MuscleVisualSurface.front);

  bool get appearsOnBack => visibleSurfaces.contains(MuscleVisualSurface.back);

  bool get isOverflowing =>
      coverageState == MuscleVisualCoverageState.overflow;

  bool get isFullyCovered =>
      coverageState == MuscleVisualCoverageState.full || isOverflowing;

  String get intensityLevel {
    switch (bucket) {
      case MuscleVisualBucket.empty:
        return 'Untrained';
      case MuscleVisualBucket.light:
        return 'Light';
      case MuscleVisualBucket.moderate:
        return 'Moderate';
      case MuscleVisualBucket.heavy:
        return 'Heavy';
      case MuscleVisualBucket.maximum:
        return 'Maximum';
    }
  }

  String get colorName {
    switch (bucket) {
      case MuscleVisualBucket.empty:
        return 'Gray';
      case MuscleVisualBucket.light:
        return 'Green';
      case MuscleVisualBucket.moderate:
        return 'Yellow';
      case MuscleVisualBucket.heavy:
        return 'Orange';
      case MuscleVisualBucket.maximum:
        return 'Red';
    }
  }

  String get coverageLabel {
    switch (coverageState) {
      case MuscleVisualCoverageState.empty:
        return 'Empty';
      case MuscleVisualCoverageState.partial:
        return 'Partial';
      case MuscleVisualCoverageState.full:
        return 'Full';
      case MuscleVisualCoverageState.overflow:
        return 'Overflow';
    }
  }

  String get aggregationLabel {
    switch (aggregationMode) {
      case MuscleVisualAggregationMode.remainingDailyCapacity:
        return 'Daily Remaining Capacity';
      case MuscleVisualAggregationMode.rollingWeeklyLoad:
        return 'Rolling Weekly Load';
      case MuscleVisualAggregationMode.trailingThirtyDayLoad:
        return 'Trailing 30 Day Load';
      case MuscleVisualAggregationMode.allTimePeakNormalized:
        return 'All Time Peak Normalized';
    }
  }

  String get displayName {
    return MuscleStimulus.getDisplayName(muscleGroup);
  }

  MuscleVisualData copyWith({
    String? muscleGroup,
    double? totalStimulus,
    double? threshold,
    double? visualIntensity,
    MuscleVisualBucket? bucket,
    MuscleVisualCoverageState? coverageState,
    MuscleVisualAggregationMode? aggregationMode,
    Set<MuscleVisualSurface>? visibleSurfaces,
    double? overflowAmount,
    bool? hasTrained,
  }) {
    return MuscleVisualData(
      muscleGroup: muscleGroup ?? this.muscleGroup,
      totalStimulus: totalStimulus ?? this.totalStimulus,
      threshold: threshold ?? this.threshold,
      visualIntensity: visualIntensity ?? this.visualIntensity,
      bucket: bucket ?? this.bucket,
      coverageState: coverageState ?? this.coverageState,
      aggregationMode: aggregationMode ?? this.aggregationMode,
      visibleSurfaces: visibleSurfaces ?? this.visibleSurfaces,
      overflowAmount: overflowAmount ?? this.overflowAmount,
      hasTrained: hasTrained ?? this.hasTrained,
    );
  }

  static Color _colorForBucket(
    MuscleVisualBucket bucket,
    double intensity,
  ) {
    switch (bucket) {
      case MuscleVisualBucket.empty:
        return Colors.grey.withOpacity(0.3);
      case MuscleVisualBucket.light:
        final opacity =
            0.4 + (intensity / MuscleStimulus.colorThresholdGreen) * 0.3;
        return Colors.green.withOpacity(opacity.clamp(0.0, 1.0));
      case MuscleVisualBucket.moderate:
        final normalizedIntensity =
            (intensity - MuscleStimulus.colorThresholdGreen) /
                (MuscleStimulus.colorThresholdYellow -
                    MuscleStimulus.colorThresholdGreen);
        final opacity = 0.5 + normalizedIntensity * 0.3;
        return Colors.yellow.withOpacity(opacity.clamp(0.0, 1.0));
      case MuscleVisualBucket.heavy:
        final normalizedIntensity =
            (intensity - MuscleStimulus.colorThresholdYellow) /
                (MuscleStimulus.colorThresholdOrange -
                    MuscleStimulus.colorThresholdYellow);
        final opacity = 0.6 + normalizedIntensity * 0.2;
        return Colors.orange.withOpacity(opacity.clamp(0.0, 1.0));
      case MuscleVisualBucket.maximum:
        final normalizedIntensity =
            (intensity - MuscleStimulus.colorThresholdRed) /
                (1.0 - MuscleStimulus.colorThresholdRed);
        final opacity = 0.7 + normalizedIntensity * 0.3;
        return Colors.red.withOpacity(opacity.clamp(0.0, 1.0));
    }
  }

  @override
  List<Object?> get props => [
        muscleGroup,
        totalStimulus,
        threshold,
        visualIntensity,
        bucket,
        coverageState,
        aggregationMode,
        visibleSurfaces,
        overflowAmount,
        hasTrained,
      ];
}