import 'dart:ui';

import 'package:equatable/equatable.dart';

import 'body_view.dart';

class BodyRegionVisualData extends Equatable {
  final String regionId;
  final String muscleGroup;
  final String displayName;
  final BodyView view;
  final Rect normalizedRect;
  final double visualIntensity;
  final Color color;
  final bool hasTrained;

  const BodyRegionVisualData({
    required this.regionId,
    required this.muscleGroup,
    required this.displayName,
    required this.view,
    required this.normalizedRect,
    required this.visualIntensity,
    required this.color,
    required this.hasTrained,
  });

  @override
  List<Object?> get props => [
        regionId,
        muscleGroup,
        displayName,
        view,
        normalizedRect,
        visualIntensity,
        color,
        hasTrained,
      ];
}