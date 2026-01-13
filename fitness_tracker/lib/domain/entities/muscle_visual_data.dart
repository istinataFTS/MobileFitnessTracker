import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/constants/muscle_stimulus_constants.dart';


class MuscleVisualData extends Equatable {
  final String muscleGroup;
  
  /// Total stimulus value for the selected period
  final double totalStimulus;
  
  /// Visual intensity normalized to 0.0-1.0 range
  /// Calculated as: totalStimulus / threshold
  /// Clamped to 0.0-1.0
  final double visualIntensity;
  
  /// Color to display for this muscle
  final Color color;
  
  /// Whether this muscle has any training data
  final bool hasTrained;

  const MuscleVisualData({
    required this.muscleGroup,
    required this.totalStimulus,
    required this.visualIntensity,
    required this.color,
    required this.hasTrained,
  });

  /// Create untrained muscle visual data (all gray)
  factory MuscleVisualData.untrained(String muscleGroup) {
    return MuscleVisualData(
      muscleGroup: muscleGroup,
      totalStimulus: 0.0,
      visualIntensity: 0.0,
      color: Colors.grey.withOpacity(0.3),
      hasTrained: false,
    );
  }

  /// Create visual data from stimulus and threshold
  /// 
  /// Calculates visual intensity and determines color based on thresholds
  factory MuscleVisualData.fromStimulus({
    required String muscleGroup,
    required double stimulus,
    required double threshold,
  }) {
    // Calculate visual intensity (normalized to 0.0-1.0)
    final visualIntensity = threshold > 0 
        ? (stimulus / threshold).clamp(0.0, 1.0) 
        : 0.0;

    // Determine color based on intensity thresholds
    final color = getColorForIntensity(visualIntensity);

    return MuscleVisualData(
      muscleGroup: muscleGroup,
      totalStimulus: stimulus,
      visualIntensity: visualIntensity,
      color: color,
      hasTrained: stimulus > 0,
    );
  }

  /// Get color based on visual intensity
  /// 
  /// Color mapping:
  /// - Gray (0.0): No training
  /// - Green (0.0-0.20): Light training
  /// - Yellow (0.20-0.45): Moderate training
  /// - Orange (0.45-0.70): Heavy training
  /// - Red (0.70-1.0): Maximum training
  static Color getColorForIntensity(double intensity) {
    if (intensity == 0.0) {
      // Gray for untrained muscles
      return Colors.grey.withOpacity(0.3);
    } else if (intensity < MuscleStimulus.colorThresholdGreen) {
      // Green zone: light training
      final opacity = 0.4 + (intensity / MuscleStimulus.colorThresholdGreen) * 0.3;
      return Colors.green.withOpacity(opacity);
    } else if (intensity < MuscleStimulus.colorThresholdYellow) {
      // Yellow zone: moderate training
      final normalizedIntensity = (intensity - MuscleStimulus.colorThresholdGreen) / 
                                   (MuscleStimulus.colorThresholdYellow - MuscleStimulus.colorThresholdGreen);
      final opacity = 0.5 + normalizedIntensity * 0.3;
      return Colors.yellow.withOpacity(opacity);
    } else if (intensity < MuscleStimulus.colorThresholdOrange) {
      // Orange zone: heavy training
      final normalizedIntensity = (intensity - MuscleStimulus.colorThresholdYellow) / 
                                   (MuscleStimulus.colorThresholdOrange - MuscleStimulus.colorThresholdYellow);
      final opacity = 0.6 + normalizedIntensity * 0.2;
      return Colors.orange.withOpacity(opacity);
    } else {
      // Red zone: maximum training
      final normalizedIntensity = (intensity - MuscleStimulus.colorThresholdRed) / 
                                   (1.0 - MuscleStimulus.colorThresholdRed);
      final opacity = 0.7 + normalizedIntensity * 0.3;
      return Colors.red.withOpacity(opacity);
    }
  }

  /// Get intensity level as string
  String get intensityLevel {
    if (!hasTrained) return 'Untrained';
    if (visualIntensity < MuscleStimulus.colorThresholdGreen) return 'Light';
    if (visualIntensity < MuscleStimulus.colorThresholdYellow) return 'Moderate';
    if (visualIntensity < MuscleStimulus.colorThresholdOrange) return 'Heavy';
    return 'Maximum';
  }

  /// Get color name as string
  String get colorName {
    if (!hasTrained) return 'Gray';
    if (visualIntensity < MuscleStimulus.colorThresholdGreen) return 'Green';
    if (visualIntensity < MuscleStimulus.colorThresholdYellow) return 'Yellow';
    if (visualIntensity < MuscleStimulus.colorThresholdOrange) return 'Orange';
    return 'Red';
  }

  /// Get display name for muscle group
  String get displayName {
    return MuscleStimulus.getDisplayName(muscleGroup);
  }

  MuscleVisualData copyWith({
    String? muscleGroup,
    double? totalStimulus,
    double? visualIntensity,
    Color? color,
    bool? hasTrained,
  }) {
    return MuscleVisualData(
      muscleGroup: muscleGroup ?? this.muscleGroup,
      totalStimulus: totalStimulus ?? this.totalStimulus,
      visualIntensity: visualIntensity ?? this.visualIntensity,
      color: color ?? this.color,
      hasTrained: hasTrained ?? this.hasTrained,
    );
  }

  @override
  List<Object?> get props => [
        muscleGroup,
        totalStimulus,
        visualIntensity,
        color,
        hasTrained,
      ];
}