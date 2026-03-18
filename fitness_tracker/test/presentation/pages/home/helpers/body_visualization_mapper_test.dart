import 'package:fitness_tracker/domain/entities/muscle_visual_data.dart';
import 'package:fitness_tracker/domain/muscle_visual/muscle_visual_contract.dart';
import 'package:fitness_tracker/presentation/pages/home/helpers/body_visualization_mapper.dart';
import 'package:fitness_tracker/presentation/pages/home/models/body_region_contract.dart';
import 'package:fitness_tracker/presentation/pages/home/models/body_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BodyRegionContract', () {
    test('defines front and back regions for owned muscle groups', () {
      expect(
        BodyRegionContract.forMuscle('front-delts')
            .where((r) => r.view == BodyView.front)
            .length,
        1,
      );

      expect(
        BodyRegionContract.forMuscle('rear-delts')
            .where((r) => r.view == BodyView.back)
            .length,
        1,
      );

      expect(
        BodyRegionContract.forMuscle('forearms')
            .map((r) => r.view)
            .toSet(),
        {BodyView.front, BodyView.back},
      );
    });

    test('every region has an overlay asset path', () {
      for (final region in BodyRegionContract.all) {
        expect(region.overlayAssetPath, isNotEmpty);
        expect(region.overlayAssetPath.endsWith('.png'), isTrue);
      }
    });
  });

  group('BodyVisualizationMapper', () {
    test('maps front regions using provided muscle visual data', () {
      final data = <String, MuscleVisualData>{
        'front-delts': MuscleVisualData(
          muscleGroup: 'front-delts',
          totalStimulus: 12,
          threshold: 20,
          visualIntensity: 0.5,
          bucket: MuscleVisualBucket.heavy,
          coverageState: MuscleVisualCoverageState.partial,
          aggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
          visibleSurfaces: const {MuscleVisualSurface.front},
          overflowAmount: 0,
          hasTrained: true,
        ),
      };

      final regions = BodyVisualizationMapper.mapRegions(
        muscleData: data,
        view: BodyView.front,
      );

      final trainedFrontDelts = regions
          .where((region) => region.muscleGroup == 'front-delts')
          .toList();

      expect(trainedFrontDelts, hasLength(1));
      expect(trainedFrontDelts.every((r) => r.hasTrained), isTrue);
      expect(
        trainedFrontDelts.every((r) => r.color == const Color(0xFFFF9800)),
        isTrue,
      );
    });

    test('fills missing muscles as untrained regions', () {
      final regions = BodyVisualizationMapper.mapRegions(
        muscleData: const {},
        view: BodyView.back,
      );

      expect(regions, isNotEmpty);
      expect(regions.every((region) => region.hasTrained == false), isTrue);
      expect(regions.every((region) => region.overlayOpacity == 0.0), isTrue);
    });

    test('reports training only when at least one muscle is trained', () {
      expect(
        BodyVisualizationMapper.hasAnyTraining(const {}),
        isFalse,
      );

      expect(
        BodyVisualizationMapper.hasAnyTraining({
          'quads': MuscleVisualData(
            muscleGroup: 'quads',
            totalStimulus: 18,
            threshold: 20,
            visualIntensity: 0.7,
            bucket: MuscleVisualBucket.maximum,
            coverageState: MuscleVisualCoverageState.partial,
            aggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
            visibleSurfaces: const {MuscleVisualSurface.front},
            overflowAmount: 0,
            hasTrained: true,
          ),
        }),
        isTrue,
      );
    });
  });
}