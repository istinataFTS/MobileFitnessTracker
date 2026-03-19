import 'package:fitness_tracker/domain/entities/muscle_visual_data.dart';
import 'package:fitness_tracker/domain/entities/nutrition_log.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:fitness_tracker/domain/entities/time_period.dart';
import 'package:fitness_tracker/domain/entities/workout_set.dart';
import 'package:fitness_tracker/presentation/pages/exercises/bloc/exercise_bloc.dart';
import 'package:fitness_tracker/presentation/pages/home/bloc/home_bloc.dart';
import 'package:fitness_tracker/presentation/pages/home/bloc/muscle_visual_bloc.dart';
import 'package:fitness_tracker/presentation/pages/home/helpers/home_progress_mapper.dart';
import 'package:fitness_tracker/presentation/pages/home/models/home_progress_view_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime createdAt = DateTime(2024, 1, 1);

  HomeLoaded buildHomeState({
    required List<Target> targets,
    required List<WorkoutSet> weeklySets,
  }) {
    return HomeLoaded(
      targets: targets,
      weeklySets: weeklySets,
      todaysLogs: const <NutritionLog>[],
      dailyMacros: const <String, double>{},
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

  group('HomeProgressMapper.buildProgressStats', () {
    test('builds weekly progress stats with target tone when target is nearly met',
        () {
      final homeState = buildHomeState(
        targets: <Target>[
          buildTrainingTarget(
            id: 'target-1',
            categoryKey: 'chest',
            targetValue: 12,
          ),
        ],
        weeklySets: List<WorkoutSet>.generate(
          9,
          (index) => buildWorkoutSet(
            id: 'set-$index',
            exerciseId: 'exercise-1',
          ),
        ),
      );

      final muscleState = buildMuscleVisualState(
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

      final result = HomeProgressMapper.buildProgressStats(
        homeState: homeState,
        muscleState: muscleState,
      );

      expect(result.totalSetsStat.value, '9');
      expect(result.totalSetsStat.label, 'Sets');
      expect(result.totalSetsStat.tone, HomeProgressTone.primary);

      expect(result.targetStat.value, '3');
      expect(result.targetStat.label, 'Target');
      expect(result.targetStat.tone, HomeProgressTone.warning);

      expect(result.trainedMusclesStat.value, '1');
      expect(result.trainedMusclesStat.label, 'Muscles');
      expect(result.trainedMusclesStat.tone, HomeProgressTone.primary);
    });

    test('hides target value for non-week periods', () {
      final homeState = buildHomeState(
        targets: <Target>[
          buildTrainingTarget(
            id: 'target-1',
            categoryKey: 'chest',
            targetValue: 12,
          ),
        ],
        weeklySets: List<WorkoutSet>.generate(
          9,
          (index) => buildWorkoutSet(
            id: 'set-$index',
            exerciseId: 'exercise-1',
          ),
        ),
      );

      final muscleState = buildMuscleVisualState(
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

      final result = HomeProgressMapper.buildProgressStats(
        homeState: homeState,
        muscleState: muscleState,
      );

      expect(result.targetStat.value, '-');
      expect(result.targetStat.tone, HomeProgressTone.muted);
    });

    test('uses success tone when remaining target is zero', () {
      final homeState = buildHomeState(
        targets: <Target>[
          buildTrainingTarget(
            id: 'target-1',
            categoryKey: 'chest',
            targetValue: 12,
          ),
        ],
        weeklySets: List<WorkoutSet>.generate(
          12,
          (index) => buildWorkoutSet(
            id: 'set-$index',
            exerciseId: 'exercise-1',
          ),
        ),
      );

      final muscleState = buildMuscleVisualState(
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

      final result = HomeProgressMapper.buildProgressStats(
        homeState: homeState,
        muscleState: muscleState,
      );

      expect(result.targetStat.value, '0');
      expect(result.targetStat.tone, HomeProgressTone.success);
    });
  });

  group('HomeProgressMapper.buildDetailedProgressStats', () {
    test('builds detailed progress stats view data', () {
      final result = HomeProgressMapper.buildDetailedProgressStats(
        totalSets: 8,
        totalTarget: 10,
        remainingTarget: 2,
        trainedMuscles: 4,
        totalMuscles: 20,
        progressPercentage: 0.8,
      );

      expect(result.progressValue, 0.8);
      expect(result.progressLabel, '80% Complete');
      expect(result.progressTone, HomeProgressTone.primary);
      expect(result.completedSetsStat.value, '8 / 10');
      expect(result.trainedMusclesStat.value, '4 / 20');
      expect(result.targetCallout.message, '2 sets remaining');
      expect(result.targetCallout.tone, HomeProgressTone.warning);
    });

    test('marks completed target callout as success', () {
      final result = HomeProgressMapper.buildDetailedProgressStats(
        totalSets: 12,
        totalTarget: 12,
        remainingTarget: 0,
        trainedMuscles: 5,
        progressPercentage: 1.0,
      );

      expect(result.progressTone, HomeProgressTone.success);
      expect(result.targetCallout.message, 'Target met! 🎉');
      expect(result.targetCallout.tone, HomeProgressTone.success);
    });
  });

  group('HomeProgressMapper.buildMuscleGroupProgressItems', () {
    test('builds progress items with completion badge and success tone', () {
      final homeState = buildHomeState(
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
      );

      final exerciseState = ExercisesLoaded(
        <dynamic>[
          _TestExercise(
            id: 'exercise-1',
            muscleGroups: const <String>['chest'],
          ),
          _TestExercise(
            id: 'exercise-2',
            muscleGroups: const <String>['quads'],
          ),
        ],
      );

      final items = HomeProgressMapper.buildMuscleGroupProgressItems(
        homeState: homeState,
        exerciseState: exerciseState,
      );

      expect(items, hasLength(2));

      final chest = items.firstWhere((item) => item.categoryKey == 'chest');
      expect(chest.progressLabel, '2 / 2 sets');
      expect(chest.percentageLabel, '100%');
      expect(chest.progressValue, 1.0);
      expect(chest.showCompleteBadge, isTrue);
      expect(chest.tone, MuscleGroupProgressTone.success);

      final quads = items.firstWhere((item) => item.categoryKey == 'quads');
      expect(quads.progressLabel, '1 / 3 sets');
      expect(quads.percentageLabel, '33%');
      expect(quads.progressValue, closeTo(0.3333, 0.001));
      expect(quads.showCompleteBadge, isFalse);
      expect(quads.tone, MuscleGroupProgressTone.primary);
    });

    test('returns empty breakdown-driven values when exercises are not loaded', () {
      final homeState = buildHomeState(
        targets: <Target>[
          buildTrainingTarget(
            id: 'target-1',
            categoryKey: 'chest',
            targetValue: 4,
          ),
        ],
        weeklySets: <WorkoutSet>[
          buildWorkoutSet(id: 'set-1', exerciseId: 'exercise-1'),
        ],
      );

      final items = HomeProgressMapper.buildMuscleGroupProgressItems(
        homeState: homeState,
        exerciseState: ExerciseInitial(),
      );

      expect(items, hasLength(1));
      expect(items.single.progressLabel, '0 / 4 sets');
      expect(items.single.percentageLabel, '0%');
      expect(items.single.progressValue, 0);
      expect(items.single.showCompleteBadge, isFalse);
      expect(items.single.tone, MuscleGroupProgressTone.primary);
    });
  });
}

class _TestExercise {
  final String id;
  final List<String> muscleGroups;

  const _TestExercise({
    required this.id,
    required this.muscleGroups,
  });
}