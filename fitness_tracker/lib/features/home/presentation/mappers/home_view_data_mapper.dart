import 'package:flutter/material.dart';

import '../../../../config/env_config.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/muscle_groups.dart';
import '../../../../core/utils/week_range_label_formatter.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/entities/exercise.dart';
import '../../../../domain/entities/muscle_visual_data.dart';
import '../../../../domain/entities/nutrition_log.dart';
import '../../../../domain/entities/target.dart';
import '../../../../domain/entities/time_period.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../application/models/home_dashboard_data.dart';
import '../../application/muscle_visual_bloc.dart';
import '../models/home_view_data.dart';

class HomeViewDataMapper {
  const HomeViewDataMapper._();

  static HomePageViewData map({
    required HomeDashboardData homeData,
    required MuscleVisualState muscleVisualState,
    required AppSettings settings,
  }) {
    final List<Target> trainingTargets = _filterTrainingTargets(homeData.targets);
    final List<Target> macroTargets = _filterMacroTargets(homeData.targets);
    final TimePeriod currentPeriod = _resolveCurrentPeriod(muscleVisualState);

    return HomePageViewData(
      greeting: '${AppStrings.hello}, ${EnvConfig.userName}!',
      weekRangeLabel: WeekRangeLabelFormatter.formatForDate(
        DateTime.now(),
        weekStartDay: settings.weekStartDay,
      ),
      nutrition: _mapNutrition(
        macroTargets: macroTargets,
        dailyMacros: homeData.dailyMacros,
        todaysLogs: homeData.todaysLogs,
      ),
      progress: _mapProgress(
        weeklySets: homeData.weeklySets,
        trainingTargets: trainingTargets,
        muscleVisualState: muscleVisualState,
        currentPeriod: currentPeriod,
      ),
      muscleGroups: _mapMuscleGroupProgress(
        targets: trainingTargets,
        weeklySets: homeData.weeklySets,
        exercises: homeData.exercises,
      ),
      showMuscleGroups: trainingTargets.isNotEmpty,
    );
  }

  static List<Target> _filterTrainingTargets(List<Target> targets) {
    return targets
        .where((Target target) => target.isWeeklyMuscleTarget)
        .toList(growable: false);
  }

  static List<Target> _filterMacroTargets(List<Target> targets) {
    return targets
        .where((Target target) => target.isDailyMacroTarget)
        .toList(growable: false);
  }

  static TimePeriod _resolveCurrentPeriod(MuscleVisualState muscleVisualState) {
    if (muscleVisualState is MuscleVisualLoaded) {
      return muscleVisualState.currentPeriod;
    }

    if (muscleVisualState is MuscleVisualLoading) {
      return muscleVisualState.period;
    }

    if (muscleVisualState is MuscleVisualError) {
      return muscleVisualState.period;
    }

    return TimePeriod.week;
  }

  static HomeNutritionCardViewData _mapNutrition({
    required List<Target> macroTargets,
    required Map<String, double> dailyMacros,
    required List<NutritionLog> todaysLogs,
  }) {
    final Map<String, double> targetMap = <String, double>{
      for (final Target target in macroTargets)
        target.categoryKey: target.targetValue,
    };

    return HomeNutritionCardViewData(
      totalCaloriesLabel: '${(dailyMacros['calories'] ?? 0).round()} kcal',
      macros: <HomeMacroProgressViewData>[
        _buildMacroProgress(
          label: 'Protein',
          unit: 'g',
          actual: dailyMacros['protein'] ?? 0,
          target: targetMap['protein'] ?? 0,
        ),
        _buildMacroProgress(
          label: 'Carbs',
          unit: 'g',
          actual: dailyMacros['carbs'] ?? 0,
          target: targetMap['carbs'] ?? 0,
        ),
        _buildMacroProgress(
          label: 'Fats',
          unit: 'g',
          actual: dailyMacros['fats'] ?? 0,
          target: targetMap['fats'] ?? 0,
        ),
      ],
      recentEntries: todaysLogs
          .take(3)
          .map(
            (NutritionLog log) => HomeRecentNutritionEntryViewData(
              title: log.mealName,
              subtitle:
                  '${log.proteinGrams.toStringAsFixed(0)}P • '
                  '${log.carbsGrams.toStringAsFixed(0)}C • '
                  '${log.fatGrams.toStringAsFixed(0)}F • '
                  '${log.calories.round()} kcal',
              isMealLog: log.isMealLog,
            ),
          )
          .toList(growable: false),
      hasEntries: todaysLogs.isNotEmpty,
    );
  }

  static HomeMacroProgressViewData _buildMacroProgress({
    required String label,
    required String unit,
    required double actual,
    required double target,
  }) {
    final bool hasTarget = target > 0;
    final bool isComplete = hasTarget && actual >= target;
    final double progressValue =
        hasTarget ? (actual / target).clamp(0.0, 1.0) : 0.0;
    final double remaining =
        hasTarget ? (target - actual).clamp(0.0, target) : 0.0;

    return HomeMacroProgressViewData(
      label: label,
      progressLabel: hasTarget
          ? '${actual.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit'
          : '${actual.toStringAsFixed(0)} $unit',
      trailingLabel: hasTarget
          ? (isComplete ? 'Done' : '${remaining.toStringAsFixed(0)} $unit left')
          : 'No target',
      progressValue: progressValue,
      hasTarget: hasTarget,
      isComplete: isComplete,
    );
  }

  static HomeProgressCardViewData _mapProgress({
    required List<WorkoutSet> weeklySets,
    required List<Target> trainingTargets,
    required MuscleVisualState muscleVisualState,
    required TimePeriod currentPeriod,
  }) {
    final int totalSets = weeklySets.length;
    final int totalTarget = trainingTargets.fold<int>(
      0,
      (int sum, Target target) => sum + target.weeklyGoal,
    );
    final int remainingTarget = (totalTarget - totalSets).clamp(0, totalTarget);
    final bool selectorEnabled = muscleVisualState is! MuscleVisualLoading;

    if (muscleVisualState is MuscleVisualLoading ||
        muscleVisualState is MuscleVisualInitial) {
      return HomeProgressCardViewData(
        title: '${AppStrings.progress} • ${_periodLabel(currentPeriod)}',
        selectedPeriod: currentPeriod,
        selectorEnabled: selectorEnabled,
        totalSetsLabel: totalSets.toString(),
        remainingTargetLabel:
            totalTarget > 0 ? remainingTarget.toString() : '-',
        trainedMusclesLabel: '-',
        targetTone: _targetTone(
          remainingTarget,
          showTarget: totalTarget > 0 && currentPeriod == TimePeriod.week,
        ),
        muscleSummary: const <HomeMuscleSummaryItemViewData>[],
        isLoading: true,
        errorMessage: null,
      );
    }

    if (muscleVisualState is MuscleVisualError) {
      return HomeProgressCardViewData(
        title: '${AppStrings.progress} • ${_periodLabel(currentPeriod)}',
        selectedPeriod: currentPeriod,
        selectorEnabled: selectorEnabled,
        totalSetsLabel: totalSets.toString(),
        remainingTargetLabel:
            totalTarget > 0 && currentPeriod == TimePeriod.week
                ? remainingTarget.toString()
                : '-',
        trainedMusclesLabel: '-',
        targetTone: _targetTone(
          remainingTarget,
          showTarget: totalTarget > 0 && currentPeriod == TimePeriod.week,
        ),
        muscleSummary: const <HomeMuscleSummaryItemViewData>[],
        isLoading: false,
        errorMessage: muscleVisualState.message,
      );
    }

    final MuscleVisualLoaded loaded = muscleVisualState as MuscleVisualLoaded;
    final bool showTarget =
        loaded.currentPeriod == TimePeriod.week && totalTarget > 0;

    final List<MuscleVisualData> trained = loaded.muscleData.values
        .where(
          (MuscleVisualData item) => item.hasTrained && item.totalStimulus > 0,
        )
        .toList()
      ..sort(
        (MuscleVisualData a, MuscleVisualData b) =>
            b.totalStimulus.compareTo(a.totalStimulus),
      );

    return HomeProgressCardViewData(
      title: '${AppStrings.progress} • ${_periodLabel(currentPeriod)}',
      selectedPeriod: currentPeriod,
      selectorEnabled: selectorEnabled,
      totalSetsLabel: totalSets.toString(),
      remainingTargetLabel: showTarget ? remainingTarget.toString() : '-',
      trainedMusclesLabel: loaded.trainedMuscleCount.toString(),
      targetTone: _targetTone(remainingTarget, showTarget: showTarget),
      muscleSummary: trained
          .take(6)
          .map(
            (MuscleVisualData item) => HomeMuscleSummaryItemViewData(
              displayName: item.displayName,
              stimulusLabel: item.totalStimulus.toStringAsFixed(0),
              intensityLabel: item.intensityLevel,
              color: item.color,
            ),
          )
          .toList(growable: false),
      isLoading: false,
      errorMessage: null,
    );
  }

  static HomeTone _targetTone(
    int remainingTarget, {
    required bool showTarget,
  }) {
    if (!showTarget) {
      return HomeTone.muted;
    }

    if (remainingTarget <= 0) {
      return HomeTone.success;
    }

    if (remainingTarget <= 3) {
      return HomeTone.warning;
    }

    return HomeTone.primary;
  }

  static List<HomeMuscleGroupProgressViewData> _mapMuscleGroupProgress({
    required List<Target> targets,
    required List<WorkoutSet> weeklySets,
    required List<Exercise> exercises,
  }) {
    final Map<String, int> breakdown = _buildMuscleBreakdown(
      weeklySets: weeklySets,
      exercises: exercises,
    );

    return targets.map((Target target) {
      final int currentSets = breakdown[target.categoryKey] ?? 0;
      final int targetSets = target.weeklyGoal;
      final double rawProgress = targetSets > 0 ? currentSets / targetSets : 0;
      final double progressValue = rawProgress.clamp(0.0, 1.0);
      final int percentage = (rawProgress * 100).clamp(0, 100).toInt();
      final bool isComplete = targetSets > 0 && currentSets >= targetSets;

      return HomeMuscleGroupProgressViewData(
        title: MuscleGroups.getDisplayName(target.categoryKey),
        progressLabel: '$currentSets / $targetSets ${AppStrings.sets}',
        percentageLabel: '$percentage%',
        progressValue: progressValue,
        isComplete: isComplete,
        tone: isComplete ? HomeTone.success : HomeTone.primary,
      );
    }).toList(growable: false);
  }

  static Map<String, int> _buildMuscleBreakdown({
    required List<WorkoutSet> weeklySets,
    required List<Exercise> exercises,
  }) {
    final Map<String, int> result = <String, int>{};
    final Map<String, Exercise> exercisesById = <String, Exercise>{
      for (final Exercise exercise in exercises) exercise.id: exercise,
    };

    for (final WorkoutSet set in weeklySets) {
      final Exercise? exercise = exercisesById[set.exerciseId];
      if (exercise == null) {
        continue;
      }

      for (final String muscle in exercise.muscleGroups) {
        if (!MuscleGroups.isValid(muscle)) {
          continue;
        }

        result[muscle] = (result[muscle] ?? 0) + 1;
      }
    }

    return result;
  }

  static String _periodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.today:
        return AppStrings.periodToday;
      case TimePeriod.week:
        return AppStrings.periodWeek;
      case TimePeriod.month:
        return AppStrings.periodMonth;
      case TimePeriod.allTime:
        return AppStrings.periodAllTime;
    }
  }
}