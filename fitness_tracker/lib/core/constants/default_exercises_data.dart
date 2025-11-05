import '../../domain/entities/exercise.dart';

class DefaultExercisesData {
  DefaultExercisesData._(); // Private constructor

  /// Get all default exercises for seeding
  /// Returns a new list each time to prevent mutation
  static List<ExerciseData> getDefaultExercises() {
    return [
      // ==================== CHEST EXERCISES ====================
      ExerciseData(
        name: 'Bench Press',
        muscleGroups: ['chest', 'triceps', 'shoulder'],
        category: 'chest',
      ),
      ExerciseData(
        name: 'Incline Bench Press',
        muscleGroups: ['chest', 'shoulder', 'triceps'],
        category: 'chest',
      ),
      ExerciseData(
        name: 'Decline Bench Press',
        muscleGroups: ['chest', 'triceps'],
        category: 'chest',
      ),
      ExerciseData(
        name: 'Dumbbell Flyes',
        muscleGroups: ['chest'],
        category: 'chest',
      ),
      ExerciseData(
        name: 'Push-ups',
        muscleGroups: ['chest', 'triceps', 'shoulder'],
        category: 'chest',
      ),
      ExerciseData(
        name: 'Cable Crossover',
        muscleGroups: ['chest'],
        category: 'chest',
      ),

      // ==================== BACK EXERCISES ====================
      ExerciseData(
        name: 'Pull-ups',
        muscleGroups: ['lats', 'biceps'],
        category: 'back',
      ),
      ExerciseData(
        name: 'Chin-ups',
        muscleGroups: ['lats', 'biceps'],
        category: 'back',
      ),
      ExerciseData(
        name: 'Barbell Row',
        muscleGroups: ['lats', 'lower back', 'biceps'],
        category: 'back',
      ),
      ExerciseData(
        name: 'Dumbbell Row',
        muscleGroups: ['lats', 'lower back', 'biceps'],
        category: 'back',
      ),
      ExerciseData(
        name: 'Deadlift',
        muscleGroups: ['lower back', 'glutes', 'hamstring', 'traps'],
        category: 'back',
      ),
      ExerciseData(
        name: 'Lat Pulldown',
        muscleGroups: ['lats', 'biceps'],
        category: 'back',
      ),
      ExerciseData(
        name: 'T-Bar Row',
        muscleGroups: ['lats', 'lower back'],
        category: 'back',
      ),
      ExerciseData(
        name: 'Seated Cable Row',
        muscleGroups: ['lats', 'lower back'],
        category: 'back',
      ),

      // ==================== SHOULDER EXERCISES ====================
      ExerciseData(
        name: 'Overhead Press',
        muscleGroups: ['shoulder', 'triceps'],
        category: 'shoulders',
      ),
      ExerciseData(
        name: 'Arnold Press',
        muscleGroups: ['shoulder'],
        category: 'shoulders',
      ),
      ExerciseData(
        name: 'Lateral Raises',
        muscleGroups: ['shoulder'],
        category: 'shoulders',
      ),
      ExerciseData(
        name: 'Front Raises',
        muscleGroups: ['shoulder'],
        category: 'shoulders',
      ),
      ExerciseData(
        name: 'Rear Delt Flyes',
        muscleGroups: ['shoulder'],
        category: 'shoulders',
      ),
      ExerciseData(
        name: 'Face Pulls',
        muscleGroups: ['shoulder', 'traps'],
        category: 'shoulders',
      ),

      // ==================== ARM EXERCISES ====================
      
      // Biceps
      ExerciseData(
        name: 'Barbell Curl',
        muscleGroups: ['biceps'],
        category: 'arms',
      ),
      ExerciseData(
        name: 'Dumbbell Curl',
        muscleGroups: ['biceps'],
        category: 'arms',
      ),
      ExerciseData(
        name: 'Hammer Curl',
        muscleGroups: ['biceps', 'forearms'],
        category: 'arms',
      ),
      ExerciseData(
        name: 'Preacher Curl',
        muscleGroups: ['biceps'],
        category: 'arms',
      ),
      ExerciseData(
        name: 'Concentration Curl',
        muscleGroups: ['biceps'],
        category: 'arms',
      ),
      
      // Triceps
      ExerciseData(
        name: 'Tricep Dips',
        muscleGroups: ['triceps', 'chest'],
        category: 'arms',
      ),
      ExerciseData(
        name: 'Tricep Pushdown',
        muscleGroups: ['triceps'],
        category: 'arms',
      ),
      ExerciseData(
        name: 'Overhead Tricep Extension',
        muscleGroups: ['triceps'],
        category: 'arms',
      ),
      ExerciseData(
        name: 'Skull Crushers',
        muscleGroups: ['triceps'],
        category: 'arms',
      ),
      ExerciseData(
        name: 'Close-Grip Bench Press',
        muscleGroups: ['triceps', 'chest'],
        category: 'arms',
      ),
      
      // Forearms
      ExerciseData(
        name: 'Wrist Curl',
        muscleGroups: ['forearms'],
        category: 'arms',
      ),
      ExerciseData(
        name: 'Reverse Wrist Curl',
        muscleGroups: ['forearms'],
        category: 'arms',
      ),

      // ==================== LEG EXERCISES ====================
      
      // Quads/Glutes
      ExerciseData(
        name: 'Squat',
        muscleGroups: ['quads', 'glutes', 'hamstring'],
        category: 'legs',
      ),
      ExerciseData(
        name: 'Front Squat',
        muscleGroups: ['quads', 'glutes'],
        category: 'legs',
      ),
      ExerciseData(
        name: 'Leg Press',
        muscleGroups: ['quads', 'glutes'],
        category: 'legs',
      ),
      ExerciseData(
        name: 'Lunges',
        muscleGroups: ['quads', 'glutes'],
        category: 'legs',
      ),
      ExerciseData(
        name: 'Bulgarian Split Squat',
        muscleGroups: ['quads', 'glutes'],
        category: 'legs',
      ),
      ExerciseData(
        name: 'Leg Extension',
        muscleGroups: ['quads'],
        category: 'legs',
      ),
      
      // Hamstrings
      ExerciseData(
        name: 'Leg Curl',
        muscleGroups: ['hamstring'],
        category: 'legs',
      ),
      ExerciseData(
        name: 'Romanian Deadlift',
        muscleGroups: ['hamstring', 'glutes', 'lower back'],
        category: 'legs',
      ),
      ExerciseData(
        name: 'Nordic Curls',
        muscleGroups: ['hamstring'],
        category: 'legs',
      ),
      
      // Calves
      ExerciseData(
        name: 'Calf Raises',
        muscleGroups: ['calves'],
        category: 'legs',
      ),
      ExerciseData(
        name: 'Seated Calf Raises',
        muscleGroups: ['calves'],
        category: 'legs',
      ),

      // ==================== CORE EXERCISES ====================
      ExerciseData(
        name: 'Crunches',
        muscleGroups: ['abs'],
        category: 'core',
      ),
      ExerciseData(
        name: 'Sit-ups',
        muscleGroups: ['abs'],
        category: 'core',
      ),
      ExerciseData(
        name: 'Planks',
        muscleGroups: ['abs', 'obliques'],
        category: 'core',
      ),
      ExerciseData(
        name: 'Side Planks',
        muscleGroups: ['obliques', 'abs'],
        category: 'core',
      ),
      ExerciseData(
        name: 'Russian Twists',
        muscleGroups: ['obliques', 'abs'],
        category: 'core',
      ),
      ExerciseData(
        name: 'Hanging Leg Raises',
        muscleGroups: ['abs'],
        category: 'core',
      ),
      ExerciseData(
        name: 'Ab Wheel Rollout',
        muscleGroups: ['abs'],
        category: 'core',
      ),
      ExerciseData(
        name: 'Cable Crunches',
        muscleGroups: ['abs'],
        category: 'core',
      ),
      
      // ==================== TRAPS EXERCISES ====================
      ExerciseData(
        name: 'Shrugs',
        muscleGroups: ['traps'],
        category: 'back',
      ),
      ExerciseData(
        name: 'Upright Row',
        muscleGroups: ['traps', 'shoulder'],
        category: 'back',
      ),
    ];
  }

  /// Get exercises count for logging/validation
  static int get exercisesCount => getDefaultExercises().length;

  /// Get exercises grouped by category
  static Map<String, List<ExerciseData>> getExercisesByCategory() {
    final exercises = getDefaultExercises();
    final Map<String, List<ExerciseData>> grouped = {};
    
    for (final exercise in exercises) {
      if (!grouped.containsKey(exercise.category)) {
        grouped[exercise.category] = [];
      }
      grouped[exercise.category]!.add(exercise);
    }
    
    return grouped;
  }
}

/// Data class for exercise seed data
/// Lighter than Exercise entity, used only for seeding
class ExerciseData {
  final String name;
  final List<String> muscleGroups;
  final String category; // For organizational purposes

  const ExerciseData({
    required this.name,
    required this.muscleGroups,
    required this.category,
  });

  /// Convert to Exercise entity for database insertion
  Exercise toEntity(String id, DateTime createdAt) {
    return Exercise(
      id: id,
      name: name,
      muscleGroups: muscleGroups,
      createdAt: createdAt,
    );
  }
}
