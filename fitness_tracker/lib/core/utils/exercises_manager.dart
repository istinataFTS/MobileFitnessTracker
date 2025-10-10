import 'package:flutter/foundation.dart';
import '../../domain/entities/exercise.dart';
import '../constants/muscle_groups.dart';
import 'package:uuid/uuid.dart';

/// Manages exercises and their muscle group mappings
class ExercisesManager extends ChangeNotifier {
  static final ExercisesManager _instance = ExercisesManager._internal();
  factory ExercisesManager() => _instance;
  
  ExercisesManager._internal() {
    _initializeDefaultExercises();
  }

  final List<Exercise> _exercises = [];
  final _uuid = const Uuid();

  List<Exercise> get exercises => List.unmodifiable(_exercises);

  /// Initialize with common exercises
  void _initializeDefaultExercises() {
    _exercises.addAll([
      // Chest exercises
      Exercise(
        id: _uuid.v4(),
        name: 'Bench Press',
        muscleGroups: ['chest', 'triceps', 'shoulder'],
        createdAt: DateTime.now(),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Incline Bench Press',
        muscleGroups: ['chest', 'shoulder', 'triceps'],
        createdAt: DateTime.now(),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Dumbbell Flyes',
        muscleGroups: ['chest'],
        createdAt: DateTime.now(),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Push-ups',
        muscleGroups: ['chest', 'triceps', 'shoulder'],
        createdAt: DateTime.now(),
      ),
      
      // Back exercises
      Exercise(
        id: _uuid.v4(),
        name: 'Pull-ups',
        muscleGroups: ['lats', 'biceps'],
        createdAt: DateTime.now(),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Barbell Row',
        muscleGroups: ['lats', 'lower back', 'biceps'],
        createdAt: DateTime.now(),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Deadlift',
        muscleGroups: ['lower back', 'glutes', 'hamstring', 'traps'],
        createdAt: DateTime.now(),
      ),
      
      // Shoulder exercises
      Exercise(
        id: _uuid.v4(),
        name: 'Overhead Press',
        muscleGroups: ['shoulder', 'triceps'],
        createdAt: DateTime.now(),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Lateral Raises',
        muscleGroups: ['shoulder'],
        createdAt: DateTime.now(),
      ),
      
      // Arm exercises
      Exercise(
        id: _uuid.v4(),
        name: 'Barbell Curl',
        muscleGroups: ['biceps'],
        createdAt: DateTime.now(),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Tricep Dips',
        muscleGroups: ['triceps'],
        createdAt: DateTime.now(),
      ),
      
      // Leg exercises
      Exercise(
        id: _uuid.v4(),
        name: 'Squat',
        muscleGroups: ['quads', 'glutes', 'hamstring'],
        createdAt: DateTime.now(),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Leg Press',
        muscleGroups: ['quads', 'glutes'],
        createdAt: DateTime.now(),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Leg Curl',
        muscleGroups: ['hamstring'],
        createdAt: DateTime.now(),
      ),
      
      // Core exercises
      Exercise(
        id: _uuid.v4(),
        name: 'Crunches',
        muscleGroups: ['abs'],
        createdAt: DateTime.now(),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Planks',
        muscleGroups: ['abs', 'obliques'],
        createdAt: DateTime.now(),
      ),
    ]);
  }

  Exercise? getExerciseById(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  Exercise? getExerciseByName(String name) {
    try {
      return _exercises.firstWhere(
        (e) => e.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  void addExercise(String name, List<String> muscleGroups) {
    // Validate muscle groups
    final validMuscleGroups = muscleGroups
        .where((mg) => MuscleGroups.isValid(mg))
        .toList();

    if (validMuscleGroups.isEmpty) return;

    // Check if exercise already exists
    if (getExerciseByName(name) != null) return;

    final exercise = Exercise(
      id: _uuid.v4(),
      name: name,
      muscleGroups: validMuscleGroups,
      createdAt: DateTime.now(),
    );

    _exercises.add(exercise);
    notifyListeners();
  }

  void updateExercise(String id, String name, List<String> muscleGroups) {
    final index = _exercises.indexWhere((e) => e.id == id);
    if (index == -1) return;

    // Validate muscle groups
    final validMuscleGroups = muscleGroups
        .where((mg) => MuscleGroups.isValid(mg))
        .toList();

    if (validMuscleGroups.isEmpty) return;

    _exercises[index] = _exercises[index].copyWith(
      name: name,
      muscleGroups: validMuscleGroups,
    );
    
    notifyListeners();
  }

  void deleteExercise(String id) {
    _exercises.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void clearAllExercises() {
    _exercises.clear();
    notifyListeners();
  }

  /// Get exercises that work a specific muscle group
  List<Exercise> getExercisesForMuscle(String muscleGroup) {
    return _exercises
        .where((e) => e.muscleGroups.contains(muscleGroup))
        .toList();
  }
}