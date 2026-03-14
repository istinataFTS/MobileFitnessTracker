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
    final trainedMuscles = muscleState.trainedMuscleCount;

    if (muscleState.currentPeriod == TimePeriod.week) {
      return HomeProgressStatsViewData(
        totalSets: homeState.stats.totalWeeklySets,
        remainingTarget: homeState.stats.remainingTarget,
        trainedMuscles: trainedMuscles,
        hasTarget: homeState.stats.hasTargets,
      );
    }

    return HomeProgressStatsViewData(
      totalSets: homeState.stats.totalWeeklySets,
      remainingTarget: 0,
      trainedMuscles: trainedMuscles,
      hasTarget: homeState.stats.hasTargets,
    );
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