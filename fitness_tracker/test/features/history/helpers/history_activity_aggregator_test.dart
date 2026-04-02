import 'package:fitness_tracker/domain/entities/nutrition_log.dart';
import 'package:fitness_tracker/domain/entities/workout_set.dart';
import 'package:fitness_tracker/features/history/presentation/helpers/history_activity_aggregator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime baseDate = DateTime(2026, 3, 18, 14, 30);

  WorkoutSet buildWorkoutSet({
    required String id,
    required DateTime date,
  }) {
    return WorkoutSet(
      id: id,
      exerciseId: 'exercise-$id',
      reps: 10,
      weight: 80,
      date: date,
      createdAt: date,
    );
  }

  NutritionLog buildNutritionLog({
    required String id,
    required DateTime date,
  }) {
    return NutritionLog(
      id: id,
      mealName: 'Meal $id',
      proteinGrams: 25,
      carbsGrams: 30,
      fatGrams: 10,
      calories: 310,
      loggedAt: date,
      createdAt: date,
    );
  }

  group('HistoryActivityAggregator', () {
    test('normalizeDate removes time information', () {
      final DateTime result = HistoryActivityAggregator.normalizeDate(baseDate);

      expect(result, DateTime(2026, 3, 18));
      expect(result.hour, 0);
      expect(result.minute, 0);
      expect(result.second, 0);
      expect(result.millisecond, 0);
      expect(result.microsecond, 0);
    });

    test('getActivityCountForDate returns combined workout and nutrition count', () {
      final DateTime selectedDate = DateTime(2026, 3, 18, 22, 10);

      final Map<DateTime, List<WorkoutSet>> monthSets = <DateTime, List<WorkoutSet>>{
        DateTime(2026, 3, 18): <WorkoutSet>[
          buildWorkoutSet(id: 'w1', date: DateTime(2026, 3, 18, 8, 0)),
          buildWorkoutSet(id: 'w2', date: DateTime(2026, 3, 18, 18, 0)),
        ],
      };

      final Map<DateTime, List<NutritionLog>> monthNutritionLogs =
          <DateTime, List<NutritionLog>>{
        DateTime(2026, 3, 18): <NutritionLog>[
          buildNutritionLog(id: 'n1', date: DateTime(2026, 3, 18, 12, 0)),
        ],
      };

      final int result = HistoryActivityAggregator.getActivityCountForDate(
        monthSets: monthSets,
        monthNutritionLogs: monthNutritionLogs,
        date: selectedDate,
      );

      expect(result, 3);
    });

    test('getActivityCountForDate returns zero when date has no activity', () {
      final int result = HistoryActivityAggregator.getActivityCountForDate(
        monthSets: const <DateTime, List<WorkoutSet>>{},
        monthNutritionLogs: const <DateTime, List<NutritionLog>>{},
        date: DateTime(2026, 3, 19, 9, 0),
      );

      expect(result, 0);
    });

    test('buildActivityCounts merges counts for the same normalized date', () {
      final Map<DateTime, List<WorkoutSet>> monthSets = <DateTime, List<WorkoutSet>>{
        DateTime(2026, 3, 18, 6, 30): <WorkoutSet>[
          buildWorkoutSet(id: 'w1', date: DateTime(2026, 3, 18, 6, 30)),
          buildWorkoutSet(id: 'w2', date: DateTime(2026, 3, 18, 19, 0)),
        ],
        DateTime(2026, 3, 19, 7, 0): <WorkoutSet>[
          buildWorkoutSet(id: 'w3', date: DateTime(2026, 3, 19, 7, 0)),
        ],
      };

      final Map<DateTime, List<NutritionLog>> monthNutritionLogs =
          <DateTime, List<NutritionLog>>{
        DateTime(2026, 3, 18, 12, 0): <NutritionLog>[
          buildNutritionLog(id: 'n1', date: DateTime(2026, 3, 18, 12, 0)),
          buildNutritionLog(id: 'n2', date: DateTime(2026, 3, 18, 20, 0)),
        ],
        DateTime(2026, 3, 20, 9, 15): <NutritionLog>[
          buildNutritionLog(id: 'n3', date: DateTime(2026, 3, 20, 9, 15)),
        ],
      };

      final Map<DateTime, int> result =
          HistoryActivityAggregator.buildActivityCounts(
        monthSets: monthSets,
        monthNutritionLogs: monthNutritionLogs,
      );

      expect(result, <DateTime, int>{
        DateTime(2026, 3, 18): 4,
        DateTime(2026, 3, 19): 1,
        DateTime(2026, 3, 20): 1,
      });
    });

    test('buildActivityCounts returns empty map when there is no activity', () {
      final Map<DateTime, int> result =
          HistoryActivityAggregator.buildActivityCounts(
        monthSets: const <DateTime, List<WorkoutSet>>{},
        monthNutritionLogs: const <DateTime, List<NutritionLog>>{},
      );

      expect(result, isEmpty);
    });
  });
}