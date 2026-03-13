import 'package:fitness_tracker/domain/entities/nutrition_log.dart';
import 'package:fitness_tracker/domain/entities/workout_set.dart';
import 'package:fitness_tracker/presentation/pages/history/utils/history_activity_aggregator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HistoryActivityAggregator', () {
    final targetDate = DateTime(2024, 1, 15);

    WorkoutSet buildWorkoutSet({
      required String id,
      required DateTime date,
    }) {
      return WorkoutSet(
        id: id,
        exerciseId: 'exercise-1',
        reps: 10,
        weight: 80,
        date: date,
        createdAt: date.add(const Duration(hours: 1)),
      );
    }

    NutritionLog buildNutritionLog({
      required String id,
      required DateTime loggedAt,
    }) {
      return NutritionLog(
        id: id,
        mealName: 'Chicken and rice',
        proteinGrams: 40,
        carbsGrams: 60,
        fatGrams: 10,
        calories: 490,
        loggedAt: loggedAt,
        createdAt: loggedAt.add(const Duration(minutes: 30)),
      );
    }

    test('normalizes dates to day precision', () {
      final normalized = HistoryActivityAggregator.normalizeDate(
        DateTime(2024, 1, 15, 18, 45, 12),
      );

      expect(normalized, DateTime(2024, 1, 15));
    });

    test('returns combined activity count for a given date', () {
      final monthSets = <DateTime, List<WorkoutSet>>{
        targetDate: [
          buildWorkoutSet(id: 'set-1', date: targetDate),
          buildWorkoutSet(id: 'set-2', date: targetDate),
        ],
      };

      final monthNutritionLogs = <DateTime, List<NutritionLog>>{
        targetDate: [
          buildNutritionLog(id: 'log-1', loggedAt: targetDate),
        ],
      };

      final count = HistoryActivityAggregator.getActivityCountForDate(
        monthSets: monthSets,
        monthNutritionLogs: monthNutritionLogs,
        date: DateTime(2024, 1, 15, 22, 10),
      );

      expect(count, 3);
    });

    test('builds merged activity counts for calendar display', () {
      final secondDate = DateTime(2024, 1, 16);

      final monthSets = <DateTime, List<WorkoutSet>>{
        targetDate: [
          buildWorkoutSet(id: 'set-1', date: targetDate),
        ],
        secondDate: [
          buildWorkoutSet(id: 'set-2', date: secondDate),
          buildWorkoutSet(id: 'set-3', date: secondDate),
        ],
      };

      final monthNutritionLogs = <DateTime, List<NutritionLog>>{
        targetDate: [
          buildNutritionLog(id: 'log-1', loggedAt: targetDate),
          buildNutritionLog(id: 'log-2', loggedAt: targetDate),
        ],
      };

      final result = HistoryActivityAggregator.buildActivityCounts(
        monthSets: monthSets,
        monthNutritionLogs: monthNutritionLogs,
      );

      expect(result[targetDate], 3);
      expect(result[secondDate], 2);
    });

    test('returns zero when a date has no activity', () {
      final count = HistoryActivityAggregator.getActivityCountForDate(
        monthSets: const {},
        monthNutritionLogs: const {},
        date: targetDate,
      );

      expect(count, 0);
    });
  });
}