import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/domain/entities/exercise.dart';
import 'package:fitness_tracker/domain/entities/muscle_visual_data.dart';
import 'package:fitness_tracker/domain/entities/nutrition_log.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:fitness_tracker/domain/entities/time_period.dart';
import 'package:fitness_tracker/domain/entities/workout_set.dart';
import 'package:fitness_tracker/features/home/application/home_bloc.dart';
import 'package:fitness_tracker/features/home/application/muscle_visual_bloc.dart';
import 'package:fitness_tracker/features/home/presentation/mappers/home_view_data_mapper.dart';
import 'package:fitness_tracker/features/home/presentation/models/home_view_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime createdAt = DateTime(2024, 1, 1);

  HomeLoaded buildHomeState({
    required List<Target> targets,
    required List<WorkoutSet> weeklySets,
    required List<Exercise> exercises,
  }) {
    return HomeLoaded(
      targets: targets,
      weeklySets: weeklySets,
      todaysLogs: const <NutritionLog>[],
      dailyMacros: const <String, double>{},
      exercises: exercises,
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

  Exercise buildExercise({
    required String id,
    required List<String> muscleGroups,
  }) {
    return Exercise(
      id: id,
      name: 'Exercise $id',
      muscleGroups: muscleGroups,
      equipment: 'barbell',
      instructions: const <String>[],
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
      final HomeLoaded homeState = buildHomeState(
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
        exercises: <Exercise>[
          buildExercise(
            id: 'exercise-1',
            muscleGroups: const <String>['chest'],
          ),
        ],
      );

      final MuscleVisualLoaded visualState = buildMuscleVisualState(
        period: TimePeriod.week,
        muscleData: <String, MuscleVisualData>{
          'chest': const MuscleVisualData(
            muscleGroup: 'chest',
            totalStimulus: 18,
            visualIntensity: 0.6,
            color: Colors.orange,
            hasTrained: true,
          ),
          'back': const MuscleVisualData(
            muscleGroup: 'back',
            totalStimulus: 0,
            visualIntensity: 0,
            color: Colors.grey,
            hasTrained: false,
          ),
        },
      );

      final HomePageViewData result = HomeViewDataMapper.map(
        homeState: homeState,
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
      final HomeLoaded homeState = buildHomeState(
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
        exercises: <Exercise>[
          buildExercise(
            id: 'exercise-1',
            muscleGroups: const <String>['chest'],
          ),
        ],
      );

      final MuscleVisualLoaded visualState = buildMuscleVisualState(
        period: TimePeriod.allTime,
        muscleData: <String, MuscleVisualData>{
          'chest': const MuscleVisualData(
            muscleGroup: 'chest',
            totalStimulus: 30,
            visualIntensity: 1,
            color: Colors.red,
            hasTrained: true,
          ),
        },
      );

      final HomePageViewData result = HomeViewDataMapper.map(
        homeState: homeState,
        muscleVisualState: visualState,
        settings: settings,
      );

      expect(result.progress.remainingTargetLabel, '-');
      expect(result.progress.targetTone, HomeTone.muted);
    });

    test('uses success tone when remaining target is zero', () {
      final HomeLoaded homeState = buildHomeState(
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
        exercises: <Exercise>[
          buildExercise(
            id: 'exercise-1',
            muscleGroups: const <String>['chest'],
          ),
        ],
      );

      final MuscleVisualLoaded visualState = buildMuscleVisualState(
        period: TimePeriod.week,
        muscleData: <String, MuscleVisualData>{
          'chest': const MuscleVisualData(
            muscleGroup: 'chest',
            totalStimulus: 22,
            visualIntensity: 0.8,
            color: Colors.red,
            hasTrained: true,
          ),
          'triceps': const MuscleVisualData(
            muscleGroup: 'triceps',
            totalStimulus: 14,
            visualIntensity: 0.5,
            color: Colors.orange,
            hasTrained: true,
          ),
        },
      );

      final HomePageViewData result = HomeViewDataMapper.map(
        homeState: homeState,
        muscleVisualState: visualState,
        settings: settings,
      );

      expect(result.progress.remainingTargetLabel, '0');
      expect(result.progress.targetTone, HomeTone.success);
    });

    test('builds muscle group progress items with completion state', () {
      final HomeLoaded homeState = buildHomeState(
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
        weeklySets: <WorkoutSet>[
          buildWorkoutSet(id: 'set-1', exerciseId: 'exercise-1'),
          buildWorkoutSet(id: 'set-2', exerciseId: 'exercise-1'),
          buildWorkoutSet(id: 'set-3', exerciseId: 'exercise-2'),
        ],
        exercises: <Exercise>[
          buildExercise(
            id: 'exercise-1',
            muscleGroups: const <String>['chest'],
          ),
          buildExercise(
            id: 'exercise-2',
            muscleGroups: const <String>['quads'],
          ),
        ],
      );

      final HomePageViewData result = HomeViewDataMapper.map(
        homeState: homeState,
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