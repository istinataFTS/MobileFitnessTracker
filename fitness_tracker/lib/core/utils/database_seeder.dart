import 'package:uuid/uuid.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';

/// Seeds the database with default exercises
class DatabaseSeeder {
  final ExerciseRepository exerciseRepository;
  static const _uuid = Uuid();

  const DatabaseSeeder(this.exerciseRepository);

  /// Seed default exercises if database is empty
  Future<void> seedDefaultExercises() async {
    // Check if exercises already exist
    final result = await exerciseRepository.getAllExercises();
    final hasExercises = result.fold(
      (_) => false,
      (exercises) => exercises.isNotEmpty,
    );

    // If exercises already exist, don't seed
    if (hasExercises) return;

    // Seed default exercises
    final defaultExercises = _getDefaultExercises();
    for (final exercise in defaultExercises) {
      await exerciseRepository.addExercise(exercise);
    }
  }

  /// Get list of default exercises
  /// Covers all major muscle groups with common exercises
  static List<Exercise> _getDefaultExercises() {
    final now = DateTime.now();
    return [
      // ==================== Chest Exercises ====================
      Exercise(
        id: _uuid.v4(),
        name: 'Bench Press',
        muscleGroups: ['chest', 'triceps'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Incline Bench Press',
        muscleGroups: ['chest', 'triceps'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Dumbbell Flyes',
        muscleGroups: ['chest'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Push Ups',
        muscleGroups: ['chest', 'triceps'],
        createdAt: now,
      ),

      // ==================== Back Exercises ====================
      Exercise(
        id: _uuid.v4(),
        name: 'Pull Ups',
        muscleGroups: ['back', 'biceps'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Barbell Row',
        muscleGroups: ['back', 'biceps'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Lat Pulldown',
        muscleGroups: ['back', 'biceps'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Deadlift',
        muscleGroups: ['back', 'hamstring', 'glutes'],
        createdAt: now,
      ),

      // ==================== Shoulder Exercises ====================
      Exercise(
        id: _uuid.v4(),
        name: 'Overhead Press',
        muscleGroups: ['shoulders', 'triceps'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Lateral Raises',
        muscleGroups: ['shoulders'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Front Raises',
        muscleGroups: ['shoulders'],
        createdAt: now,
      ),

      // ==================== Arm Exercises ====================
      Exercise(
        id: _uuid.v4(),
        name: 'Barbell Curl',
        muscleGroups: ['biceps'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Hammer Curls',
        muscleGroups: ['biceps'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Tricep Dips',
        muscleGroups: ['triceps'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Tricep Pushdowns',
        muscleGroups: ['triceps'],
        createdAt: now,
      ),

      // ==================== Leg Exercises ====================
      Exercise(
        id: _uuid.v4(),
        name: 'Squat',
        muscleGroups: ['quads', 'glutes', 'hamstring'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Leg Press',
        muscleGroups: ['quads', 'glutes'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Leg Curl',
        muscleGroups: ['hamstring'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Leg Extension',
        muscleGroups: ['quads'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Calf Raises',
        muscleGroups: ['calves'],
        createdAt: now,
      ),

      // ==================== Core Exercises ====================
      Exercise(
        id: _uuid.v4(),
        name: 'Crunches',
        muscleGroups: ['abs'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Planks',
        muscleGroups: ['abs', 'obliques'],
        createdAt: now,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Russian Twists',
        muscleGroups: ['abs', 'obliques'],
        createdAt: now,
      ),
    ];
  }
}
