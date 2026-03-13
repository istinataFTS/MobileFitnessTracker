import '../../../../domain/entities/nutrition_log.dart';
import '../../../../domain/entities/workout_set.dart';

class HistoryActivityAggregator {
  const HistoryActivityAggregator._();

  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int getActivityCountForDate({
    required Map<DateTime, List<WorkoutSet>> monthSets,
    required Map<DateTime, List<NutritionLog>> monthNutritionLogs,
    required DateTime date,
  }) {
    final normalizedDate = normalizeDate(date);

    return (monthSets[normalizedDate]?.length ?? 0) +
        (monthNutritionLogs[normalizedDate]?.length ?? 0);
  }

  static Map<DateTime, int> buildActivityCounts({
    required Map<DateTime, List<WorkoutSet>> monthSets,
    required Map<DateTime, List<NutritionLog>> monthNutritionLogs,
  }) {
    final activityCounts = <DateTime, int>{};

    for (final entry in monthSets.entries) {
      final normalizedDate = normalizeDate(entry.key);
      activityCounts.update(
        normalizedDate,
        (current) => current + entry.value.length,
        ifAbsent: () => entry.value.length,
      );
    }

    for (final entry in monthNutritionLogs.entries) {
      final normalizedDate = normalizeDate(entry.key);
      activityCounts.update(
        normalizedDate,
        (current) => current + entry.value.length,
        ifAbsent: () => entry.value.length,
      );
    }

    return activityCounts;
  }
}