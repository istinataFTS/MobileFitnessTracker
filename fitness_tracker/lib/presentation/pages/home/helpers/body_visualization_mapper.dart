import 'package:fitness_tracker/core/constants/muscle_stimulus_constants.dart';
import 'package:fitness_tracker/domain/entities/muscle_visual_data.dart';
import 'package:fitness_tracker/presentation/pages/home/models/body_region_contract.dart';
import 'package:fitness_tracker/presentation/pages/home/models/body_region_visual_data.dart';
import 'package:fitness_tracker/presentation/pages/home/models/body_view.dart';
import 'package:flutter/material.dart';

class BodyVisualizationMapper {
  const BodyVisualizationMapper._();

  static List<BodyRegionVisualData> mapRegions({
    required Map<String, MuscleVisualData> muscleData,
    required BodyView view,
  }) {
    final contracts = BodyRegionContract.forView(view);

    return contracts.map((contract) {
      final muscleVisual = muscleData[contract.muscleGroup] ??
          MuscleVisualData.untrained(
            contract.muscleGroup,
            aggregationMode: contract.defaultAggregationMode,
          );

      return BodyRegionVisualData(
        regionId: contract.id,
        muscleGroup: contract.muscleGroup,
        displayName: MuscleStimulus.getDisplayName(contract.muscleGroup),
        view: contract.view,
        overlayAssetPath: contract.overlayAssetPath,
        visualIntensity: muscleVisual.visualIntensity,
        overlayOpacity: _resolveRegionOpacity(muscleVisual),
        color: _resolveRegionColor(muscleVisual),
        hasTrained: muscleVisual.hasTrained,
        bucket: muscleVisual.bucket,
        coverageState: muscleVisual.coverageState,
      );
    }).toList(growable: false);
  }

  static bool hasAnyTraining(Map<String, MuscleVisualData> muscleData) {
    return muscleData.values.any((entry) => entry.hasTrained);
  }

  static Color _resolveRegionColor(MuscleVisualData data) {
    if (!data.hasTrained) {
      return Colors.transparent;
    }

    return data.color;
  }

  static double _resolveRegionOpacity(MuscleVisualData data) {
    if (!data.hasTrained) {
      return 0.0;
    }

    return data.overlayOpacity;
  }
}