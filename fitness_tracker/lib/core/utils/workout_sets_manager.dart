import 'package:flutter/foundation.dart';
import '../../domain/entities/workout_set.dart';
import '../constants/muscle_groups.dart';
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
    required String muscleGroup,
    required String exerciseName,
    required int reps,
    required double weight,
    DateTime? date,
  }) {
    if (!MuscleGroups.isValid(muscleGroup)) return;

    final set = WorkoutSet(
      id: _uuid.v4(),
      muscleGroup: muscleGroup,
      exerciseName: exerciseName,
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

  // Get sets for a specific muscle group
  List<WorkoutSet> getSetsForMuscle(String muscleGroup) {
    return _sets.where((set) => set.muscleGroup == muscleGroup).toList();
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

  // Get weekly progress for a specific muscle
  int getWeeklySetsForMuscle(String muscleGroup) {
    final weeklySets = getSetsForCurrentWeek();
    return weeklySets.where((set) => set.muscleGroup == muscleGroup).length;
  }

  // Get total weekly sets
  int get totalWeeklySets {
    return getSetsForCurrentWeek().length;
  }

  // Get sets grouped by date
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

  // Get sets for a specific date
  List<WorkoutSet> getSetsForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return _sets.where((set) {
      final setDate = DateTime(set.date.year, set.date.month, set.date.day);
      return setDate == targetDate;
    }).toList();
  }
}