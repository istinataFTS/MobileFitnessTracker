import 'package:flutter/foundation.dart';
import '../constants/muscle_groups.dart';

/// Simple state management for weekly goals
/// For now, using in-memory storage (will persist in final version)
class GoalsManager extends ChangeNotifier {
  static final GoalsManager _instance = GoalsManager._internal();
  factory GoalsManager() => _instance;
  GoalsManager._internal() {
    _goals = Map.from(MuscleGroups.defaultWeeklyGoals);
  }

  Map<String, int> _goals = {};

  Map<String, int> get goals => Map.unmodifiable(_goals);

  int getGoal(String muscleGroup) {
    return _goals[muscleGroup] ?? MuscleGroups.getDefaultGoal(muscleGroup);
  }

  void updateGoal(String muscleGroup, int sets) {
    _goals[muscleGroup] = sets;
    notifyListeners();
  }

  void updateAllGoals(Map<String, int> newGoals) {
    _goals = Map.from(newGoals);
    notifyListeners();
  }

  void resetToDefaults() {
    _goals = Map.from(MuscleGroups.defaultWeeklyGoals);
    notifyListeners();
  }

  int get totalWeeklyGoal {
    return _goals.values.fold(0, (sum, goal) => sum + goal);
  }
}