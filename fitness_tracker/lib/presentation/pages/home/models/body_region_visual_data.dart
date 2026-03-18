import 'dart:ui';

import 'package:equatable/equatable.dart';

import '../../../../domain/muscle_visual/muscle_visual_contract.dart';
import 'body_view.dart';

class BodyRegionVisualData extends Equatable {
  final String regionId;
  final String muscleGroup;
  final String displayName;
  final BodyView view;
  final String overlayAssetPath;
  final double visualIntensity;
  final double overlayOpacity;
  final Color color;
  final bool hasTrained;
  final MuscleVisualBucket bucket;
  final MuscleVisualCoverageState coverageState;

  const BodyRegionVisualData({
    required this.regionId,
    required this.muscleGroup,
    required this.displayName,
    required this.view,
    required this.overlayAssetPath,
    required this.visualIntensity,
    required this.overlayOpacity,
    required this.color,
    required this.hasTrained,
    required this.bucket,
    required this.coverageState,
  });

  @override
  List<Object?> get props => [
        regionId,
        muscleGroup,
        displayName,
        view,
        overlayAssetPath,
        visualIntensity,
        overlayOpacity,
        color,
        hasTrained,
        bucket,
        coverageState,
      ];
}