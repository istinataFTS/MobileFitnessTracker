import 'package:flutter/foundation.dart';
import '../../domain/entities/target.dart';
import '../constants/muscle_groups.dart';
import 'package:uuid/uuid.dart';


class TargetsManager extends ChangeNotifier {
  static final TargetsManager _instance = TargetsManager._internal();
  factory TargetsManager() => _instance;
  TargetsManager._internal();

  final List<Target> _targets = [];
  final _uuid = const Uuid();

  List<Target> get targets => List.unmodifiable(_targets);

  bool hasTarget(String muscleGroup) {
    return _targets.any((t) => t.muscleGroup == muscleGroup);
  }

  Target? getTarget(String muscleGroup) {
    try {
      return _targets.firstWhere((t) => t.muscleGroup == muscleGroup);
    } catch (e) {
      return null;
    }
  }

  void addTarget(String muscleGroup, int weeklyGoal) {
    if (!MuscleGroups.isValid(muscleGroup)) return;
    if (hasTarget(muscleGroup)) return;

    final target = Target(
      id: _uuid.v4(),
      muscleGroup: muscleGroup,
      weeklyGoal: weeklyGoal,
      createdAt: DateTime.now(),
    );

    _targets.add(target);
    notifyListeners();
  }

  void updateTarget(String muscleGroup, int weeklyGoal) {
    final index = _targets.indexWhere((t) => t.muscleGroup == muscleGroup);
    if (index == -1) return;

    _targets[index] = _targets[index].copyWith(weeklyGoal: weeklyGoal);
    notifyListeners();
  }

  void removeTarget(String muscleGroup) {
    _targets.removeWhere((t) => t.muscleGroup == muscleGroup);
    notifyListeners();
  }

  void clearAllTargets() {
    _targets.clear();
    notifyListeners();
  }

  int get totalWeeklyTarget {
    return _targets.fold(0, (sum, target) => sum + target.weeklyGoal);
  }

  List<String> get availableMuscleGroups {
    final targetedMuscles = _targets.map((t) => t.muscleGroup).toSet();
    return MuscleGroups.all
        .where((muscle) => !targetedMuscles.contains(muscle))
        .toList();
  }
}