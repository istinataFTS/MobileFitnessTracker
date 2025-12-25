import '../../domain/entities/muscle_factor.dart';
import 'muscle_stimulus_constants.dart';

class ExerciseMuscleFactor sData {
  ExerciseMuscleFactorsData._(); // Private constructor

  /// Get all exercise muscle factor mappings
  static Map<String, List<MuscleFactorData>> getAllFactors() {
    return {
      // ==================== CHEST EXERCISES ====================
      
      'Bench Press': [
        MuscleFactorData(MuscleStimulus.midChest, 1.0),
        MuscleFactorData(MuscleStimulus.upperChest, 0.4),
        MuscleFactorData(MuscleStimulus.lowerChest, 0.4),
        MuscleFactorData(MuscleStimulus.frontDelts, 0.4),
        MuscleFactorData(MuscleStimulus.triceps, 0.3),
      ],
      
      'Incline Bench Press': [
        MuscleFactorData(MuscleStimulus.upperChest, 1.0),
        MuscleFactorData(MuscleStimulus.midChest, 0.5),
        MuscleFactorData(MuscleStimulus.frontDelts, 0.5),
        MuscleFactorData(MuscleStimulus.triceps, 0.3),
      ],
      
      'Dumbbell Flyes': [
        MuscleFactorData(MuscleStimulus.midChest, 1.0),
        MuscleFactorData(MuscleStimulus.upperChest, 0.3),
        MuscleFactorData(MuscleStimulus.lowerChest, 0.3),
        MuscleFactorData(MuscleStimulus.frontDelts, 0.2),
      ],
      
      'Decline Bench Press': [
        MuscleFactorData(MuscleStimulus.lowerChest, 1.0),
        MuscleFactorData(MuscleStimulus.midChest, 0.5),
        MuscleFactorData(MuscleStimulus.frontDelts, 0.3),
        MuscleFactorData(MuscleStimulus.triceps, 0.3),
      ],
      
      'Push Ups': [
        MuscleFactorData(MuscleStimulus.midChest, 1.0),
        MuscleFactorData(MuscleStimulus.upperChest, 0.3),
        MuscleFactorData(MuscleStimulus.lowerChest, 0.3),
        MuscleFactorData(MuscleStimulus.frontDelts, 0.3),
        MuscleFactorData(MuscleStimulus.triceps, 0.3),
        MuscleFactorData(MuscleStimulus.abs, 0.2), // Stabilizer
      ],
      
      'Cable Chest Flyes': [
        MuscleFactorData(MuscleStimulus.midChest, 1.0),
        MuscleFactorData(MuscleStimulus.upperChest, 0.4),
        MuscleFactorData(MuscleStimulus.lowerChest, 0.4),
        MuscleFactorData(MuscleStimulus.frontDelts, 0.2),
      ],
      
      'Chest Dips': [
        MuscleFactorData(MuscleStimulus.lowerChest, 1.0),
        MuscleFactorData(MuscleStimulus.midChest, 0.6),
        MuscleFactorData(MuscleStimulus.frontDelts, 0.4),
        MuscleFactorData(MuscleStimulus.triceps, 0.5),
      ],
      
      // ==================== BACK EXERCISES ====================
      
      'Pull Ups': [
        MuscleFactorData(MuscleStimulus.lats, 1.0),
        MuscleFactorData(MuscleStimulus.middleTraps, 0.4),
        MuscleFactorData(MuscleStimulus.biceps, 0.5),
        MuscleFactorData(MuscleStimulus.rearDelts, 0.3),
        MuscleFactorData(MuscleStimulus.forearms, 0.2),
      ],
      
      'Barbell Row': [
        MuscleFactorData(MuscleStimulus.lats, 1.0),
        MuscleFactorData(MuscleStimulus.middleTraps, 0.6),
        MuscleFactorData(MuscleStimulus.lowerTraps, 0.4),
        MuscleFactorData(MuscleStimulus.rearDelts, 0.4),
        MuscleFactorData(MuscleStimulus.biceps, 0.5),
        MuscleFactorData(MuscleStimulus.lowerBack, 0.3), // Stabilizer
      ],
      
      'Lat Pulldown': [
        MuscleFactorData(MuscleStimulus.lats, 1.0),
        MuscleFactorData(MuscleStimulus.middleTraps, 0.3),
        MuscleFactorData(MuscleStimulus.biceps, 0.4),
        MuscleFactorData(MuscleStimulus.rearDelts, 0.2),
        MuscleFactorData(MuscleStimulus.forearms, 0.2),
      ],
      
      'Deadlift': [
        MuscleFactorData(MuscleStimulus.lowerBack, 1.0),
        MuscleFactorData(MuscleStimulus.glutes, 0.8),
        MuscleFactorData(MuscleStimulus.hamstrings, 0.7),
        MuscleFactorData(MuscleStimulus.middleTraps, 0.5),
        MuscleFactorData(MuscleStimulus.lats, 0.4),
        MuscleFactorData(MuscleStimulus.forearms, 0.5),
        MuscleFactorData(MuscleStimulus.abs, 0.3), // Core stabilization
      ],
      
      'T-Bar Row': [
        MuscleFactorData(MuscleStimulus.lats, 1.0),
        MuscleFactorData(MuscleStimulus.middleTraps, 0.6),
        MuscleFactorData(MuscleStimulus.rearDelts, 0.4),
        MuscleFactorData(MuscleStimulus.biceps, 0.4),
        MuscleFactorData(MuscleStimulus.lowerBack, 0.3),
      ],
      
      'Seated Cable Row': [
        MuscleFactorData(MuscleStimulus.lats, 1.0),
        MuscleFactorData(MuscleStimulus.middleTraps, 0.5),
        MuscleFactorData(MuscleStimulus.rearDelts, 0.4),
        MuscleFactorData(MuscleStimulus.biceps, 0.4),
        MuscleFactorData(MuscleStimulus.lowerTraps, 0.3),
      ],
      
      'Face Pulls': [
        MuscleFactorData(MuscleStimulus.rearDelts, 1.0),
        MuscleFactorData(MuscleStimulus.middleTraps, 0.6),
        MuscleFactorData(MuscleStimulus.upperTraps, 0.4),
        MuscleFactorData(MuscleStimulus.biceps, 0.2),
      ],
      
      // ==================== SHOULDER EXERCISES ====================
      
      'Overhead Press': [
        MuscleFactorData(MuscleStimulus.frontDelts, 1.0),
        MuscleFactorData(MuscleStimulus.sideDelts, 0.5),
        MuscleFactorData(MuscleStimulus.upperChest, 0.3),
        MuscleFactorData(MuscleStimulus.triceps, 0.5),
        MuscleFactorData(MuscleStimulus.upperTraps, 0.3),
        MuscleFactorData(MuscleStimulus.abs, 0.2), // Stabilizer
      ],
      
      'Lateral Raises': [
        MuscleFactorData(MuscleStimulus.sideDelts, 1.0),
        MuscleFactorData(MuscleStimulus.frontDelts, 0.2),
        MuscleFactorData(MuscleStimulus.upperTraps, 0.2),
      ],
      
      'Front Raises': [
        MuscleFactorData(MuscleStimulus.frontDelts, 1.0),
        MuscleFactorData(MuscleStimulus.upperChest, 0.2),
      ],
      
      'Arnold Press': [
        MuscleFactorData(MuscleStimulus.frontDelts, 1.0),
        MuscleFactorData(MuscleStimulus.sideDelts, 0.6),
        MuscleFactorData(MuscleStimulus.triceps, 0.4),
        MuscleFactorData(MuscleStimulus.upperTraps, 0.3),
      ],
      
      'Dumbbell Shoulder Press': [
        MuscleFactorData(MuscleStimulus.frontDelts, 1.0),
        MuscleFactorData(MuscleStimulus.sideDelts, 0.5),
        MuscleFactorData(MuscleStimulus.triceps, 0.5),
        MuscleFactorData(MuscleStimulus.upperTraps, 0.3),
      ],
      
      'Cable Lateral Raises': [
        MuscleFactorData(MuscleStimulus.sideDelts, 1.0),
        MuscleFactorData(MuscleStimulus.frontDelts, 0.2),
      ],
      
      'Rear Delt Flyes': [
        MuscleFactorData(MuscleStimulus.rearDelts, 1.0),
        MuscleFactorData(MuscleStimulus.middleTraps, 0.3),
      ],
      
      // ==================== ARM EXERCISES ====================
      
      'Barbell Curl': [
        MuscleFactorData(MuscleStimulus.biceps, 1.0),
        MuscleFactorData(MuscleStimulus.forearms, 0.3),
      ],
      
      'Hammer Curls': [
        MuscleFactorData(MuscleStimulus.biceps, 1.0),
        MuscleFactorData(MuscleStimulus.forearms, 0.5),
      ],
      
      'Preacher Curls': [
        MuscleFactorData(MuscleStimulus.biceps, 1.0),
        MuscleFactorData(MuscleStimulus.forearms, 0.2),
      ],
      
      'Tricep Dips': [
        MuscleFactorData(MuscleStimulus.triceps, 1.0),
        MuscleFactorData(MuscleStimulus.lowerChest, 0.4),
        MuscleFactorData(MuscleStimulus.frontDelts, 0.3),
      ],
      
      'Tricep Pushdowns': [
        MuscleFactorData(MuscleStimulus.triceps, 1.0),
      ],
      
      'Skull Crushers': [
        MuscleFactorData(MuscleStimulus.triceps, 1.0),
        MuscleFactorData(MuscleStimulus.forearms, 0.2),
      ],
      
      'Close-Grip Bench Press': [
        MuscleFactorData(MuscleStimulus.triceps, 1.0),
        MuscleFactorData(MuscleStimulus.midChest, 0.6),
        MuscleFactorData(MuscleStimulus.frontDelts, 0.4),
      ],
      
      'Concentration Curls': [
        MuscleFactorData(MuscleStimulus.biceps, 1.0),
        MuscleFactorData(MuscleStimulus.forearms, 0.2),
      ],
      
      'Cable Curls': [
        MuscleFactorData(MuscleStimulus.biceps, 1.0),
        MuscleFactorData(MuscleStimulus.forearms, 0.3),
      ],
      
      'Overhead Tricep Extension': [
        MuscleFactorData(MuscleStimulus.triceps, 1.0),
        MuscleFactorData(MuscleStimulus.forearms, 0.2),
      ],
      
      'Wrist Curls': [
        MuscleFactorData(MuscleStimulus.forearms, 1.0),
      ],
      
      // ==================== LEG EXERCISES ====================
      
      'Squat': [
        MuscleFactorData(MuscleStimulus.quads, 1.0),
        MuscleFactorData(MuscleStimulus.glutes, 0.7),
        MuscleFactorData(MuscleStimulus.hamstrings, 0.4),
        MuscleFactorData(MuscleStimulus.lowerBack, 0.3), // Stabilizer
        MuscleFactorData(MuscleStimulus.abs, 0.3), // Core stabilization
      ],
      
      'Leg Press': [
        MuscleFactorData(MuscleStimulus.quads, 1.0),
        MuscleFactorData(MuscleStimulus.glutes, 0.6),
        MuscleFactorData(MuscleStimulus.hamstrings, 0.3),
      ],
      
      'Leg Curl': [
        MuscleFactorData(MuscleStimulus.hamstrings, 1.0),
      ],
      
      'Leg Extension': [
        MuscleFactorData(MuscleStimulus.quads, 1.0),
      ],
      
      'Calf Raises': [
        MuscleFactorData(MuscleStimulus.calves, 1.0),
      ],
      
      'Romanian Deadlift': [
        MuscleFactorData(MuscleStimulus.hamstrings, 1.0),
        MuscleFactorData(MuscleStimulus.glutes, 0.7),
        MuscleFactorData(MuscleStimulus.lowerBack, 0.6),
        MuscleFactorData(MuscleStimulus.forearms, 0.3),
      ],
      
      'Bulgarian Split Squat': [
        MuscleFactorData(MuscleStimulus.quads, 1.0),
        MuscleFactorData(MuscleStimulus.glutes, 0.7),
        MuscleFactorData(MuscleStimulus.hamstrings, 0.4),
      ],
      
      'Hack Squat': [
        MuscleFactorData(MuscleStimulus.quads, 1.0),
        MuscleFactorData(MuscleStimulus.glutes, 0.5),
        MuscleFactorData(MuscleStimulus.hamstrings, 0.3),
      ],
      
      'Lunges': [
        MuscleFactorData(MuscleStimulus.quads, 1.0),
        MuscleFactorData(MuscleStimulus.glutes, 0.7),
        MuscleFactorData(MuscleStimulus.hamstrings, 0.4),
      ],
      
      'Hip Thrusts': [
        MuscleFactorData(MuscleStimulus.glutes, 1.0),
        MuscleFactorData(MuscleStimulus.hamstrings, 0.4),
      ],
      
      'Seated Calf Raises': [
        MuscleFactorData(MuscleStimulus.calves, 1.0),
      ],
      
      // ==================== CORE EXERCISES ====================
      
      'Crunches': [
        MuscleFactorData(MuscleStimulus.abs, 1.0),
      ],
      
      'Planks': [
        MuscleFactorData(MuscleStimulus.abs, 1.0),
        MuscleFactorData(MuscleStimulus.obliques, 0.5),
        MuscleFactorData(MuscleStimulus.lowerBack, 0.3),
      ],
      
      'Side Planks': [
        MuscleFactorData(MuscleStimulus.obliques, 1.0),
        MuscleFactorData(MuscleStimulus.abs, 0.5),
      ],
      
      'Russian Twists': [
        MuscleFactorData(MuscleStimulus.obliques, 1.0),
        MuscleFactorData(MuscleStimulus.abs, 0.5),
      ],
      
      'Hanging Leg Raises': [
        MuscleFactorData(MuscleStimulus.abs, 1.0),
        MuscleFactorData(MuscleStimulus.obliques, 0.3),
        MuscleFactorData(MuscleStimulus.forearms, 0.2), // Grip
      ],
      
      'Ab Wheel Rollout': [
        MuscleFactorData(MuscleStimulus.abs, 1.0),
        MuscleFactorData(MuscleStimulus.obliques, 0.4),
        MuscleFactorData(MuscleStimulus.lowerBack, 0.3),
      ],
      
      'Cable Crunches': [
        MuscleFactorData(MuscleStimulus.abs, 1.0),
        MuscleFactorData(MuscleStimulus.obliques, 0.2),
      ],
      
      // ==================== TRAP EXERCISES ====================
      
      'Shrugs': [
        MuscleFactorData(MuscleStimulus.upperTraps, 1.0),
        MuscleFactorData(MuscleStimulus.middleTraps, 0.4),
        MuscleFactorData(MuscleStimulus.forearms, 0.3), // Grip
      ],
      
      'Upright Row': [
        MuscleFactorData(MuscleStimulus.upperTraps, 1.0),
        MuscleFactorData(MuscleStimulus.sideDelts, 0.7),
        MuscleFactorData(MuscleStimulus.frontDelts, 0.4),
        MuscleFactorData(MuscleStimulus.biceps, 0.3),
      ],
    };
  }

  /// Get total number of exercises with factors
  static int get totalExercises => getAllFactors().length;

  /// Get total number of muscle factor assignments
  static int get totalFactorAssignments {
    int count = 0;
    getAllFactors().forEach((_, factors) {
      count += factors.length;
    });
    return count;
  }

  /// Validate that an exercise has factors defined
  static bool hasFactors(String exerciseName) {
    return getAllFactors().containsKey(exerciseName);
  }

  /// Get factors for a specific exercise
  static List<MuscleFactorData>? getFactorsForExercise(String exerciseName) {
    return getAllFactors()[exerciseName];
  }

  /// Get all exercises that target a specific muscle group
  static List<String> getExercisesForMuscle(String muscleGroup) {
    final exercises = <String>[];
    getAllFactors().forEach((exerciseName, factors) {
      for (final factor in factors) {
        if (factor.muscleGroup == muscleGroup) {
          exercises.add(exerciseName);
          break; // Only add exercise once
        }
      }
    });
    return exercises;
  }

  /// Validate factor assignments (all factors should be 0.1 - 1.0)
  static bool validateFactors() {
    final factors = getAllFactors();
    for (final entry in factors.entries) {
      for (final factor in entry.value) {
        if (factor.factor < 0.1 || factor.factor > 1.0) {
          return false;
        }
      }
    }
    return true;
  }
}

/// Data class for muscle factor seed data
/// Lightweight structure used only for seeding
class MuscleFactorData {
  final String muscleGroup;
  final double factor;

  const MuscleFactorData(this.muscleGroup, this.factor);

  /// Convert to MuscleFactor entity with generated ID
  MuscleFactor toEntity({
    required String id,
    required String exerciseId,
  }) {
    return MuscleFactor(
      id: id,
      exerciseId: exerciseId,
      muscleGroup: muscleGroup,
      factor: factor,
    );
  }

  @override
  String toString() => '$muscleGroup: $factor';
}