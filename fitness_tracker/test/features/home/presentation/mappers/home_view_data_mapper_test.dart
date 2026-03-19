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
    required List<NutritionLog> todaysLogs,
    required Map<String, double> dailyMacros,
    required List<Exercise> exercises,
  }) {
    return HomeLoaded(
      targets: targets,
      weeklySets: weeklySets,
      todaysLogs: todaysLogs,
      dailyMacros: dailyMacros,
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

  Target buildMacroTarget({
    required String id,
    required String categoryKey,
    required double targetValue,
  }) {
    return Target(
      id: id,
      type: TargetType.macro,
      categoryKey: categoryKey,
      targetValue: targetValue,
      unit: 'g',
      period: TargetPeriod.daily,
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

  NutritionLog buildNutritionLog({
    required String id,
    required String mealName,
    required double protein,
    required double carbs,
    required double fats,
    required double calories,
    bool isMealLog = true,
  }) {
    return NutritionLog(
      id: id,
      mealName: mealName,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fats,
      calories: calories,
      createdAt: createdAt,
      isMealLog: isMealLog,
    );
  }

  MuscleVisualLoaded buildMuscleVisualLoaded({
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

  group('HomeViewDataMapper.map', () {
    test('builds full page view data from loaded home and loaded visuals', () {
      final HomeLoaded homeState = buildHomeState(
        targets: <Target>[
          buildTrainingTarget(
            id: 'training-1',
            categoryKey: 'chest',
            targetValue: 4,
          ),
          buildMacroTarget(
            id: 'macro-1',
            categoryKey: 'protein',
            targetValue: 180,
          ),
        ],
        weeklySets: <WorkoutSet>[
          buildWorkoutSet(id: 'set-1', exerciseId: 'exercise-1'),
          buildWorkoutSet(id: 'set-2', exerciseId: 'exercise-1'),
          buildWorkoutSet(id: 'set-3', exerciseId: 'exercise-1'),
        ],
        todaysLogs: <NutritionLog>[
          buildNutritionLog(
            id: 'log-1',
            mealName: 'Chicken Bowl',
            protein: 45,
            carbs: 60,
            fats: 12,
            calories: 520,
          ),
        ],
        dailyMacros: const <String, double>{
          'protein': 120,
          'carbs': 210,
          'fats': 55,
          'calories': 1850,
        },
        exercises: <Exercise>[
          buildExercise(
            id: 'exercise-1',
            muscleGroups: const <String>['chest'],
          ),
        ],
      );

      final MuscleVisualLoaded visualState = buildMuscleVisualLoaded(
        period: TimePeriod.week,
        muscleData: <String, MuscleVisualData>{
          'chest': const MuscleVisualData(
            muscleGroup: 'chest',
            totalStimulus: 18,
            visualIntensity: 0.8,
            color: Colors.red,
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

      expect(result.greeting, contains('Hello'));
      expect(result.progress.title, 'Progress • Week');
      expect(result.progress.selectedPeriod, TimePeriod.week);
      expect(result.progress.selectorEnabled, isTrue);
      expect(result.progress.totalSetsLabel, '3');
      expect(result.progress.remainingTargetLabel, '1');
      expect(result.progress.trainedMusclesLabel, '1');
      expect(result.progress.targetTone, HomeTone.warning);
      expect(result.progress.isLoading, isFalse);
      expect(result.progress.errorMessage, isNull);

      expect(result.nutrition.totalCaloriesLabel, '1850 kcal');
      expect(result.nutrition.macros.first.label, 'Protein');
      expect(result.nutrition.macros.first.progressLabel, '120 / 180 g');
      expect(result.nutrition.recentEntries.single.title, 'Chicken Bowl');

      expect(result.showMuscleGroups, isTrue);
      expect(result.muscleGroups, hasLength(1));
      expect(result.muscleGroups.single.title, 'Chest');
      expect(result.muscleGroups.single.progressLabel, '3 / 4 sets');
      expect(result.muscleGroups.single.percentageLabel, '75%');

      expect(result.progress.muscleSummary, hasLength(1));
      expect(result.progress.muscleSummary.single.displayName, 'Chest');
    });

    test('hides target label and mutes target tone outside weekly period', () {
      final HomeLoaded homeState = buildHomeState(
        targets: <Target>[
          buildTrainingTarget(
            id: 'training-1',
            categoryKey: 'chest',
            targetValue: 4,
          ),
        ],
        weeklySets: <WorkoutSet>[
          buildWorkoutSet(id: 'set-1', exerciseId: 'exercise-1'),
          buildWorkoutSet(id: 'set-2', exerciseId: 'exercise-1'),
        ],
        todaysLogs: const <NutritionLog>[],
        dailyMacros: const <String, double>{},
        exercises: <Exercise>[
          buildExercise(
            id: 'exercise-1',
            muscleGroups: const <String>['chest'],
          ),
        ],
      );

      final MuscleVisualLoaded visualState = buildMuscleVisualLoaded(
        period: TimePeriod.month,
        muscleData: <String, MuscleVisualData>{
          'chest': const MuscleVisualData(
            muscleGroup: 'chest',
            totalStimulus: 24,
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

      expect(result.progress.title, 'Progress • Month');
      expect(result.progress.selectedPeriod, TimePeriod.month);
      expect(result.progress.remainingTargetLabel, '-');
      expect(result.progress.targetTone, HomeTone.muted);
    });

    test('returns loading progress card while visuals are loading', () {
      final HomeLoaded homeState = buildHomeState(
        targets: <Target>[
          buildTrainingTarget(
            id: 'training-1',
            categoryKey: 'chest',
            targetValue: 4,
          ),
        ],
        weeklySets: <WorkoutSet>[
          buildWorkoutSet(id: 'set-1', exerciseId: 'exercise-1'),
        ],
        todaysLogs: const <NutritionLog>[],
        dailyMacros: const <String, double>{},
        exercises: <Exercise>[
          buildExercise(
            id: 'exercise-1',
            muscleGroups: const <String>['chest'],
          ),
        ],
      );

      final HomePageViewData result = HomeViewDataMapper.map(
        homeState: homeState,
        muscleVisualState: const MuscleVisualLoading(TimePeriod.week),
        settings: settings,
      );

      expect(result.progress.title, 'Progress • Week');
      expect(result.progress.selectedPeriod, TimePeriod.week);
      expect(result.progress.selectorEnabled, isFalse);
      expect(result.progress.isLoading, isTrue);
      expect(result.progress.errorMessage, isNull);
      expect(result.progress.totalSetsLabel, '1');
      expect(result.progress.remainingTargetLabel, '3');
    });

    test('returns error progress card while preserving computed totals', () {
      final HomeLoaded homeState = buildHomeState(
        targets: <Target>[
          buildTrainingTarget(
            id: 'training-1',
            categoryKey: 'chest',
            targetValue: 4,
          ),
        ],
        weeklySets: <WorkoutSet>[
          buildWorkoutSet(id: 'set-1', exerciseId: 'exercise-1'),
          buildWorkoutSet(id: 'set-2', exerciseId: 'exercise-1'),
        ],
        todaysLogs: const <NutritionLog>[],
        dailyMacros: const <String, double>{},
        exercises: <Exercise>[
          buildExercise(
            id: 'exercise-1',
            muscleGroups: const <String>['chest'],
          ),
        ],
      );

      final HomePageViewData result = HomeViewDataMapper.map(
        homeState: homeState,
        muscleVisualState: const MuscleVisualError(
          message: 'visuals failed',
          period: TimePeriod.week,
        ),
        settings: settings,
      );

      expect(result.progress.selectedPeriod, TimePeriod.week);
      expect(result.progress.selectorEnabled, isTrue);
      expect(result.progress.isLoading, isFalse);
      expect(result.progress.errorMessage, 'visuals failed');
      expect(result.progress.totalSetsLabel, '2');
      expect(result.progress.remainingTargetLabel, '2');
    });

    test('builds completed muscle group progress with success tone', () {
      final HomeLoaded homeState = buildHomeState(
        targets: <Target>[
          buildTrainingTarget(
            id: 'training-1',
            categoryKey: 'chest',
            targetValue: 2,
          ),
        ],
        weeklySets: <WorkoutSet>[
          buildWorkoutSet(id: 'set-1', exerciseId: 'exercise-1'),
          buildWorkoutSet(id: 'set-2', exerciseId: 'exercise-1'),
          buildWorkoutSet(id: 'set-3', exerciseId: 'exercise-1'),
        ],
        todaysLogs: const <NutritionLog>[],
        dailyMacros: const <String, double>{},
        exercises: <Exercise>[
          buildExercise(
            id: 'exercise-1',
            muscleGroups: const <String>['chest'],
          ),
        ],
      );

      final HomePageViewData result = HomeViewDataMapper.map(
        homeState: homeState,
        muscleVisualState: const MuscleVisualInitial(),
        settings: settings,
      );

      expect(result.muscleGroups.single.progressValue, 1.0);
      expect(result.muscleGroups.single.percentageLabel, '100%');
      expect(result.muscleGroups.single.isComplete, isTrue);
      expect(result.muscleGroups.single.tone, HomeTone.success);
    });
  });
}