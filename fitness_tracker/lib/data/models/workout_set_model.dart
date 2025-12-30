import '../../core/constants/database_tables.dart';
import '../../core/constants/muscle_stimulus_constants.dart';
import '../../domain/entities/workout_set.dart';

/// Data model for WorkoutSet with database serialization
class WorkoutSetModel extends WorkoutSet {
  const WorkoutSetModel({
    required super.id,
    required super.exerciseId,
    required super.reps,
    required super.weight,
    super.intensity = MuscleStimulus.defaultIntensity,
    required super.date,
    required super.createdAt,
  });

  /// Create model from entity
  factory WorkoutSetModel.fromEntity(WorkoutSet set) {
    return WorkoutSetModel(
      id: set.id,
      exerciseId: set.exerciseId,
      reps: set.reps,
      weight: set.weight,
      intensity: set.intensity,
      date: set.date,
      createdAt: set.createdAt,
    );
  }

  /// Create model from database map
  factory WorkoutSetModel.fromMap(Map<String, dynamic> map) {
    return WorkoutSetModel(
      id: map[DatabaseTables.setId] as String,
      exerciseId: map[DatabaseTables.setExerciseId] as String,
      reps: map[DatabaseTables.setReps] as int,
      weight: (map[DatabaseTables.setWeight] as num).toDouble(),
      intensity: (map[DatabaseTables.setIntensity] as int?) ?? 
          MuscleStimulus.defaultIntensity, // Handle old records without intensity
      date: DateTime.parse(map[DatabaseTables.setDate] as String),
      createdAt: DateTime.parse(map[DatabaseTables.setCreatedAt] as String),
    );
  }

  /// Convert model to database map
  Map<String, dynamic> toMap() {
    return {
      DatabaseTables.setId: id,
      DatabaseTables.setExerciseId: exerciseId,
      DatabaseTables.setReps: reps,
      DatabaseTables.setWeight: weight,
      DatabaseTables.setIntensity: intensity,
      DatabaseTables.setDate: date.toIso8601String(),
      DatabaseTables.setCreatedAt: createdAt.toIso8601String(),
    };
  }

  /// Create model from JSON (for API compatibility)
  factory WorkoutSetModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSetModel(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
      intensity: (json['intensity'] as int?) ?? MuscleStimulus.defaultIntensity,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert model to JSON (for API compatibility)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'reps': reps,
      'weight': weight,
      'intensity': intensity,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}