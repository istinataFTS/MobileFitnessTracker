import '../../../../domain/entities/nutrition_log.dart';
import '../../../../domain/entities/workout_set.dart';
import '../models/day_activity.dart';

/// Aggregates per-day workout and nutrition activity for the history calendar.
///
/// The calendar renders one dot per activity *type* (yellow for exercise,
/// green for nutrition), so the aggregator returns counts split by type via
/// [DayActivity] rather than a single combined integer.
///
/// Workout sets can become orphaned when their [WorkoutSet.exerciseId] no
/// longer resolves to an [Exercise] in the library (e.g. the exercise was
/// deleted). The day-detail view filters those out and shows an "unavailable"
/// fallback, so the calendar must do the same — otherwise a dot promises
/// data the user can't actually open. Pass [resolvableExerciseIds] to gate
/// the workout count; pass `null` while the exercise list is still loading
/// to fall back to counting every set (avoids an empty-then-populated flash
/// during boot).
class HistoryActivityAggregator {
  const HistoryActivityAggregator._();

  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DayActivity getActivityForDate({
    required Map<DateTime, List<WorkoutSet>> monthSets,
    required Map<DateTime, List<NutritionLog>> monthNutritionLogs,
    required DateTime date,
    Set<String>? resolvableExerciseIds,
  }) {
    final DateTime normalizedDate = normalizeDate(date);

    final int exerciseSets = _countResolvableSets(
      monthSets[normalizedDate],
      resolvableExerciseIds,
    );
    final int nutritionLogs = monthNutritionLogs[normalizedDate]?.length ?? 0;

    return DayActivity(
      exerciseSets: exerciseSets,
      nutritionLogs: nutritionLogs,
    );
  }

  static Map<DateTime, DayActivity> buildActivityCounts({
    required Map<DateTime, List<WorkoutSet>> monthSets,
    required Map<DateTime, List<NutritionLog>> monthNutritionLogs,
    Set<String>? resolvableExerciseIds,
  }) {
    final Map<DateTime, int> exerciseByDate = <DateTime, int>{};
    final Map<DateTime, int> nutritionByDate = <DateTime, int>{};

    for (final MapEntry<DateTime, List<WorkoutSet>> entry
        in monthSets.entries) {
      final int count = _countResolvableSets(
        entry.value,
        resolvableExerciseIds,
      );
      if (count == 0) continue;
      final DateTime normalizedDate = normalizeDate(entry.key);
      exerciseByDate.update(
        normalizedDate,
        (int current) => current + count,
        ifAbsent: () => count,
      );
    }

    for (final MapEntry<DateTime, List<NutritionLog>> entry
        in monthNutritionLogs.entries) {
      if (entry.value.isEmpty) continue;
      final DateTime normalizedDate = normalizeDate(entry.key);
      nutritionByDate.update(
        normalizedDate,
        (int current) => current + entry.value.length,
        ifAbsent: () => entry.value.length,
      );
    }

    final Set<DateTime> allDates = <DateTime>{
      ...exerciseByDate.keys,
      ...nutritionByDate.keys,
    };

    return <DateTime, DayActivity>{
      for (final DateTime date in allDates)
        date: DayActivity(
          exerciseSets: exerciseByDate[date] ?? 0,
          nutritionLogs: nutritionByDate[date] ?? 0,
        ),
    };
  }

  static int _countResolvableSets(
    List<WorkoutSet>? sets,
    Set<String>? resolvableExerciseIds,
  ) {
    if (sets == null || sets.isEmpty) return 0;
    if (resolvableExerciseIds == null) return sets.length;
    int count = 0;
    for (final WorkoutSet set in sets) {
      if (resolvableExerciseIds.contains(set.exerciseId)) count++;
    }
    return count;
  }
}
