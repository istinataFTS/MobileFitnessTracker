import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/domain/entities/muscle_visual_data.dart';
import 'package:fitness_tracker/domain/entities/nutrition_log.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:fitness_tracker/domain/entities/time_period.dart';
import 'package:fitness_tracker/domain/entities/workout_set.dart';
import 'package:fitness_tracker/domain/muscle_visual/muscle_visual_contract.dart';
import 'package:fitness_tracker/features/home/application/models/home_dashboard_data.dart';
import 'package:fitness_tracker/features/home/application/muscle_visual_bloc.dart';
import 'package:fitness_tracker/features/home/presentation/mappers/home_view_data_mapper.dart';
import 'package:fitness_tracker/features/home/presentation/models/home_view_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression guards for the "stat cards disagree with the 2D muscle map"
/// bug (Phase 3). The fix routed the Sets stat card through
/// MuscleLoadResolver so it counts the same sets the map derives its
/// highlights from — these tests pin that contract at the mapper boundary.
void main() {
  final DateTime now = DateTime(2026, 4, 20);
  const AppSettings settings = AppSettings.defaults();

  MuscleVisualData trained(String group, {double stimulus = 18}) {
    return MuscleVisualData(
      muscleGroup: group,
      totalStimulus: stimulus,
      threshold: 25,
      visualIntensity: stimulus / 25,
      bucket: MuscleVisualBucket.heavy,
      coverageState: MuscleVisualCoverageState.partial,
      aggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
      visibleSurfaces: const <MuscleVisualSurface>{MuscleVisualSurface.front},
      overflowAmount: 0,
      hasTrained: true,
    );
  }

  MuscleVisualData untrained(String group) {
    return MuscleVisualData(
      muscleGroup: group,
      totalStimulus: 0,
      threshold: 25,
      visualIntensity: 0,
      bucket: MuscleVisualBucket.empty,
      coverageState: MuscleVisualCoverageState.empty,
      aggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
      visibleSurfaces: const <MuscleVisualSurface>{MuscleVisualSurface.front},
      overflowAmount: 0,
      hasTrained: false,
    );
  }

  HomeDashboardData homeDataWith({
    required int weeklySetCount,
    List<Target> targets = const <Target>[],
  }) {
    return HomeDashboardData(
      targets: targets,
      weeklySets: const <WorkoutSet>[],
      todaysLogs: const <NutritionLog>[],
      dailyMacros: const <String, double>{},
      weeklySetCount: weeklySetCount,
    );
  }

  MuscleVisualLoaded loadedState({
    required Map<String, MuscleVisualData> muscleData,
    TimePeriod period = TimePeriod.week,
  }) {
    return MuscleVisualLoaded(
      muscleData: muscleData,
      currentPeriod: period,
      loadedAt: now,
    );
  }

  test(
    'Sets card and Muscles card move together: training presence is consistent',
    () {
      // A set registered against a tracked exercise should produce
      // weeklySetCount > 0 AND ≥1 trained muscle.  Before Phase 3, Sets came
      // from a raw repo list and Muscles came from factor-aware stimulus,
      // so a factor-less exercise inflated Sets while the map stayed blank.
      final HomePageViewData result = HomeViewDataMapper.map(
        homeData: homeDataWith(weeklySetCount: 3),
        muscleVisualState: loadedState(
          muscleData: <String, MuscleVisualData>{
            'chest': trained('chest'),
            'lats': untrained('lats'),
          },
        ),
        settings: settings,
      );

      expect(result.progress.totalSetsLabel, '3');
      expect(result.progress.trainedMusclesLabel, '1');
    },
  );

  test(
    'zero sets in range ⇒ zero trained muscles on the map (empty-week '
    'parity)',
    () {
      final HomePageViewData result = HomeViewDataMapper.map(
        homeData: homeDataWith(weeklySetCount: 0),
        muscleVisualState: loadedState(
          muscleData: <String, MuscleVisualData>{
            'chest': untrained('chest'),
            'lats': untrained('lats'),
          },
        ),
        settings: settings,
      );

      expect(result.progress.totalSetsLabel, '0');
      expect(result.progress.trainedMusclesLabel, '0');
      expect(result.progress.bodyVisual.frontLayers, isEmpty);
      expect(result.progress.bodyVisual.backLayers, isEmpty);
    },
  );

  test(
    'Sets card reads from HomeDashboardData.weeklySetCount, not a raw '
    'weeklySets list — regression guard for the SSOT fix',
    () {
      // If a future change re-routes the Sets card back to weeklySets.length,
      // this test will fail: weeklySets is empty but weeklySetCount is 4,
      // so the card must show 4 (resolver-sourced count).
      final HomePageViewData result = HomeViewDataMapper.map(
        homeData: homeDataWith(weeklySetCount: 4),
        muscleVisualState: loadedState(
          muscleData: <String, MuscleVisualData>{
            'chest': trained('chest'),
          },
        ),
        settings: settings,
      );

      expect(result.progress.totalSetsLabel, '4');
    },
  );
}
