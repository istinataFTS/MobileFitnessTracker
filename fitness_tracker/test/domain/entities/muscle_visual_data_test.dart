import 'package:fitness_tracker/domain/entities/muscle_visual_data.dart';
import 'package:fitness_tracker/domain/muscle_visual/muscle_visual_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MuscleVisualData', () {
    test('builds untrained data with explicit empty state', () {
      final data = MuscleVisualData.untrained(
        'abs',
        aggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
      );

      expect(data.hasTrained, isFalse);
      expect(data.bucket, MuscleVisualBucket.empty);
      expect(data.coverageState, MuscleVisualCoverageState.empty);
      expect(data.appearsOnFront, isTrue);
      expect(data.appearsOnBack, isFalse);
      expect(data.color, isA<Color>());
    });

    test('builds overflowing data with capped intensity and explicit overflow state', () {
      final data = MuscleVisualData.fromStimulus(
        muscleGroup: 'side-delts',
        stimulus: 16,
        threshold: 10,
        aggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
      );

      expect(data.hasTrained, isTrue);
      expect(data.visualIntensity, 1.0);
      expect(data.coverageState, MuscleVisualCoverageState.overflow);
      expect(data.overflowAmount, 6.0);
      expect(data.appearsOnFront, isTrue);
      expect(data.appearsOnBack, isTrue);
    });
  });
}