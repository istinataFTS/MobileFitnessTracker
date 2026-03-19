import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/muscle_groups.dart';
import '../../../../domain/entities/time_period.dart';
import '../../../pages/exercises/bloc/exercise_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/muscle_visual_bloc.dart';
import '../models/home_progress_view_data.dart';

class HomeProgressMapper {
  const HomeProgressMapper._();

  static HomeProgressStatsViewData buildProgressStats({
    required HomeLoaded homeState,
    required MuscleVisualLoaded muscleState,
  }) {
    final int totalSets = homeState.stats.totalWeeklySets;
    final int trainedMuscles = muscleState.trainedMuscleCount;
    final bool showTarget =
        muscleState.currentPeriod == TimePeriod.week &&
            homeState.stats.hasTargets;

    final String targetValue =
        showTarget ? homeState.stats.remainingTarget.toString() : '-';

    final HomeProgressTone targetTone = showTarget
        ? _targetTone(homeState.stats.remainingTarget)
        : HomeProgressTone.muted;

    return HomeProgressStatsViewData(
      totalSetsStat: HomeProgressStatViewData(
        value: totalSets.toString(),
        label: AppStringsPhase7.sets,
        tone: totalSets > 0 ? HomeProgressTone.primary : HomeProgressTone.muted,
      ),
      targetStat: HomeProgressStatViewData(
        value: targetValue,
        label: AppStringsPhase7.target,
        tone: targetTone,
      ),
      trainedMusclesStat: HomeProgressStatViewData(
        value: trainedMuscles.toString(),
        label: AppStringsPhase7.muscles,
        tone: trainedMuscles > 0
            ? HomeProgressTone.primary
            : HomeProgressTone.muted,
      ),
    );
  }

  static DetailedHomeProgressStatsViewData buildDetailedProgressStats({
    required int totalSets,
    required int totalTarget,
    required int remainingTarget,
    required int trainedMuscles,
    int totalMuscles = 20,
    double progressPercentage = 0.0,
  }) {
    final double clampedProgress = progressPercentage.clamp(0.0, 1.0);
    final HomeProgressTone progressTone = _progressTone(clampedProgress);
    final bool targetMet = remainingTarget <= 0;

    return DetailedHomeProgressStatsViewData(
      progressValue: clampedProgress,
      progressLabel: '${(clampedProgress * 100).toStringAsFixed(0)}% Complete',
      progressTone: progressTone,
      completedSetsStat: HomeProgressStatViewData(
        value: '$totalSets / $totalTarget',
        label: 'Sets Completed',
        tone: HomeProgressTone.primary,
      ),
      trainedMusclesStat: HomeProgressStatViewData(
        value: '$trainedMuscles / $totalMuscles',
        label: 'Muscles Trained',
        tone: HomeProgressTone.primary,
      ),
      targetCallout: HomeProgressCalloutViewData(
        message: targetMet
            ? 'Target met! 🎉'
            : '$remainingTarget sets remaining',
        tone: _targetTone(remainingTarget),
      ),
    );
  }

  static List<MuscleGroupProgressItemViewData> buildMuscleGroupProgressItems({
    required HomeLoaded homeState,
    required ExerciseState exerciseState,
  }) {
    final muscleBreakdown = buildMuscleBreakdown(
      weeklySets: homeState.weeklySets,
      exerciseState: exerciseState,
    );

    return homeState.trainingTargets.map((target) {
      final int currentSets = muscleBreakdown[target.categoryKey] ?? 0;
      final int targetSets = target.weeklyGoal;

      final double rawProgress = targetSets > 0 ? currentSets / targetSets : 0.0;
      final double progressValue = rawProgress.clamp(0.0, 1.0);
      final int percentage = (rawProgress * 100).clamp(0, 100).toInt();
      final bool isComplete = targetSets > 0 && currentSets >= targetSets;

      return MuscleGroupProgressItemViewData(
        categoryKey: target.categoryKey,
        title: MuscleGroups.getDisplayName(target.categoryKey),
        progressLabel: '$currentSets / $targetSets ${AppStrings.sets}',
        percentageLabel: '$percentage%',
        progressValue: progressValue,
        showCompleteBadge: isComplete,
        tone: isComplete
            ? MuscleGroupProgressTone.success
            : MuscleGroupProgressTone.primary,
      );
    }).toList(growable: false);
  }

  static HomeProgressTone _targetTone(int remainingTarget) {
    if (remainingTarget <= 0) {
      return HomeProgressTone.success;
    }

    if (remainingTarget <= 3) {
      return HomeProgressTone.warning;
    }

    return HomeProgressTone.primary;
  }

  static HomeProgressTone _progressTone(double progressPercentage) {
    if (progressPercentage >= 1.0) {
      return HomeProgressTone.success;
    }

    if (progressPercentage >= 0.7) {
      return HomeProgressTone.primary;
    }

    return HomeProgressTone.warning;
  }

  static Map<String, int> buildMuscleBreakdown({
    required List weeklySets,
    required ExerciseState exerciseState,
  }) {
    final Map<String, int> muscleBreakdown = {};

    if (exerciseState is! ExercisesLoaded) {
      return muscleBreakdown;
    }

    final exercises = exerciseState.exercises;

    for (final set in weeklySets) {
      try {
        final exercise = exercises.firstWhere(
          (e) => e.id == set.exerciseId,
        );

        for (final muscleGroup in exercise.muscleGroups) {
          if (!MuscleGroups.isValid(muscleGroup)) {
            continue;
          }

          muscleBreakdown[muscleGroup] =
              (muscleBreakdown[muscleGroup] ?? 0) + 1;
        }
      } catch (_) {
        continue;
      }
    }

    return muscleBreakdown;
  }
}