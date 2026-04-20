import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/domain/entities/muscle_visual_data.dart';
import 'package:fitness_tracker/domain/muscle_visual/muscle_visual_contract.dart';
import 'package:fitness_tracker/domain/entities/nutrition_log.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:fitness_tracker/domain/entities/time_period.dart';
import 'package:fitness_tracker/domain/entities/workout_set.dart';
import 'package:fitness_tracker/features/home/application/models/home_dashboard_data.dart';
import 'package:fitness_tracker/features/home/application/muscle_visual_bloc.dart';
import 'package:fitness_tracker/features/home/presentation/mappers/home_view_data_mapper.dart';
import 'package:fitness_tracker/features/home/presentation/models/home_view_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime createdAt = DateTime(2024, 1, 1);

  HomeDashboardData buildHomeData({
    required List<Target> targets,
    required List<WorkoutSet> weeklySets,
    Map<String, int> muscleSetCounts = const <String, int>{},
    int? weeklySetCount,
  }) {
    return HomeDashboardData(
      targets: targets,
      weeklySets: weeklySets,
      todaysLogs: const <NutritionLog>[],
      dailyMacros: const <String, double>{},
      muscleSetCounts: muscleSetCounts,
      weeklySetCount: weeklySetCount ?? weeklySets.length,
    );
  }

  Target buildTrainingTarget({
    required String id,
    required String categoryKey,
    required double targetValue,
  }) {
    return Target(
      id: id,
      type: TargetType.muscleSets,
      categoryKey: categoryKey,
      targetValue: targetValue,
      unit: 'sets',
      period: TargetPeriod.weekly,
      createdAt: createdAt,
    );
  }

  WorkoutSet buildWorkoutSet({
    required String id,
    required String exerciseId,
  }) {
    return WorkoutSet(
      id: id,
      exerciseId: exerciseId,
      reps: 10,
      weight: 80,
      date: createdAt,
      createdAt: createdAt,
    );
  }

  MuscleVisualLoaded buildMuscleVisualState({
    required TimePeriod period,
    required Map<String, MuscleVisualData> muscleData,
  }) {
    return MuscleVisualLoaded(
      muscleData: muscleData,
      currentPeriod: period,
      loadedAt: createdAt,
    );
  }

  const AppSettings settings = AppSettings(
    notificationsEnabled: true,
    weekStartDay: WeekStartDay.monday,
    weightUnit: WeightUnit.kilograms,
  );

  group('HomeViewDataMapper progress mapping', () {
    test('builds weekly progress card with warning tone when target is nearly met', () {
      final HomeDashboardData homeData = buildHomeData(
        targets: <Target>[
          buildTrainingTarget(
            id: 'target-1',
            categoryKey: 'chest',
            targetValue: 12,
          ),
        ],
        weeklySets: List<WorkoutSet>.generate(
          9,
          (int index) => buildWorkoutSet(
            id: 'set-$index',
            exerciseId: 'exercise-1',
          ),
        ),
        muscleSetCounts: const <String, int>{'chest': 9},
      );

      final MuscleVisualLoaded visualState = buildMuscleVisualState(
        period: TimePeriod.week,
        muscleData: <String, MuscleVisualData>{
          'chest': const MuscleVisualData(
            muscleGroup: 'chest',
            totalStimulus: 18,
            threshold: 20,
            visualIntensity: 0.6,
            bucket: MuscleVisualBucket.heavy,
            coverageState: MuscleVisualCoverageState.partial,
            aggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
            visibleSurfaces: const <MuscleVisualSurface>{MuscleVisualSurface.front},
            overflowAmount: 0,
            hasTrained: true,
          ),
          'back': const MuscleVisualData(
            muscleGroup: 'back',
            totalStimulus: 0,
            threshold: 20,
            visualIntensity: 0,
            bucket: MuscleVisualBucket.empty,
            coverageState: MuscleVisualCoverageState.empty,
            aggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
            visibleSurfaces: const <MuscleVisualSurface>{MuscleVisualSurface.back},
            overflowAmount: 0,
            hasTrained: false,
          ),
        },
      );

      final HomePageViewData result = HomeViewDataMapper.map(
        homeData: homeData,
        muscleVisualState: visualState,
        settings: settings,
      );

      expect(result.progress.totalSetsLabel, '9');
      expect(result.progress.remainingTargetLabel, '3');
      expect(result.progress.trainedMusclesLabel, '1');
      expect(result.progress.targetTone, HomeTone.warning);
      expect(result.progress.isLoading, isFalse);
      expect(result.progress.errorMessage, isNull);
    });

    test('hides target value for non-week periods', () {
      final HomeDashboardData homeData = buildHomeData(
        targets: <Target>[
          buildTrainingTarget(
            id: 'target-1',
            categoryKey: 'chest',
            targetValue: 12,
          ),
        ],
        weeklySets: List<WorkoutSet>.generate(
          9,
          (int index) => buildWorkoutSet(
            id: 'set-$index',
            exerciseId: 'exercise-1',
          ),
        ),
        muscleSetCounts: const <String, int>{'chest': 9},
      );

      final MuscleVisualLoaded visualState = buildMuscleVisualState(
        period: TimePeriod.allTime,
        muscleData: <String, MuscleVisualData>{
          'chest': const MuscleVisualData(
            muscleGroup: 'chest',
            totalStimulus: 30,
            threshold: 20,
            visualIntensity: 1,
            bucket: MuscleVisualBucket.maximum,
            coverageState: MuscleVisualCoverageState.full,
            aggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
            visibleSurfaces: const <MuscleVisualSurface>{MuscleVisualSurface.front},
            overflowAmount: 10,
            hasTrained: true,
          ),
        },
      );

      final HomePageViewData result = HomeViewDataMapper.map(
        homeData: homeData,
        muscleVisualState: visualState,
        settings: settings,
      );

      expect(result.progress.remainingTargetLabel, '-');
      expect(result.progress.targetTone, HomeTone.muted);
    });

    test('uses success tone when remaining target is zero', () {
      final HomeDashboardData homeData = buildHomeData(
        targets: <Target>[
          buildTrainingTarget(
            id: 'target-1',
            categoryKey: 'chest',
            targetValue: 12,
          ),
        ],
        weeklySets: List<WorkoutSet>.generate(
          12,
          (int index) => buildWorkoutSet(
            id: 'set-$index',
            exerciseId: 'exercise-1',
          ),
        ),
        muscleSetCounts: const <String, int>{'chest': 12},
      );

      final MuscleVisualLoaded visualState = buildMuscleVisualState(
        period: TimePeriod.week,
        muscleData: <String, MuscleVisualData>{
          'chest': const MuscleVisualData(
            muscleGroup: 'chest',
            totalStimulus: 22,
            threshold: 20,
            visualIntensity: 0.8,
            bucket: MuscleVisualBucket.maximum,
            coverageState: MuscleVisualCoverageState.full,
            aggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
            visibleSurfaces: const <MuscleVisualSurface>{MuscleVisualSurface.front},
            overflowAmount: 2,
            hasTrained: true,
          ),
          'triceps': const MuscleVisualData(
            muscleGroup: 'triceps',
            totalStimulus: 14,
            threshold: 20,
            visualIntensity: 0.5,
            bucket: MuscleVisualBucket.heavy,
            coverageState: MuscleVisualCoverageState.partial,
            aggregationMode: MuscleVisualAggregationMode.rollingWeeklyLoad,
            visibleSurfaces: const <MuscleVisualSurface>{
              MuscleVisualSurface.front,
              MuscleVisualSurface.back,
            },
            overflowAmount: 0,
            hasTrained: true,
          ),
        },
      );

      final HomePageViewData result = HomeViewDataMapper.map(
        homeData: homeData,
        muscleVisualState: visualState,
        settings: settings,
      );

      expect(result.progress.remainingTargetLabel, '0');
      expect(result.progress.targetTone, HomeTone.success);
    });

    test('builds muscle group progress items with completion state', () {
      final HomeDashboardData homeData = buildHomeData(
        targets: <Target>[
          buildTrainingTarget(
            id: 'target-1',
            categoryKey: 'chest',
            targetValue: 2,
          ),
          buildTrainingTarget(
            id: 'target-2',
            categoryKey: 'quads',
            targetValue: 3,
          ),
        ],
        weeklySets: const <WorkoutSet>[],
        muscleSetCounts: const <String, int>{'chest': 2, 'quads': 1},
      );

      final HomePageViewData result = HomeViewDataMapper.map(
        homeData: homeData,
        muscleVisualState: const MuscleVisualInitial(),
        settings: settings,
      );

      expect(result.muscleGroups, hasLength(2));

      final HomeMuscleGroupProgressViewData chest =
          result.muscleGroups.firstWhere((HomeMuscleGroupProgressViewData item) {
        return item.title == 'Chest';
      });

      expect(chest.progressLabel, '2 / 2 sets');
      expect(chest.percentageLabel, '100%');
      expect(chest.progressValue, 1.0);
      expect(chest.isComplete, isTrue);
      expect(chest.tone, HomeTone.success);

      final HomeMuscleGroupProgressViewData quads =
          result.muscleGroups.firstWhere((HomeMuscleGroupProgressViewData item) {
        return item.title == 'Quads';
      });

      expect(quads.progressLabel, '1 / 3 sets');
      expect(quads.percentageLabel, '33%');
      expect(quads.progressValue, closeTo(0.3333, 0.001));
      expect(quads.isComplete, isFalse);
      expect(quads.tone, HomeTone.primary);
    });
  });
}
