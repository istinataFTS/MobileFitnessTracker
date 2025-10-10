import 'package:flutter/foundation.dart';
import '../../domain/entities/workout_set.dart';
import 'exercises_manager.dart';
import 'package:uuid/uuid.dart';

/// Simple state management for workout sets
class WorkoutSetsManager extends ChangeNotifier {
  static final WorkoutSetsManager _instance = WorkoutSetsManager._internal();
  factory WorkoutSetsManager() => _instance;
  WorkoutSetsManager._internal();

  final List<WorkoutSet> _sets = [];
  final _uuid = const Uuid();

  List<WorkoutSet> get allSets => List.unmodifiable(_sets);

  void addSet({
    required String exerciseId,
    required int reps,
    required double weight,
    DateTime? date,
  }) {
    final set = WorkoutSet(
      id: _uuid.v4(),
      exerciseId: exerciseId,
      reps: reps,
      weight: weight,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
    );

    _sets.add(set);
    notifyListeners();
  }

  void removeSet(String setId) {
    _sets.removeWhere((set) => set.id == setId);
    notifyListeners();
  }

  void clearAllSets() {
    _sets.clear();
    notifyListeners();
  }

  // Get sets for a specific exercise
  List<WorkoutSet> getSetsForExercise(String exerciseId) {
    return _sets.where((set) => set.exerciseId == exerciseId).toList();
  }

  // Get sets for current week
  List<WorkoutSet> getSetsForCurrentWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    return _sets.where((set) {
      final setDate = DateTime(set.date.year, set.date.month, set.date.day);
      return setDate.isAfter(weekStartDate.subtract(const Duration(days: 1)));
    }).toList();
  }

  /// Get weekly sets count for a specific muscle group
  /// This counts ALL sets from exercises that work this muscle
  int getWeeklySetsForMuscle(String muscleGroup) {
    final weeklySets = getSetsForCurrentWeek();
    final exercisesManager = ExercisesManager();
    
    int count = 0;
    for (final set in weeklySets) {
      final exercise = exercisesManager.getExerciseById(set.exerciseId);
      if (exercise != null && exercise.muscleGroups.contains(muscleGroup)) {
        count++;
      }
    }
    
    return count;
  }

  /// Get total weekly sets across all muscles
  int get totalWeeklySets {
    return getSetsForCurrentWeek().length;
  }

  /// Get sets grouped by date
  Map<DateTime, List<WorkoutSet>> getSetsGroupedByDate() {
    final Map<DateTime, List<WorkoutSet>> grouped = {};
    
    for (final set in _sets) {
      final date = DateTime(set.date.year, set.date.month, set.date.day);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(set);
    }
    
    return grouped;
  }

  /// Get sets for a specific date
  List<WorkoutSet> getSetsForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return _sets.where((set) {
      final setDate = DateTime(set.date.year, set.date.month, set.date.day);
      return setDate == targetDate;
    }).toList();
  }

  /// Get muscle groups breakdown for weekly sets
  /// Returns map of muscle group -> set count
  Map<String, int> getWeeklyMuscleBreakdown() {
    final weeklySets = getSetsForCurrentWeek();
    final exercisesManager = ExercisesManager();
    final Map<String, int> breakdown = {};
    
    for (final set in weeklySets) {
      final exercise = exercisesManager.getExerciseById(set.exerciseId);
      if (exercise != null) {
        for (final muscleGroup in exercise.muscleGroups) {
          breakdown[muscleGroup] = (breakdown[muscleGroup] ?? 0) + 1;
        }
      }
    }
    
    return breakdown;
  }
}