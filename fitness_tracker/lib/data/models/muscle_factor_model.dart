import '../../core/constants/database_tables.dart';
import '../../domain/entities/muscle_factor.dart';

/// Data model for MuscleFactor with database serialization
class MuscleFactorModel extends MuscleFactor {
  const MuscleFactorModel({
    required super.id,
    required super.exerciseId,
    required super.muscleGroup,
    required super.factor,
  });

  /// Create model from entity
  factory MuscleFactorModel.fromEntity(MuscleFactor muscleFactor) {
    return MuscleFactorModel(
      id: muscleFactor.id,
      exerciseId: muscleFactor.exerciseId,
      muscleGroup: muscleFactor.muscleGroup,
      factor: muscleFactor.factor,
    );
  }

  /// Create model from database map
  factory MuscleFactorModel.fromMap(Map<String, dynamic> map) {
    return MuscleFactorModel(
      id: map[DatabaseTables.factorId] as String,
      exerciseId: map[DatabaseTables.factorExerciseId] as String,
      muscleGroup: map[DatabaseTables.factorMuscleGroup] as String,
      factor: (map[DatabaseTables.factorValue] as num).toDouble(),
    );
  }

  /// Convert model to database map
  Map<String, dynamic> toMap() {
    return {
      DatabaseTables.factorId: id,
      DatabaseTables.factorExerciseId: exerciseId,
      DatabaseTables.factorMuscleGroup: muscleGroup,
      DatabaseTables.factorValue: factor,
    };
  }

  /// Create model from JSON (for API compatibility if needed)
  factory MuscleFactorModel.fromJson(Map<String, dynamic> json) {
    return MuscleFactorModel(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      muscleGroup: json['muscleGroup'] as String,
      factor: (json['factor'] as num).toDouble(),
    );
  }

  /// Convert model to JSON (for API compatibility if needed)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'muscleGroup': muscleGroup,
      'factor': factor,
    };
  }
}